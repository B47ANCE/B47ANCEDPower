B47ANCEDPower=B47ANCEDPower or {}
local B47ANCEDPower=B47ANCEDPower
local ItemAccess=require "B47ANCEDPower/ItemAccess"

B47ANCEDPower.VERSION="0.16.0"
B47ANCEDPower.Batteries=B47ANCEDPower.Batteries or {}
B47ANCEDPower.Consumers=B47ANCEDPower.Consumers or {}
B47ANCEDPower.Loads=B47ANCEDPower.Loads or {}
B47ANCEDPower.Config=B47ANCEDPower.Config or {
    BatteryCapacityMultiplier=1.0,
    GlobalConsumptionMultiplier=1.0,
    UVConsumptionMultiplier=1.0,
    EnableImprovisedAdapters=true,
    ImprovisedEfficiencyMultiplier=1.0,
    ImprovisedResistanceMultiplier=1.0,
    EnableVanillaBatteryLootConversion=true,
    LootWeightAAA=30,
    LootWeightAA=42,
    LootWeightC=10,
    LootWeightD=10,
    LootWeight9V=6,
    LootWeightLithiumPack=2,
    BatteryServiceTimeMultiplier=1.0,
    ToolAssistedReplaceTimeBonus=0.10,
    DefaultBatteryInstallTime=55,
    DefaultBatteryRemoveTime=35,
    BatteryPackAssemblyEfficiency=0.90,
    DigitalWatchDrainPerMinute=0.0000002,
    CoinCellLootChance=0.10,
    SolarMilitaryWatchLootChance=0.003,
}
local function applySandbox()
    local root=rawget(_G,"SandboxVars")
    local values=root and root.B47ANCEDPower or nil
    if not values then return false end
    for key in pairs(B47ANCEDPower.Config) do if values[key]~=nil then B47ANCEDPower.Config[key]=values[key] end end
    return true
end
B47ANCEDPower.applySandbox=applySandbox
applySandbox()
if Events and Events.OnGameStart then Events.OnGameStart.Add(applySandbox) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(applySandbox) end

local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end
local function fullType(value)
    if type(value)=="string" then return value end
    local ok,result=call(value,"getFullType")
    return ok and result or nil
end
local function modData(item)
    local ok,result=call(item,"getModData")
    return ok and result or nil
end
local function copy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {}; if seen[value] then return seen[value] end
    local result={}; seen[value]=result
    for key,entry in pairs(value) do result[copy(key,seen)]=copy(entry,seen) end
    return result
end

local function restoreTable(target,snapshot)
    for key in pairs(target) do target[key]=nil end
    for key,value in pairs(snapshot or {}) do target[key]=copy(value) end
end
local function authoritative()
    return not (type(isClient)=="function" and isClient()==true
        and not (type(isServer)=="function" and isServer()==true))
end

function B47ANCEDPower.registerBattery(def)
    assert(type(def)=="table" and type(def.item)=="string","battery.item is required")
    assert(type(def.size)=="string" and def.size~="","battery.size is required")
    local profile=copy(def)
    profile.capacity=math.max(0.01,(tonumber(def.capacity) or 1.0)
        * math.max(0.01,tonumber(B47ANCEDPower.Config.BatteryCapacityMultiplier) or 1.0))
    profile.nominalVoltage=math.max(0,tonumber(def.nominalVoltage) or 1.5)
    profile.efficiency=clamp(tonumber(def.efficiency) or 1.0,0,1)
    profile.pack=def.pack==true
    B47ANCEDPower.Batteries[profile.item]=profile
    return profile
end

