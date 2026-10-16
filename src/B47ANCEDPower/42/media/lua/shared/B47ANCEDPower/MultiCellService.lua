local B47ANCEDPower=require "B47ANCEDPower/API"
local CellSet=require "B47ANCEDPower/CellSet"

local singleInstall=B47ANCEDPower.installBattery
local singleExtract=B47ANCEDPower.extractBattery
local singleReplace=B47ANCEDPower.replaceBattery
local singleMigrate=B47ANCEDPower.migrateInstalledLegacyBattery

local sequence=0
local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end
local function modData(item) local ok,value=call(item,"getModData"); return ok and value or nil end
local function copy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {}; if seen[value] then return seen[value] end
    local result={}; seen[value]=result
    for key,entry in pairs(value) do result[copy(key,seen)]=copy(entry,seen) end
    return result
end
local function restore(target,snapshot)
    for key in pairs(target) do target[key]=nil end
    for key,value in pairs(snapshot or {}) do target[key]=copy(value) end
end
local function authoritative()
    return not (type(isClient)=="function" and isClient()==true
        and not (type(isServer)=="function" and isServer()==true))
end
local function readFraction(consumer,profile,state)
    return B47ANCEDPower.readConsumerCharge(consumer)
end
local function writeFraction(consumer,state,value,mode)
    return B47ANCEDPower.writeConsumerCharge(consumer,value,mode)
end
local function addExact(container,item)
    call(container,"AddItem",item)
    local ok,present=call(container,"contains",item)
    return ok and present==true
end
local function removeExact(container,item)
    local ok,present=call(container,"contains",item)
    if not ok or present~=true then return false end
    call(container,"Remove",item)
    ok,present=call(container,"contains",item)
    return ok and present==false
end
local function metadata(item)
    local data=modData(item) or {}; local result={}
    for _,key in ipairs({"B47ANCEDPowerSource","B47ANCEDPowerSources","B47ANCEDPowerImprovised","B47ANCEDPowerResistance"}) do
        local value=data[key]
        if type(value)=="string" or type(value)=="boolean" or type(value)=="number" then result[key]=value end
    end
    return result
end
local function nextRecord(mode,consumer)
    sequence=sequence+1
    local _,id=call(consumer,"getID")
    return {schemaVersion=2,status="executing",mode=mode,operationId="PWSET-"..tostring(id or 0).."-"..sequence}
end
local function syncResources(player,consumer,batteries)
    if not player then return end
    local parent=B47ANCEDPower.ItemAccess.findWeaponForPart(player,consumer)
    B47ANCEDPower.ItemAccess.syncConsumer(player,consumer,parent)
    for _,item in ipairs(batteries or {}) do
        if B47ANCEDPower.ItemAccess.ownsInventoryItem(player,item) and type(syncItemModData)=="function" then
            pcall(syncItemModData,player,item)
        end
    end
end
local function clearClaims(record,consumer,batteries,player)
    local data=modData(consumer)
    if type(data)=="table" and data.B47ANCEDPowerServiceRecovery==record then data.B47ANCEDPowerServiceRecovery=nil end
    for _,battery in ipairs(batteries or {}) do
        local itemData=modData(battery)
        if type(itemData)=="table" and itemData.B47ANCEDPowerServiceRecovery==record then
            itemData.B47ANCEDPowerServiceRecovery=nil
        end
    end
    syncResources(player,consumer,batteries)
end
local function quarantine(record,reason,player,consumer,batteries)
    record.status="inspection_required"; record.reason=tostring(reason or "multi-cell transaction uncertain")
    if consumer then syncResources(player,consumer,batteries) end
end

function B47ANCEDPower.getInstalledCellSet(consumer)
    local data=modData(consumer); local state=type(data)=="table" and data.B47ANCEDPower or nil
    if type(state)~="table" or state.cellSet==nil then return nil end
    local valid=CellSet.validate(state.cellSet)
    return valid and copy(state.cellSet) or nil,"invalid installed cell set"
end