function B47ANCEDPower.registerConsumer(def)
    assert(type(def)=="table" and type(def.item)=="string","consumer.item is required")
    local profile=copy(def)
    profile.sizes=profile.sizes or {"LEGACY"}
    assert(type(profile.sizes)=="table","consumer.sizes must be a table")
    local sizes={}
    for _,size in ipairs(profile.sizes) do
        assert(type(size)=="string" and size~="","consumer size must be a non-empty string")
        sizes[#sizes+1]=size
    end
    assert(#sizes>0,"consumer must accept at least one battery size")
    profile.sizes=sizes
    profile.referenceCapacity=math.max(0.01,tonumber(profile.referenceCapacity) or 2.5)
    profile.drainMultiplier=math.max(0,tonumber(profile.drainMultiplier) or 1.0)
    -- Cell count is enforced by the versioned CellSet/service layer. Explicit
    -- battery packs remain one physical inventory item even when they represent
    -- multiple taped cells.
    profile.nominalCellCount=math.max(1,math.floor(tonumber(profile.nominalCellCount) or 1))
    profile.nominalVoltage=math.max(0,tonumber(profile.nominalVoltage) or 0)
    profile.runtimeTargetHours=math.max(0,tonumber(profile.runtimeTargetHours) or 0)
    profile.installTime=math.max(1,tonumber(profile.installTime) or B47ANCEDPower.Config.DefaultBatteryInstallTime)
    profile.removeTime=math.max(1,tonumber(profile.removeTime) or B47ANCEDPower.Config.DefaultBatteryRemoveTime)
    profile.accessToolRequired=profile.accessToolRequired==true
    B47ANCEDPower.Consumers[profile.item]=profile
    return profile
end

function B47ANCEDPower.registerLoad(def)
    assert(type(def)=="table" and type(def.item)=="string","load.item is required")
    local profile=copy(def)
    profile.consumptionMultiplier=math.max(0,tonumber(def.consumptionMultiplier) or 1.0)
    B47ANCEDPower.Loads[profile.item]=profile
    return profile
end

function B47ANCEDPower.getBatteryProfile(value) return B47ANCEDPower.Batteries[fullType(value)] end
function B47ANCEDPower.getConsumerProfile(value) return B47ANCEDPower.Consumers[fullType(value)] end
function B47ANCEDPower.getLoadProfile(value) return B47ANCEDPower.Loads[fullType(value)] end
function B47ANCEDPower.isRegisteredBattery(value) return B47ANCEDPower.getBatteryProfile(value)~=nil end
function B47ANCEDPower.isRegisteredConsumer(value) return B47ANCEDPower.getConsumerProfile(value)~=nil end

local conversionTypes={
    {item="B47ANCEDPower.BatteryAAA",key="LootWeightAAA"}, {item="B47ANCEDPower.BatteryAA",key="LootWeightAA"},
    {item="B47ANCEDPower.BatteryC",key="LootWeightC"}, {item="B47ANCEDPower.BatteryD",key="LootWeightD"},
    {item="B47ANCEDPower.Battery9V",key="LootWeight9V"}, {item="B47ANCEDPower.BatteryLithiumPack",key="LootWeightLithiumPack"},
}
function B47ANCEDPower.chooseConvertedBatteryType()
    local total=0
    for _,entry in ipairs(conversionTypes) do total=total+math.max(0,tonumber(B47ANCEDPower.Config[entry.key]) or 0) end
    if total<=0 then return "B47ANCEDPower.BatteryAA" end
    local pick=(ZombRand and ZombRand(total) or math.floor(math.random()*total)); local running=0
    for _,entry in ipairs(conversionTypes) do
        running=running+math.max(0,tonumber(B47ANCEDPower.Config[entry.key]) or 0)
        if pick<running then return entry.item end
    end
    return "B47ANCEDPower.BatteryAA"
end

function B47ANCEDPower.getCharge(item)
    local profile=B47ANCEDPower.getBatteryProfile(item); if not profile then return nil end
    local data=modData(item)
    if data and tonumber(data.B47ANCEDPowerCharge) then return clamp(tonumber(data.B47ANCEDPowerCharge),0,profile.capacity) end
    local ok,delta=call(item,"getUsedDelta")
    if ok and tonumber(delta) then return clamp(tonumber(delta),0,1)*profile.capacity end
    return profile.capacity
end

function B47ANCEDPower.setCharge(item,charge)
    local profile=B47ANCEDPower.getBatteryProfile(item); if not profile then return false end
    charge=clamp(tonumber(charge) or 0,0,profile.capacity)
    local data=modData(item); if data then data.B47ANCEDPowerCharge=charge end
    call(item,"setUsedDelta",charge/profile.capacity)
    return true
end

function B47ANCEDPower.accepts(consumer,battery)
    local device=B47ANCEDPower.getConsumerProfile(consumer)
    local cell=B47ANCEDPower.getBatteryProfile(battery)
    if not device or not cell then return false end
    for _,size in ipairs(device.sizes) do
        if size==cell.size or (size=="LEGACY" and cell.item=="Base.Battery") then return true end
    end
    return false
end

local function stateFor(consumer,create)
    local data=modData(consumer); if type(data)~="table" then return nil end
    if create and data.B47ANCEDPower==nil then data.B47ANCEDPower={} end
    -- A malformed stored value is not an empty battery compartment. Preserve
    -- it for inspection instead of silently resetting it during migration.
    return type(data.B47ANCEDPower)=="table" and data.B47ANCEDPower or nil
end
local function readConsumerCharge(consumer)
    local ok,value=call(consumer,"getUsedDelta")
    if ok and tonumber(value)~=nil then return true,clamp(tonumber(value),0,1),"usedDelta" end
    ok,value=call(consumer,"getCurrentUsesFloat")
    if ok and tonumber(value)~=nil then return true,clamp(tonumber(value),0,1),"currentUsesFloat" end
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    local state=stateFor(consumer,false)
    if profile and profile.storageMode=="modData" then
        return true,clamp(tonumber(state and state.chargeFraction) or 0,0,1),"modData"
    end
    return false,nil,nil
end

-- Canonical read-only power decision for consumer frameworks. Callers should
-- never infer power from the presence of a battery record alone: native charge
-- may be empty, unavailable, or quarantined by an uncertain service operation.
function B47ANCEDPower.getConsumerPowerState(consumer)
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    if not profile then return nil,"unregistered consumer" end
    local data=modData(consumer)
    if type(data)~="table" then return {known=false,powered=false,reason="modData unavailable"} end
    if data.B47ANCEDPowerServiceRecovery~=nil then
        return {known=false,powered=false,reason="consumer requires inspection"}
    end
    if data.B47ANCEDPowerEnergyRecovery~=nil then
        return {known=false,powered=false,reason="consumer has pending energy transaction"}
    end
    local state=stateFor(consumer,false)
    if data.B47ANCEDPower~=nil and not state then
        return {known=false,powered=false,reason="malformed consumer state"}
    end
    local read,fraction,mode=readConsumerCharge(consumer)
    if not read or type(fraction)~="number" or fraction~=fraction then
        return {known=false,powered=false,reason="charge unavailable",
            batteryType=state and state.batteryType or nil}
    end
    local batteryType=state and state.batteryType or nil
    if batteryType and not B47ANCEDPower.getBatteryProfile(batteryType) then
        return {known=false,powered=false,reason="unknown installed battery",batteryType=batteryType}
    end
    return {known=true,powered=fraction>0.000001,chargeFraction=clamp(fraction,0,1),
        batteryType=batteryType,storageMode=(state and state.storageMode) or mode,
        legacy=batteryType==nil and fraction>0.000001}
end
local function writeConsumerCharge(consumer,value,mode)
    value=clamp(tonumber(value) or 0,0,1)
    if mode=="modData" then
        local state=stateFor(consumer,true); if not state then return false end
        state.chargeFraction=value
        return true
    end
    -- A callable native method (or a mod wrapper) may silently do nothing.
    -- Verify the same storage surface selected by readConsumerCharge; never
    -- write a different surface and assume the device now uses that value.
    local setter=mode=="currentUsesFloat" and "setCurrentUsesFloat" or "setUsedDelta"
    local getter=mode=="currentUsesFloat" and "getCurrentUsesFloat" or "getUsedDelta"
    call(consumer,setter,value)
    local checked,actual=call(consumer,getter)
    return checked and type(actual)=="number" and actual==actual
        and math.abs(actual-value)<=0.000001
end
function B47ANCEDPower.getInstalledBatteryType(consumer)
    local state=stateFor(consumer,false)
    return state and state.batteryType or nil
end
function B47ANCEDPower.initializeEmbeddedBattery(consumer,batteryType,fraction)
    local data=modData(consumer)
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil then return false,"consumer requires inspection" end
    if B47ANCEDPower.getInstalledBatteryType(consumer) then return false,"already initialized" end
    local cell=B47ANCEDPower.getBatteryProfile(batteryType)
    local device=B47ANCEDPower.getConsumerProfile(consumer)
    if not cell or not device then return false,"unknown battery or consumer" end
    local accepted=false
    for _,size in ipairs(device.sizes) do if size==cell.size then accepted=true break end end
    if not accepted then return false,"incompatible" end
    local state=stateFor(consumer,true); if not state then return false,"consumer state unavailable" end
    local snapshot=copy(state)
    local recovery={schemaVersion=1,status="executing",mode="embedded-initialization",state=snapshot}
    data.B47ANCEDPowerServiceRecovery=recovery
    state.batteryType=cell.item; state.capacity=cell.capacity
    state.baseUseDelta=tonumber(device.baseUseDelta) or 0
    state.resistance=1; state.storageMode=device.storageMode or "modData"
    state.chargeFraction=clamp(tonumber(fraction) or 1,0,1)
    local called,refreshed=pcall(B47ANCEDPower.refreshConsumer,consumer)
    if not called or refreshed~=true then
        restoreTable(state,snapshot)
        recovery.status="inspection_required"
        return false,"embedded initialization could not configure consumer"
    end
    data.B47ANCEDPowerServiceRecovery=nil
    return true
end
function B47ANCEDPower.getBatteryInstallTime(consumer)
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    return math.max(1,(tonumber(profile and profile.installTime) or B47ANCEDPower.Config.DefaultBatteryInstallTime)
        * math.max(0.01,tonumber(B47ANCEDPower.Config.BatteryServiceTimeMultiplier) or 1))
end
function B47ANCEDPower.getBatteryRemoveTime(consumer)
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    return math.max(1,(tonumber(profile and profile.removeTime) or B47ANCEDPower.Config.DefaultBatteryRemoveTime)
        * math.max(0.01,tonumber(B47ANCEDPower.Config.BatteryServiceTimeMultiplier) or 1))
end
function B47ANCEDPower.getBatteryReplaceTime(consumer)
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    local total=B47ANCEDPower.getBatteryRemoveTime(consumer)+B47ANCEDPower.getBatteryInstallTime(consumer)
    if profile and profile.accessToolRequired then
        local bonus=clamp(tonumber(B47ANCEDPower.Config.ToolAssistedReplaceTimeBonus) or 0.10,0,0.5)
        total=total*(1-bonus)
    end
    return math.max(1,math.floor(total+0.5))
end

local function standardBatteryForSize(size)
    local matches={}
    for item,profile in pairs(B47ANCEDPower.Batteries) do
        if profile.size==size and item~="Base.Battery" and not profile.improvised then matches[#matches+1]=item end
    end
    table.sort(matches)
    return matches[1]
end

-- Converts the charge already embedded in a vanilla flashlight into canonical
-- B47ANCEDPower state. No physical battery is created or consumed: this is the
-- battery that was already inside the device.
function B47ANCEDPower.migrateInstalledLegacyBattery(consumer)
    local data=modData(consumer)
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil then return false,"consumer requires inspection" end
    if data.B47ANCEDPower~=nil and type(data.B47ANCEDPower)~="table" then return false,"malformed consumer state" end
    local profile=B47ANCEDPower.getConsumerProfile(consumer)
    if not profile or B47ANCEDPower.getInstalledBatteryType(consumer) then return false,"not-needed" end
    local okCharge,fraction,storageMode=readConsumerCharge(consumer)
    if not okCharge or not fraction or fraction<=0.0001 then return false,"empty" end
    local batteryType=nil
    for _,size in ipairs(profile.sizes) do
        if size~="LEGACY" then batteryType=standardBatteryForSize(size); if batteryType then break end end
    end
    if not batteryType then return false,"no-sized-replacement" end
    local cell=B47ANCEDPower.getBatteryProfile(batteryType)
    local okUse,baseUseDelta=call(consumer,"getUseDelta")
    if not okUse or tonumber(baseUseDelta)==nil then return false,"unsupported-consumer" end
    local state=stateFor(consumer,true)
    if not state then return false,"consumer state unavailable" end
    local snapshot=copy(state)
    local recovery={schemaVersion=1,status="executing",mode="embedded-migration",state=snapshot,
        chargeFraction=fraction,storageMode=storageMode}
    data.B47ANCEDPowerServiceRecovery=recovery
    state.batteryType=batteryType; state.capacity=cell.capacity; state.baseUseDelta=tonumber(baseUseDelta)
    state.resistance=1.0; state.storageMode=storageMode; state.migratedLegacyBattery=true
    local called,refreshed=pcall(B47ANCEDPower.refreshConsumer,consumer)
    if not called or refreshed~=true then
        restoreTable(state,snapshot)
        call(consumer,"setUseDelta",baseUseDelta)
        recovery.status="inspection_required"
        return false,"embedded migration could not apply drain"
    end
    data.B47ANCEDPowerServiceRecovery=nil
    return true,batteryType
end

function B47ANCEDPower.getEffectiveConsumptionMultiplier(consumer)
    local device=B47ANCEDPower.getConsumerProfile(consumer)
    if not device then return 1.0,nil end
    local loadType=nil
    if type(device.loadResolver)=="function" then
        local ok,value=pcall(device.loadResolver,consumer)
        if ok then loadType=value end
    end
    local load=loadType and B47ANCEDPower.getLoadProfile(loadType) or nil
    local dynamicMultiplier=1.0
    if type(device.consumptionResolver)=="function" then
        local ok,value=pcall(device.consumptionResolver,consumer,loadType)
        value=ok and tonumber(value) or nil
        if value and value==value and value~=math.huge and value~=-math.huge then
            dynamicMultiplier=math.max(0,value)
        end
    end
    local multiplier=device.drainMultiplier*(load and load.consumptionMultiplier or 1.0)*dynamicMultiplier
    multiplier=multiplier*math.max(0,tonumber(B47ANCEDPower.Config.GlobalConsumptionMultiplier) or 1.0)
    if loadType and string.find(string.upper(tostring(loadType)),"UV",1,true) then
        multiplier=multiplier*math.max(0,tonumber(B47ANCEDPower.Config.UVConsumptionMultiplier) or 1.0)
    end
    return multiplier,loadType,dynamicMultiplier
end

-- Absolute stored-energy demand for one in-game hour. Native activated
-- drainables consume one useDelta every ten in-game minutes; converting that
-- to capacity units here lets world-present consumers use the identical
-- battery/load/device model without depending on an equipped-item update.
function B47ANCEDPower.getConsumerEnergyRatePerHour(consumer)
    local state=stateFor(consumer,false);local device=B47ANCEDPower.getConsumerProfile(consumer)
    if not state or not device or not state.batteryType then return nil,"configured battery required" end
    local base=tonumber(state.baseUseDelta) or tonumber(device.baseUseDelta)
    if not base or base<0 then return nil,"base consumption unavailable" end
    local multiplier=B47ANCEDPower.getEffectiveConsumptionMultiplier(consumer)
    local reference=math.max(0.01,tonumber(device.referenceCapacity) or 2.5)
    local resistance=math.max(0,tonumber(state.resistance) or 1)
    return base*reference*multiplier*resistance*6
end

function B47ANCEDPower.refreshConsumer(consumer)
    local state=stateFor(consumer,false)
    local device=B47ANCEDPower.getConsumerProfile(consumer)
    if not state or not state.batteryType or not device or not state.baseUseDelta then return false end
    local cell=B47ANCEDPower.getBatteryProfile(state.batteryType)
    if not cell then return false end
    local multiplier,loadType=B47ANCEDPower.getEffectiveConsumptionMultiplier(consumer)
    local installedCapacity=math.max(0.01,tonumber(state.capacity) or cell.capacity)
    local effectiveDrain=state.baseUseDelta*(device.referenceCapacity/installedCapacity)*multiplier*(state.resistance or 1.0)
    if state.storageMode=="modData" then state.effectiveDrain=effectiveDrain
    else
        call(consumer,"setUseDelta",effectiveDrain)
        local checked,actual=call(consumer,"getUseDelta")
        if not checked or type(actual)~="number" or actual~=actual
            or math.abs(actual-effectiveDrain)>math.max(0.000000001,math.abs(effectiveDrain)*0.00001) then
            return false,"consumer drain update was not applied"
        end
    end
    state.loadType=loadType
    state.consumptionMultiplier=multiplier
    return true,multiplier,loadType
end

function B47ANCEDPower.consumeEnergy(consumer,amount)
    if not authoritative() then return false,"non-authority" end
    local data=modData(consumer)
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil or data.B47ANCEDPowerEnergyRecovery~=nil then
        return false,"consumer requires inspection"
    end
    local state=stateFor(consumer,false)
    if not state or not state.batteryType then return false,"no B47ANCEDPower battery" end
    local capacity=math.max(0.01,tonumber(state.capacity) or 1)
    local ok,fraction,mode=readConsumerCharge(consumer)
    if not ok then return false,"unsupported consumer power API" end
    amount=tonumber(amount)
    if type(amount)~="number" or amount~=amount or math.abs(amount)==math.huge or amount<0 then
        return false,"invalid energy amount"
    end
    local remaining=math.max(0,fraction*capacity-amount)
    if not writeConsumerCharge(consumer,remaining/capacity,state.storageMode or mode) then
        return false,"could not update consumer charge"
    end
    return true,remaining
end

local ENERGY_RECOVERY_KEY="B47ANCEDPowerEnergyRecovery"
function B47ANCEDPower.beginEnergyTransaction(consumer,amount,operationId)
    if not authoritative() then return false,"non-authority" end
    if type(operationId)~="string" or operationId=="" or #operationId>128 then return false,"operation id required" end
    local data=modData(consumer)
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil or data[ENERGY_RECOVERY_KEY]~=nil then
        return false,"consumer requires inspection"
    end
    local state=stateFor(consumer,false); if not state or not state.batteryType then return false,"no B47ANCEDPower battery" end
    local read,before,mode=readConsumerCharge(consumer); if not read then return false,"unsupported consumer power API" end
    local capacity=math.max(0.01,tonumber(state.capacity) or 1)
    amount=tonumber(amount)
    if type(amount)~="number" or amount~=amount or math.abs(amount)==math.huge or amount<=0 then return false,"invalid energy amount" end
    local absolute=before*capacity
    if absolute+0.0000001<amount then return false,"insufficient energy" end
    local after=(absolute-amount)/capacity
    local record={schemaVersion=1,status="executing",operationId=operationId,beforeFraction=before,
        afterFraction=after,amount=amount,capacity=capacity,storageMode=state.storageMode or mode}
    data[ENERGY_RECOVERY_KEY]=record
    local wrote=writeConsumerCharge(consumer,after,record.storageMode)
    local verified,current=readConsumerCharge(consumer)
    if not wrote or not verified or math.abs(current-after)>0.000001 then
        local restored=writeConsumerCharge(consumer,before,record.storageMode)
        local checked,value=readConsumerCharge(consumer)
        if restored and checked and math.abs(value-before)<=0.000001 then data[ENERGY_RECOVERY_KEY]=nil
        else record.status="inspection_required" end
        return false,"energy reservation failed"
    end
    record.status="reserved"
    return true,{operationId=operationId,amount=amount,remaining=after*capacity}
end

function B47ANCEDPower.commitEnergyTransaction(consumer,operationId)
    if not authoritative() then return false,"non-authority" end
    local data=modData(consumer); local record=type(data)=="table" and data[ENERGY_RECOVERY_KEY] or nil
    if type(record)~="table" or record.operationId~=operationId or record.status~="reserved" then
        return false,"energy reservation unavailable"
    end
    local read,current=readConsumerCharge(consumer)
    if not read or math.abs(current-record.afterFraction)>0.000001 then
        record.status="inspection_required"; return false,"energy reservation changed; inspection required"
    end
    data[ENERGY_RECOVERY_KEY]=nil
    return true,{operationId=operationId,amount=record.amount,remaining=current*record.capacity}
end

function B47ANCEDPower.rollbackEnergyTransaction(consumer,operationId)
    if not authoritative() then return false,"non-authority" end
    local data=modData(consumer); local record=type(data)=="table" and data[ENERGY_RECOVERY_KEY] or nil
    if type(record)~="table" or record.operationId~=operationId
        or (record.status~="reserved" and record.status~="executing") then return false,"energy reservation unavailable" end
    local wrote=writeConsumerCharge(consumer,record.beforeFraction,record.storageMode)
    local read,current=readConsumerCharge(consumer)
    if not wrote or not read or math.abs(current-record.beforeFraction)>0.000001 then
        record.status="inspection_required"; return false,"energy rollback failed; inspection required"
    end
    data[ENERGY_RECOVERY_KEY]=nil
    return true,{operationId=operationId,restored=current*record.capacity}
end

function B47ANCEDPower.inspectEnergyRecovery(consumer)
    local data=modData(consumer); local record=type(data)=="table" and data[ENERGY_RECOVERY_KEY] or nil
    return type(record)=="table" and copy(record) or nil
end
B47ANCEDPower.ENERGY_RECOVERY_KEY=ENERGY_RECOVERY_KEY

function B47ANCEDPower.findOwnedItemById(player,itemId,limit)
    itemId=tonumber(itemId)
    if not player or not itemId or itemId~=itemId then return nil,"invalid item id" end
    local gotRoot,root=call(player,"getInventory")
    if not gotRoot or not root then return nil,"player inventory unavailable" end
    limit=math.max(1,math.floor(tonumber(limit) or 512))
    local queue={root}; local head,visited=1,0
    while head<=#queue and visited<limit do
        local container=queue[head]; head=head+1
        local gotItems,items=call(container,"getItems")
        local gotSize,size=gotItems and call(items,"size") or false,nil
        if gotSize and type(size)=="number" then
            for index=0,math.min(math.floor(size)-1,limit-visited-1) do
                local gotItem,item=call(items,"get",index)
                if gotItem and item then
                    visited=visited+1
                    local identified,id=call(item,"getID")
                    if identified and tonumber(id)==itemId then
                        local gotOuter,outer=call(item,"getOutermostContainer")
                        if gotOuter and outer==root then return item end
                        return nil,"item ownership mismatch"
                    end
                    local gotNested,nested=call(item,"getInventory")
                    if gotNested and nested then queue[#queue+1]=nested end
                end
            end
        end
    end
    return nil,visited>=limit and "inventory search budget exceeded" or "item not found"
end

-- Runtime references are held only while a synchronous service is executing.
-- Persisted records contain IDs/state, never InventoryItem userdata.
local serviceOutputs={}
local serviceSequence=0
local function nextServiceOperationId(consumer)
    serviceSequence=serviceSequence+1
    local age=0
    if type(getGameTime)=="function" then
        local ok,value=pcall(function() return getGameTime():getWorldAgeHours() end)
        value=ok and tonumber(value) or nil
        if value and value==value and math.abs(value)<math.huge then age=math.max(0,value) end
    end
    local identified,id=call(consumer,"getID")
    if not identified or type(id)~="number" then id=0 end
    return string.format("PW-%d-%d-%d",math.floor(age*3600),math.floor(id),serviceSequence)
end
local function removeItem(player,item)
    local ok,container=call(item,"getContainer"); if not ok or not container then return false end
    local checked,present=call(container,"contains",item)
    if not checked or present~=true then return false end
    call(player,"removeFromHands",item)
    call(container,"Remove",item)
    local verified,remains=call(container,"contains",item)
    if not verified or remains~=false then return false end
    if sendRemoveItemFromContainer then pcall(sendRemoveItemFromContainer,container,item) end
    return true
end
local function addItem(player,itemType,prepare)
    local ok,inventory=call(player,"getInventory"); if not ok then return nil end
    local made,item=pcall(function() return instanceItem(itemType) end)
    if not made or not item then return nil end
    if prepare then
        local prepared,ready=pcall(prepare,item)
        if not prepared or ready~=true then return nil end
    end
    call(inventory,"AddItem",item)
    local checked,present=call(inventory,"contains",item)
    if not checked or present~=true then return nil end
    return item
end
local function publishAdded(player,item)
    local ok,inventory=call(player,"getInventory")
    if ok and sendAddItemToContainer then pcall(sendAddItemToContainer,inventory,item) end
end

function B47ANCEDPower.convertLegacyBatteryInContainer(container,battery)
    if type(isClient)=="function" and isClient()==true
        and not (type(isServer)=="function" and isServer()==true) then return false,"non-authority" end
    if fullType(battery)~="Base.Battery" then return false,"not-legacy" end
    local data=modData(battery)
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil then return false,"battery requires inspection" end
    local checked,present=call(container,"contains",battery)
    local _,actualContainer=call(battery,"getContainer")
    if not checked or present~=true or actualContainer~=container then return false,"battery not in container" end
    local record={schemaVersion=1,status="executing",mode="legacy-conversion"}
    data.B47ANCEDPowerServiceRecovery=record
    local replacement,outputData
    local attemptedInsert=false
    local ran,success=pcall(function()
        local source=B47ANCEDPower.getBatteryProfile(battery)
        local charge=B47ANCEDPower.getCharge(battery)
        if not source or not charge then return false end
        -- getCharge is absolute energy, not a fraction. Legacy conversion
        -- preserves percent-full across the newly selected capacity.
        local fraction=clamp(charge/source.capacity,0,1)
        replacement=instanceItem(B47ANCEDPower.chooseConvertedBatteryType())
        if not replacement then return false end
        outputData=modData(replacement)
        local profile=B47ANCEDPower.getBatteryProfile(replacement)
        if type(outputData)~="table" or not profile then return false end
        outputData.B47ANCEDPowerServiceRecovery=record
        if not B47ANCEDPower.setCharge(replacement,fraction*profile.capacity) then return false end
        attemptedInsert=true
        call(container,"AddItem",replacement)
        local added,hasOutput=call(container,"contains",replacement)
        if not added or hasOutput~=true then return false end
        call(container,"Remove",battery)
        local removed,hasSource=call(container,"contains",battery)
        return removed and hasSource==false
    end)
    if not ran or not success then
        if attemptedInsert then record.status="inspection_required"
        else
            data.B47ANCEDPowerServiceRecovery=nil
            if outputData then outputData.B47ANCEDPowerServiceRecovery=nil end
        end
        return false,"legacy conversion failed; inspect source and output"
    end
    data.B47ANCEDPowerServiceRecovery=nil
    outputData.B47ANCEDPowerServiceRecovery=nil
    if sendRemoveItemFromContainer then pcall(sendRemoveItemFromContainer,container,battery) end
    if sendAddItemToContainer then pcall(sendAddItemToContainer,container,replacement) end
    return true,replacement
end

function B47ANCEDPower.convertLooseLegacyBattery(player,battery)
    if not B47ANCEDPower.ownsServiceItem(player,battery) then return false,"battery not owned" end
    local _,container=call(battery,"getContainer")
    return B47ANCEDPower.convertLegacyBatteryInContainer(container,battery)
end

local function installBattery(player,consumer,battery)
    if not player or not B47ANCEDPower.accepts(consumer,battery) then return false,"incompatible" end
    if B47ANCEDPower.getInstalledBatteryType(consumer) then return false,"occupied" end
    local okStored,delta,storageMode=readConsumerCharge(consumer)
    if tonumber(delta) and tonumber(delta)>0.0001 then return false,"native battery already installed" end
    local cell=B47ANCEDPower.getBatteryProfile(battery)
    local charge=B47ANCEDPower.getCharge(battery) or 0; if charge<=0 then return false,"empty" end
    local state=stateFor(consumer,true)
    if not state then return false,"consumer state unavailable" end
    local stateSnapshot=copy(state)
    local okUse,baseUseDelta=call(consumer,"getUseDelta")
    if (not okUse or tonumber(baseUseDelta)==nil) and B47ANCEDPower.getConsumerProfile(consumer) then
        baseUseDelta=tonumber(B47ANCEDPower.getConsumerProfile(consumer).baseUseDelta)
        okUse=baseUseDelta~=nil
    end
    if not okStored or not okUse or tonumber(baseUseDelta)==nil then
        return false,string.format("unsupported consumer power API item=%s charge=%s useDelta=%s",
            tostring(fullType(consumer)),tostring(okStored),tostring(okUse))
    end
    modData(consumer).B47ANCEDPowerServiceRecovery.mutated=true
    state.batteryType=cell.item; state.capacity=cell.capacity; state.baseUseDelta=tonumber(baseUseDelta)
    state.resistance=tonumber((modData(battery) or {}).B47ANCEDPowerResistance) or 1.0
    -- Preserve our crafted-cell provenance across installation. Do not copy
    -- arbitrary third-party item ModData into the consumer's saved state.
    local batteryData=modData(battery) or {}
    state.batteryMetadata={}
    for _,key in ipairs({"B47ANCEDPowerSource","B47ANCEDPowerSources","B47ANCEDPowerImprovised","B47ANCEDPowerResistance"}) do
        local value=batteryData[key]
        if type(value)=="string" or type(value)=="boolean" or
            (type(value)=="number" and value==value and math.abs(value)<math.huge) then
            state.batteryMetadata[key]=value
        end
    end
    state.storageMode=storageMode
    local okSetUsed=writeConsumerCharge(consumer,clamp(charge/cell.capacity,0,1),storageMode)
    local refreshed=B47ANCEDPower.refreshConsumer(consumer)
    if not okSetUsed or not refreshed then
        restoreTable(state,stateSnapshot)
        writeConsumerCharge(consumer,delta,storageMode)
        call(consumer,"setUseDelta",baseUseDelta)
        return false,"could not configure consumer"
    end
    if not removeItem(player,battery) then
        restoreTable(state,stateSnapshot)
        writeConsumerCharge(consumer,delta,storageMode)
        call(consumer,"setUseDelta",baseUseDelta)
        return false,"could not consume battery"
    end
    return true
end

local function extractBattery(player,consumer)
    local state=stateFor(consumer,false)
    if not state or not state.batteryType then return false,"no B47ANCEDPower battery" end
    local okDelta,delta,detectedMode=readConsumerCharge(consumer)
    local storageMode=state.storageMode or detectedMode
    local okUse,currentUseDelta=call(consumer,"getUseDelta")
    if state.storageMode=="modData" then okUse=true; currentUseDelta=state.baseUseDelta end
    local okActive,wasActive=call(consumer,"isActivated")
    if not okActive then okActive,wasActive=call(consumer,"getActivated") end
    if not okDelta or not okUse then return false,"unsupported consumer power API" end
    modData(consumer).B47ANCEDPowerServiceRecovery.mutated=true
    local battery=addItem(player,state.batteryType,function(created)
        local data=modData(created)
        if type(data)~="table" then return false end
        local record=modData(consumer).B47ANCEDPowerServiceRecovery
        local outputs=serviceOutputs[record]
        if not outputs then return false end
        outputs[#outputs+1]=created
        data.B47ANCEDPowerServiceRecovery=record
        local identified,id=call(created,"getID")
        if identified and type(id)=="number" then
            record.outputItemIds=record.outputItemIds or {}
            record.outputItemIds[#record.outputItemIds+1]=id
        end
        for _,key in ipairs({"B47ANCEDPowerSource","B47ANCEDPowerSources","B47ANCEDPowerImprovised","B47ANCEDPowerResistance"}) do
            local value=type(state.batteryMetadata)=="table" and state.batteryMetadata[key] or nil
            if value~=nil then data[key]=value end
        end
        -- Older installed states already carry resistance, but lack metadata.
        if data.B47ANCEDPowerResistance==nil then data.B47ANCEDPowerResistance=state.resistance end
        return B47ANCEDPower.setCharge(created,clamp(tonumber(delta) or 0,0,1)*(tonumber(state.capacity) or 1))
    end)
    if not battery then return false,"could not return charged battery" end
    local restoredUse=true
    if state.baseUseDelta and state.storageMode~="modData" then
        call(consumer,"setUseDelta",state.baseUseDelta)
        local checked,actual=call(consumer,"getUseDelta")
        restoredUse=checked and type(actual)=="number" and actual==actual
            and math.abs(actual-state.baseUseDelta)<=math.max(0.000000001,math.abs(state.baseUseDelta)*0.00001)
    end
    local deactivated=true
    if state.storageMode~="modData" then
        call(consumer,"setActivated",false)
        local checked,active=call(consumer,"isActivated")
        if not checked then checked,active=call(consumer,"getActivated") end
        deactivated=checked and active==false
    end
    local cleared=writeConsumerCharge(consumer,0,storageMode)
    if not restoredUse or not deactivated or not cleared then
        call(consumer,"setUseDelta",currentUseDelta)
        writeConsumerCharge(consumer,delta,storageMode)
        if okActive then call(consumer,"setActivated",wasActive==true) end
        removeItem(player,battery)
        return false,"could not clear consumer"
    end
    state.batteryType=nil; state.capacity=nil; state.baseUseDelta=nil; state.resistance=nil; state.storageMode=nil
    state.loadType=nil; state.consumptionMultiplier=nil; state.batteryMetadata=nil
    publishAdded(player,battery)
    return true,battery
end

local function replaceBattery(player,consumer,replacement)
    if not B47ANCEDPower.getInstalledBatteryType(consumer) then return false,"no installed battery" end
    if not B47ANCEDPower.accepts(consumer,replacement) or (B47ANCEDPower.getCharge(replacement) or 0)<=0 then
        return false,"incompatible or empty replacement"
    end
    local extracted,oldBattery=extractBattery(player,consumer)
    if not extracted then return false,oldBattery end
    local installed,reason=installBattery(player,consumer,replacement)
    if installed then return true,oldBattery end
    -- Roll back with the exact physical cell and charge just extracted.
    local restored,restoreReason=installBattery(player,consumer,oldBattery)
    if not restored then
        return false,"replacement failed: "..tostring(reason).."; rollback failed: "..tostring(restoreReason)
    end
    return false,reason
end

-- Persistent, per-device quarantine. Failed operations that reached a mutation
-- are not automatically retried: rollback itself can fail in native/mod code.
function B47ANCEDPower.ownsServiceItem(player,item)
    return ItemAccess.ownsItem(player,item)
end
local function service(player,consumer,battery,mode,operation)
    if type(isClient)=="function" and isClient()==true
        and not (type(isServer)=="function" and isServer()==true) then
        return false,"non-authority"
    end
    local checked,dead=call(player,"isDead")
    if not checked or dead~=false then return false,"actor unavailable" end
    if not B47ANCEDPower.ownsServiceItem(player,consumer) then return false,"consumer not owned" end
    if battery and not B47ANCEDPower.ownsServiceItem(player,battery) then return false,"battery not owned" end
    local data=modData(consumer)
    if not player or type(data)~="table" then return false,"consumer state unavailable" end
    if data.B47ANCEDPowerServiceRecovery~=nil then return false,"battery service requires inspection" end
    local batteryData=battery and modData(battery) or nil
    if battery then
        if battery==consumer or type(batteryData)~="table" then return false,"battery state unavailable" end
        if batteryData.B47ANCEDPowerServiceRecovery~=nil then return false,"battery already claimed or requires inspection" end
    end
    local record={schemaVersion=1,status="executing",mode=mode,mutated=false,
        operationId=nextServiceOperationId(consumer),
        state=copy(data.B47ANCEDPower),batteryType=fullType(battery)}
    -- Claim both resources before invoking charge/ID adapters: those may call
    -- other mods synchronously. One physical cell cannot power two operations.
    data.B47ANCEDPowerServiceRecovery=record
    if batteryData then batteryData.B47ANCEDPowerServiceRecovery=record end
    serviceOutputs[record]={}
    local called,ok,result=pcall(function()
    local read,fraction,storageMode=readConsumerCharge(consumer)
    if read then record.chargeFraction=fraction; record.storageMode=storageMode end
    local identified,id=call(battery,"getID")
    if identified and type(id)=="number" then record.inputItemId=id end
    return operation(player,consumer,battery)
    end)
    if called and (ok==true or not record.mutated) then
        data.B47ANCEDPowerServiceRecovery=nil
        if batteryData then batteryData.B47ANCEDPowerServiceRecovery=nil end
    else
        record.status="inspection_required"
        record.reason=called and tostring(result) or "battery operation raised an exception"
    end
    -- Failed operations may also change or quarantine state. Replicate that
    -- marker without treating successful packet submission as a runtime proof.
    if type(syncItemModData)=="function" then pcall(syncItemModData,player,consumer) end
    if batteryData and batteryData.B47ANCEDPowerServiceRecovery~=nil
        and type(syncItemModData)=="function" then pcall(syncItemModData,player,battery) end
    local outputs=serviceOutputs[record]
    serviceOutputs[record]=nil
    for _,output in ipairs(outputs or {}) do
        local outputData=modData(output)
        if type(outputData)=="table" and data.B47ANCEDPowerServiceRecovery==nil then
            outputData.B47ANCEDPowerServiceRecovery=nil
        end
        local _,container=call(output,"getContainer")
        local checked,present=call(container,"contains",output)
        if checked and present==true and type(syncItemModData)=="function" then
            pcall(syncItemModData,player,output)
        end
    end
    if not called then return false,"battery operation raised an exception; inspect state" end
    return ok,result
end
function B47ANCEDPower.installBattery(player,consumer,battery)
    return service(player,consumer,battery,"install",installBattery)
end
function B47ANCEDPower.extractBattery(player,consumer)
    return service(player,consumer,nil,"remove",extractBattery)
end
function B47ANCEDPower.replaceBattery(player,consumer,battery)
    return service(player,consumer,battery,"replace",replaceBattery)
end

local function valuesEqual(left,right,seen)
    if type(left)~=type(right) then return false end
    if type(left)~="table" then return left==right end
    seen=seen or {}; if seen[left]==right then return true end; seen[left]=right
    for key,value in pairs(left) do if not valuesEqual(value,right[key],seen) then return false end end
    for key in pairs(right) do if left[key]==nil then return false end end
    return true
end

local function sameRecovery(record,candidate)
    if type(record)~="table" or type(candidate)~="table" then return false end
    if type(record.operationId)=="string" and record.operationId~="" then
        return candidate.operationId==record.operationId
    end
    return candidate==record
end

local function relatedRecoveryItems(record,items)
    local result={}
    for _,item in ipairs(type(items)=="table" and items or {}) do
        local data=modData(item)
        if type(data)=="table" and sameRecovery(record,data.B47ANCEDPowerServiceRecovery) then
            result[#result+1]=item
        end
    end
    return result
end

function B47ANCEDPower.inspectServiceRecovery(consumer,relatedItems)
    local data=modData(consumer)
    local record=type(data)=="table" and data.B47ANCEDPowerServiceRecovery or nil
    if type(record)~="table" then return {status="clear",requiresInspection=false} end
    if tonumber(record.schemaVersion)~=1 or record.status~="inspection_required"
        or (record.mode~="install" and record.mode~="remove" and record.mode~="replace") then
        return {status="manual-inspection",requiresInspection=true,reason="unsupported recovery record"}
    end
    local state=stateFor(consumer,false)
    local chargeRead,fraction=readConsumerCharge(consumer)
    local chargeMatches=chargeRead and type(record.chargeFraction)=="number"
        and math.abs(fraction-record.chargeFraction)<=0.000001
    local stateMatches=valuesEqual(copy(state),type(record.state)=="table" and record.state or nil)
    local related=relatedRecoveryItems(record,relatedItems)
    local outputs={}
    for _,item in ipairs(related) do
        local isOutput=record.mode=="remove"
        local identified,id=call(item,"getID")
        if identified and type(id)=="number" then
            for _,outputId in ipairs(type(record.outputItemIds)=="table" and record.outputItemIds or {}) do
                if outputId==id then isOutput=true break end
            end
        end
        if isOutput then outputs[#outputs+1]=item end
    end
    local status="manual-inspection"
    if stateMatches and chargeMatches then
        status=#outputs>0 and "rollback-output-found" or "safe-rollback"
    elseif record.mode=="remove" and state and state.batteryType==nil and #outputs==1 then
        status="committed-remove"
    end
    return {status=status,requiresInspection=true,mode=record.mode,
        operationId=record.operationId,stateMatches=stateMatches,chargeMatches=chargeMatches,
        relatedItems=related,outputItems=outputs,record=copy(record)}
end

function B47ANCEDPower.resolveServiceRecovery(player,consumer,relatedItems)
    if type(isClient)=="function" and isClient()==true
        and not (type(isServer)=="function" and isServer()==true) then return false,"non-authority" end
    if not B47ANCEDPower.ownsServiceItem(player,consumer) then return false,"consumer not owned" end
    local report=B47ANCEDPower.inspectServiceRecovery(consumer,relatedItems)
    if report.requiresInspection~=true then return true,report end
    if report.status~="safe-rollback" and report.status~="rollback-output-found"
        and report.status~="committed-remove" then return false,report.status,report end
    if report.status=="rollback-output-found" then
        for _,output in ipairs(report.outputItems) do
            local gotContainer,container=call(output,"getContainer")
            local checked,present=call(container,"contains",output)
            if not gotContainer or not checked or present~=true then return false,"output unavailable",report end
            call(container,"Remove",output)
            local verified,remains=call(container,"contains",output)
            if not verified or remains~=false then return false,"output-removal-unverified",report end
            if type(sendRemoveItemFromContainer)=="function" then pcall(sendRemoveItemFromContainer,container,output) end
        end
    end
    local data=modData(consumer)
    local record=type(data)=="table" and data.B47ANCEDPowerServiceRecovery or nil
    if not sameRecovery(record,report.record) then return false,"recovery record changed",report end
    data.B47ANCEDPowerServiceRecovery=nil
    for _,item in ipairs(report.relatedItems) do
        local itemData=modData(item)
        if type(itemData)=="table" and sameRecovery(record,itemData.B47ANCEDPowerServiceRecovery) then
            itemData.B47ANCEDPowerServiceRecovery=nil
            if type(syncItemModData)=="function" then pcall(syncItemModData,player,item) end
        end
    end
    if type(syncItemModData)=="function" then pcall(syncItemModData,player,consumer) end
    report.requiresInspection=false; report.resolved=true
    return true,report
end

function B47ANCEDPower.describeConsumer(consumer)
    local state=stateFor(consumer,false)
    local multiplier,loadType=B47ANCEDPower.getEffectiveConsumptionMultiplier(consumer)
    return {
        consumerType=fullType(consumer),
        profile=copy(B47ANCEDPower.getConsumerProfile(consumer)),
        installedBatteryType=state and state.batteryType or nil,
        installedCapacity=state and state.capacity or nil,
        installedCellCount=state and state.cellSet and type(state.cellSet.cells)=="table" and #state.cellSet.cells
            or (state and state.batteryType and 1 or 0),
        loadType=loadType,
        consumptionMultiplier=multiplier,
        resistance=state and state.resistance or nil,
        serviceRecovery=copy((modData(consumer) or {}).B47ANCEDPowerServiceRecovery),
    }
end

B47ANCEDPower.ItemAccess=ItemAccess
require "B47ANCEDPower/InfrastructureRegistry"
require "B47ANCEDPower/ApplianceProfiles"
require "B47ANCEDPower/InfrastructureEvents"
require "B47ANCEDPower/InfrastructureDiagnostics"

function B47ANCEDPower.makeAdapter(source,result,targetType)
    if B47ANCEDPower.Config.EnableImprovisedAdapters==false then return false,"improvised adapters disabled" end
    local sourceProfile=B47ANCEDPower.getBatteryProfile(source)
    local targetProfile=B47ANCEDPower.getBatteryProfile(targetType or result)
    if not sourceProfile or not targetProfile or not result then return false,"invalid adapter" end
    local efficiency=targetProfile.efficiency
        * math.max(0,tonumber(B47ANCEDPower.Config.ImprovisedEfficiencyMultiplier) or 1.0)
    local transferred=math.min(targetProfile.capacity,(B47ANCEDPower.getCharge(source) or 0)*math.min(1,efficiency))
    B47ANCEDPower.setCharge(result,transferred)
    local data=modData(result)
    if data then
        data.B47ANCEDPowerSource=sourceProfile.item
        data.B47ANCEDPowerImprovised=true
        data.B47ANCEDPowerResistance=(tonumber(targetProfile.resistance) or 1.25)
            * math.max(0.01,tonumber(B47ANCEDPower.Config.ImprovisedResistanceMultiplier) or 1.0)
    end
    return true,transferred
end

function B47ANCEDPower.onCreateImprovisedAA(recipeData)
    local okResult,result=call(recipeData,"getFirstCreatedItem")
    local okItems,items=call(recipeData,"getAllConsumedItems")
    if not okResult or not result or not okItems or not items then return end
    local source=nil; local _,size=call(items,"size")
    for i=0,(tonumber(size) or 0)-1 do
        local _,item=call(items,"get",i)
        local profile=B47ANCEDPower.getBatteryProfile(item)
        if profile and profile.size=="AAA" then source=item break end
    end
    if source then B47ANCEDPower.makeAdapter(source,result,"B47ANCEDPower.BatteryAAImprovised") end
end

function B47ANCEDPower.onCreateBatteryPack(recipeData)
    local okResult,result=call(recipeData,"getFirstCreatedItem")
    local okItems,items=call(recipeData,"getAllConsumedItems")
    if not okResult or not result or not okItems or not items then return end
    local energy=0; local sources={}; local _,size=call(items,"size")
    for i=0,(tonumber(size) or 0)-1 do
        local _,item=call(items,"get",i)
        if B47ANCEDPower.isRegisteredBattery(item) then
            energy=energy+(B47ANCEDPower.getCharge(item) or 0)
            sources[#sources+1]=fullType(item)
        end
    end
    local resultProfile=B47ANCEDPower.getBatteryProfile(result)
    local efficiency=clamp(tonumber(B47ANCEDPower.Config.BatteryPackAssemblyEfficiency) or 0.9,0,1)
    if resultProfile then B47ANCEDPower.setCharge(result,math.min(resultProfile.capacity,energy*efficiency)) end
    local data=modData(result)
    if data then data.B47ANCEDPowerImprovised=true; data.B47ANCEDPowerSources=table.concat(sources,";") end
end

return B47ANCEDPower