local function standardCellFor(profile)
    local matches={}
    for item,cell in pairs(B47ANCEDPower.Batteries or {}) do
        if item~="Base.Battery" and cell.pack~=true and cell.improvised~=true then
            for _,size in ipairs(profile.sizes or {}) do
                if cell.size==size then matches[#matches+1]=item; break end
            end
        end
    end
    table.sort(matches)
    return matches[1]
end

function B47ANCEDPower.migrateInstalledLegacyBattery(consumer)
    if not authoritative() then return false,"non-authority" end
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    local count=profile and math.floor(tonumber(profile.nominalCellCount) or 1) or 1
    if count<=1 then return singleMigrate(consumer) end
    local data=modData(consumer)
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil or data.B47ANCEDPowerEnergyRecovery~=nil then return false,"consumer requires inspection" end
    if data.B47ANCEDPower~=nil and type(data.B47ANCEDPower)~="table" then return false,"malformed consumer state" end
    local state=type(data.B47ANCEDPower)=="table" and data.B47ANCEDPower or {}
    local okFraction,fraction,mode=readFraction(consumer,profile,state)
    if not okFraction or fraction<=0.0001 then return false,"empty" end
    if state.cellSet then return false,"not-needed" end
    local priorBatteryType=state.batteryType
    local batteryType=priorBatteryType and B47ANCEDPower.accepts(consumer,priorBatteryType) and priorBatteryType
        or standardCellFor(profile)
    local cell=B47ANCEDPower.getBatteryProfile(batteryType)
    if not cell then return false,"no-sized-replacement" end
    local okUse,baseUse=call(consumer,"getUseDelta")
    if profile.storageMode=="modData" then baseUse=profile.baseUseDelta;okUse=type(baseUse)=="number" end
    if not okUse or tonumber(baseUse)==nil then return false,"unsupported-consumer" end
    -- A pre-0.7 canonical state already names one abstract installed cell. A
    -- vanilla-only state has no batteryType and uses the consumer reference
    -- capacity. Both migrations preserve absolute energy, not percentage.
    local priorProfile=priorBatteryType and B47ANCEDPower.getBatteryProfile(priorBatteryType) or nil
    local priorCapacity=priorBatteryType and (tonumber(state.capacity) or (priorProfile and priorProfile.capacity) or cell.capacity)
        or (tonumber(profile.referenceCapacity) or cell.capacity)
    local totalEnergy=fraction*math.max(0.01,priorCapacity)
    local perCell=math.min(cell.capacity,totalEnergy/count); local descriptors={}
    for index=1,count do
        local cellMetadata=index==1 and copy(state.batteryMetadata or {}) or {}
        if index==1 and priorBatteryType and priorBatteryType~=batteryType and cellMetadata.B47ANCEDPowerSource==nil then
            cellMetadata.B47ANCEDPowerSource=priorBatteryType
        end
        descriptors[index]={batteryType=batteryType,capacity=cell.capacity,charge=perCell,metadata=cellMetadata}
    end
    local set=assert(CellSet.create(descriptors)); local summary=assert(CellSet.summary(set))
    local snapshot=copy(state); local record=nextRecord("embedded-set-migration",consumer)
    record.state=snapshot; record.chargeFraction=fraction; data.B47ANCEDPowerServiceRecovery=record; data.B47ANCEDPower=state
    state.cellSet=set; state.batteryType=batteryType; state.capacity=summary.totalCapacity
    state.baseUseDelta=tonumber(baseUse); state.resistance=1; state.storageMode=mode; state.migratedLegacyBattery=true
    record.mutated=true
    local written=writeFraction(consumer,state,summary.chargeFraction,mode)
    local refreshed=written and B47ANCEDPower.refreshConsumer(consumer)
    if not written or refreshed~=true then
        restore(state,snapshot); writeFraction(consumer,state,fraction,mode); call(consumer,"setUseDelta",baseUse)
        quarantine(record,"embedded multi-cell migration rollback requires inspection")
        return false,"embedded migration could not configure consumer"
    end
    clearClaims(record,consumer)
    return true,batteryType
end

function B47ANCEDPower.installBatterySet(player,consumer,batteries)
    if not authoritative() then return false,"non-authority" end
    local valid,reason=B47ANCEDPower.validateBatterySet(consumer,batteries)
    if not valid then return false,reason end
    local deadOK,dead=call(player,"isDead")
    if not deadOK or dead~=false or not B47ANCEDPower.ownsServiceItem(player,consumer) then return false,"actor or consumer unavailable" end
    local data=modData(consumer); local profile=B47ANCEDPower.getConsumerProfile(consumer)
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil or data.B47ANCEDPowerEnergyRecovery~=nil then return false,"consumer requires inspection" end
    if B47ANCEDPower.getInstalledBatteryType(consumer) then return false,"occupied" end
    for _,battery in ipairs(batteries) do
        if not B47ANCEDPower.ownsServiceItem(player,battery) then return false,"battery not owned" end
        local itemData=modData(battery)
        if type(itemData)~="table" or itemData.B47ANCEDPowerServiceRecovery~=nil or itemData.B47ANCEDPowerEnergyRecovery~=nil then return false,"battery requires inspection" end
    end
    local state=type(data.B47ANCEDPower)=="table" and data.B47ANCEDPower or nil
    if data.B47ANCEDPower~=nil and not state then return false,"malformed consumer state" end
    state=state or {}; if not data.B47ANCEDPower then data.B47ANCEDPower=state end
    local okFraction,priorFraction,mode=readFraction(consumer,profile,state)
    if not okFraction or priorFraction>0.0001 then return false,"native battery already installed" end
    local okUse,baseUse=call(consumer,"getUseDelta")
    if not okUse or tonumber(baseUse)==nil then baseUse=tonumber(profile and profile.baseUseDelta); okUse=baseUse~=nil end
    if not okUse then return false,"unsupported consumer drain API" end
    local descriptors={}
    for index,battery in ipairs(batteries) do
        local cell=B47ANCEDPower.getBatteryProfile(battery)
        descriptors[index]={batteryType=cell.item,capacity=cell.capacity,
            charge=B47ANCEDPower.getCharge(battery),metadata=metadata(battery)}
    end
    local set=assert(CellSet.create(descriptors)); local summary=assert(CellSet.summary(set))
    local record=nextRecord("install-set",consumer); record.state=copy(state); record.chargeFraction=priorFraction
    data.B47ANCEDPowerServiceRecovery=record
    for _,battery in ipairs(batteries) do modData(battery).B47ANCEDPowerServiceRecovery=record end
    local removed={}
    local function restoreInputs()
        local restored=true
        for _,entry in ipairs(removed) do
            local known,present=call(entry.container,"contains",entry.item)
            if not known or (not present and not addExact(entry.container,entry.item)) then restored=false end
        end
        return restored
    end
    for _,battery in ipairs(batteries) do
        local _,container=call(battery,"getContainer")
        if container then removed[#removed+1]={item=battery,container=container};record.mutated=true end
        if not container or not removeExact(container,battery) then
            local restored=restoreInputs()
            if restored then clearClaims(record,consumer,batteries,player) else quarantine(record,"input rollback unverified",player,consumer,batteries) end
            return false,"could not consume complete battery set"
        end
    end
    local snapshot=copy(state)
    state.cellSet=set; state.batteryType=set.cells[1].batteryType; state.capacity=summary.totalCapacity
    state.baseUseDelta=tonumber(baseUse); state.storageMode=mode
    local weighted=0
    for _,cell in ipairs(set.cells) do weighted=weighted+(tonumber(cell.metadata.B47ANCEDPowerResistance) or 1)*cell.capacity end
    state.resistance=weighted/summary.totalCapacity
    local configured=writeFraction(consumer,state,summary.chargeFraction,mode)
    local refreshed=configured and B47ANCEDPower.refreshConsumer(consumer)
    if not configured or refreshed~=true then
        restore(state,snapshot)
        local chargeRestored=writeFraction(consumer,state,priorFraction,mode)
        local drainRestored=true
        if mode~="modData" then
            call(consumer,"setUseDelta",baseUse)
            local checked,value=call(consumer,"getUseDelta")
            drainRestored=checked and type(value)=="number" and math.abs(value-baseUse)<=0.000001
        end
        local restored=restoreInputs() and chargeRestored and drainRestored
        if restored then clearClaims(record,consumer,batteries,player) else quarantine(record,"configuration rollback unverified",player,consumer,batteries) end
        return false,"could not configure multi-cell consumer"
    end
    clearClaims(record,consumer,batteries,player)
    for _,entry in ipairs(removed) do
        if type(sendRemoveItemFromContainer)=="function" then pcall(sendRemoveItemFromContainer,entry.container,entry.item) end
    end
    return true
end

function B47ANCEDPower.extractBatterySet(player,consumer)
    if not authoritative() then return false,"non-authority" end
    local deadOK,dead=call(player,"isDead");if not deadOK or dead~=false then return false,"actor unavailable" end
    if not B47ANCEDPower.ownsServiceItem(player,consumer) then return false,"consumer not owned" end
    local data=modData(consumer); local state=type(data)=="table" and data.B47ANCEDPower or nil
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil or data.B47ANCEDPowerEnergyRecovery~=nil then return false,"consumer requires inspection" end
    if type(state)~="table" or not state.cellSet then return false,"no installed cell set" end
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    local okFraction,fraction,mode=readFraction(consumer,profile,state)
    local okUse,priorUse=call(consumer,"getUseDelta")
    if state.storageMode=="modData" then okUse=true; priorUse=state.baseUseDelta end
    local okActive,wasActive=call(consumer,"isActivated")
    if not okActive then okActive,wasActive=call(consumer,"getActivated") end
    local set=copy(state.cellSet)
    if not okFraction or not okUse or not CellSet.reconcileFraction(set,fraction) then return false,"installed cell energy unavailable" end
    local record=nextRecord("extract-set",consumer); record.state=copy(state); record.chargeFraction=fraction
    data.B47ANCEDPowerServiceRecovery=record
    local _,inventory=call(player,"getInventory"); if not inventory then clearClaims(record,consumer,nil,player); return false,"inventory unavailable" end
    local outputs={}
    for _,cell in ipairs(set.cells) do
        local made,item=pcall(function() return instanceItem(cell.batteryType) end)
        if not made or not item then
            local rolled=true; for _,output in ipairs(outputs) do if not removeExact(inventory,output) then rolled=false end end
            if rolled then clearClaims(record,consumer,outputs,player) else quarantine(record,"output allocation rollback unverified",player,consumer,outputs) end
            return false,"could not create returned cell set"
        end
        local itemData=modData(item)
        if type(itemData)~="table" then
            local rolled=true; for _,output in ipairs(outputs) do if not removeExact(inventory,output) then rolled=false end end
            if rolled then clearClaims(record,consumer,outputs,player) else quarantine(record,"output-state rollback unverified",player,consumer,outputs) end
            return false,"could not create returned cell set"
        end
        for key,value in pairs(cell.metadata or {}) do itemData[key]=value end
        itemData.B47ANCEDPowerServiceRecovery=record
        outputs[#outputs+1]=item
        if not B47ANCEDPower.setCharge(item,cell.charge) or not addExact(inventory,item) then
            local rolled=true; for _,output in ipairs(outputs) do
                local known,present=call(inventory,"contains",output)
                if not known or (present and not removeExact(inventory,output)) then rolled=false end
            end
            if rolled then clearClaims(record,consumer,outputs,player) else quarantine(record,"output rollback unverified",player,consumer,outputs) end
            return false,"could not return complete cell set"
        end
        record.mutated=true
    end
    local cleared=writeFraction(consumer,state,0,mode); local drainRestored=true; local deactivated=true
    if state.storageMode~="modData" then
        call(consumer,"setActivated",false)
        local checked,active=call(consumer,"isActivated"); if not checked then checked,active=call(consumer,"getActivated") end
        deactivated=checked and active==false
        call(consumer,"setUseDelta",state.baseUseDelta)
        local useChecked,actualUse=call(consumer,"getUseDelta")
        drainRestored=useChecked and type(actualUse)=="number"
            and math.abs(actualUse-state.baseUseDelta)<=math.max(0.000000001,math.abs(state.baseUseDelta)*0.00001)
    end
    if not cleared or not drainRestored or not deactivated then
        local rolled=true; for _,output in ipairs(outputs) do if not removeExact(inventory,output) then rolled=false end end
        rolled=writeFraction(consumer,state,fraction,mode) and rolled
        if mode~="modData" then
            call(consumer,"setUseDelta",priorUse)
            local checked,value=call(consumer,"getUseDelta")
            rolled=checked and type(value)=="number" and math.abs(value-priorUse)<=0.000001 and rolled
        end
        if okActive then
            call(consumer,"setActivated",wasActive==true)
            local checked,value=call(consumer,"isActivated");if not checked then checked,value=call(consumer,"getActivated") end
            rolled=checked and value==wasActive and rolled
        end
        if rolled then clearClaims(record,consumer,outputs,player) else quarantine(record,"clear rollback unverified",player,consumer,outputs) end
        return false,"could not clear multi-cell consumer"
    end
    for _,key in ipairs({"cellSet","batteryType","capacity","baseUseDelta","resistance","storageMode","loadType","consumptionMultiplier"}) do state[key]=nil end
    clearClaims(record,consumer,outputs,player)
    for _,output in ipairs(outputs) do if type(sendAddItemToContainer)=="function" then pcall(sendAddItemToContainer,inventory,output) end end
    return true,outputs
end

function B47ANCEDPower.replaceBatterySet(player,consumer,replacements)
    if not authoritative() then return false,"non-authority" end
    local valid,reason=B47ANCEDPower.validateBatterySet(consumer,replacements)
    if not valid then return false,reason end
    for _,battery in ipairs(replacements) do
        local data=modData(battery)
        if not B47ANCEDPower.ownsServiceItem(player,battery) or type(data)~="table"
            or data.B47ANCEDPowerServiceRecovery~=nil or data.B47ANCEDPowerEnergyRecovery~=nil then
            return false,"replacement battery unavailable"
        end
    end
    local oldSet=B47ANCEDPower.getInstalledCellSet(consumer)
    if not oldSet then return false,"no installed cell set" end
    local extracted,oldCells=B47ANCEDPower.extractBatterySet(player,consumer)
    if not extracted then return false,oldCells end
    local installed,installReason=B47ANCEDPower.installBatterySet(player,consumer,replacements)
    if installed then return true,oldCells end
    local restored,restoreReason=B47ANCEDPower.installBatterySet(player,consumer,oldCells)
    if not restored then
        return false,"replacement failed: "..tostring(installReason).."; rollback failed: "..tostring(restoreReason)
    end
    return false,installReason
end

function B47ANCEDPower.installBattery(player,consumer,battery)
    local required=B47ANCEDPower.getRequiredCellCount(consumer,battery)
    if required and required>1 then return false,"requires "..required.." cells; use installBatterySet" end
    return singleInstall(player,consumer,battery)
end
function B47ANCEDPower.extractBattery(player,consumer)
    local data=modData(consumer); local state=type(data)=="table" and data.B47ANCEDPower or nil
    if type(state)=="table" and state.cellSet~=nil then return B47ANCEDPower.extractBatterySet(player,consumer) end
    return singleExtract(player,consumer)
end
function B47ANCEDPower.replaceBattery(player,consumer,battery)
    local data=modData(consumer); local state=type(data)=="table" and data.B47ANCEDPower or nil
    if type(state)=="table" and state.cellSet~=nil then
        if type(battery)=="table" and battery[1] then return B47ANCEDPower.replaceBatterySet(player,consumer,battery) end
        return false,"use replaceBatterySet for multi-cell consumer"
    end
    return singleReplace(player,consumer,battery)
end

return B47ANCEDPower
