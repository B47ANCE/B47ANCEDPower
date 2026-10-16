local B47ANCEDPower=require "B47ANCEDPower/API"

local CellSet={SCHEMA_VERSION=1,MAX_CELLS=16}

local function finite(value)
    value=tonumber(value)
    if not value or value~=value or math.abs(value)==math.huge then return nil end
    return value
end

local function scalarMetadata(source)
    local result={}
    for _,key in ipairs({"B47ANCEDPowerSource","B47ANCEDPowerSources","B47ANCEDPowerImprovised","B47ANCEDPowerResistance"}) do
        local value=type(source)=="table" and source[key] or nil
        if type(value)=="string" or type(value)=="boolean"
            or (type(value)=="number" and finite(value)) then result[key]=value end
    end
    return result
end

local function normalizeCell(source)
    if type(source)~="table" or type(source.batteryType)~="string" or source.batteryType=="" then
        return nil,"cell batteryType required"
    end
    local profile=B47ANCEDPower.getBatteryProfile(source.batteryType)
    if not profile then return nil,"unknown cell battery type" end
    local capacity=finite(source.capacity) or finite(profile.capacity)
    if not capacity or capacity<=0 then return nil,"invalid cell capacity" end
    -- Persist the capacity used at installation. Sandbox/profile changes must
    -- not create or erase energy in an already installed set.
    local charge=finite(source.charge)
    if not charge or charge<0 or charge>capacity+0.000001 then return nil,"invalid cell charge" end
    return {
        batteryType=source.batteryType,
        capacity=capacity,
        charge=math.max(0,math.min(capacity,charge)),
        metadata=scalarMetadata(source.metadata),
    }
end

function CellSet.create(cells)
    if type(cells)~="table" or #cells<1 then return nil,"at least one cell required" end
    if #cells>CellSet.MAX_CELLS then return nil,"cell count exceeds safety limit" end
    local result={schemaVersion=CellSet.SCHEMA_VERSION,cells={}}
    for index,source in ipairs(cells) do
        local cell,reason=normalizeCell(source)
        if not cell then return nil,"cell "..index..": "..reason end
        result.cells[index]=cell
    end
    return result
end

function CellSet.validate(set,expectedCount)
    if type(set)~="table" or set.schemaVersion~=CellSet.SCHEMA_VERSION
        or type(set.cells)~="table" then return false,"unsupported cell-set schema" end
    if #set.cells<1 or #set.cells>CellSet.MAX_CELLS then return false,"invalid cell count" end
    if expectedCount and #set.cells~=math.floor(tonumber(expectedCount) or -1) then
        return false,"cell count mismatch"
    end
    for index,source in ipairs(set.cells) do
        local normalized,reason=normalizeCell(source)
        if not normalized then return false,"cell "..index..": "..reason end
    end
    return true
end

function CellSet.summary(set)
    local valid,reason=CellSet.validate(set)
    if not valid then return nil,reason end
    local capacity,charge=0,0
    local types={}
    for _,cell in ipairs(set.cells) do
        capacity=capacity+cell.capacity
        charge=charge+cell.charge
        types[cell.batteryType]=(types[cell.batteryType] or 0)+1
    end
    return {cellCount=#set.cells,totalCapacity=capacity,totalCharge=charge,
        chargeFraction=capacity>0 and charge/capacity or 0,batteryTypes=types}
end

function CellSet.reconcileFraction(set,fraction)
    local summary,reason=CellSet.summary(set)
    if not summary then return false,reason end
    fraction=finite(fraction)
    if not fraction or fraction<0 or fraction>1 then return false,"invalid charge fraction" end
    local target=summary.totalCapacity*fraction
    -- A device may discharge the shared native fraction between observations.
    -- Scale existing cell energy proportionally so imbalance/provenance survives
    -- extraction and total energy remains exact. This API never synthesizes a
    -- charge increase; charging belongs to a future explicit power-source flow.
    if target>summary.totalCharge+0.000001 then return false,"passive reconciliation cannot add energy" end
    if summary.totalCharge<=0 then
        if target>0 then return false,"empty set cannot gain energy" end
        for _,cell in ipairs(set.cells) do cell.charge=0 end
        return true,0
    end
    local scale=target/summary.totalCharge
    local assigned=0
    for index,cell in ipairs(set.cells) do
        if index<#set.cells then
            cell.charge=math.max(0,math.min(cell.capacity,cell.charge*scale))
            assigned=assigned+cell.charge
        else
            cell.charge=math.max(0,math.min(cell.capacity,target-assigned))
        end
    end
    return true,target
end

function CellSet.copyCells(set)
    local valid,reason=CellSet.validate(set)
    if not valid then return nil,reason end
    local result={}
    for index,cell in ipairs(set.cells) do
        result[index]={batteryType=cell.batteryType,capacity=cell.capacity,
            charge=cell.charge,metadata=scalarMetadata(cell.metadata)}
    end
    return result
end

function B47ANCEDPower.getRequiredCellCount(consumer,battery)
    local device=B47ANCEDPower.getConsumerProfile(consumer)
    if not device then return nil,"unregistered consumer" end
    if battery~=nil then
        local cell=B47ANCEDPower.getBatteryProfile(battery)
        if not cell or not B47ANCEDPower.accepts(consumer,battery) then return nil,"incompatible battery" end
        if cell.pack==true then return 1 end
    end
    return math.max(1,math.min(CellSet.MAX_CELLS,
        math.floor(tonumber(device.nominalCellCount) or 1)))
end

function B47ANCEDPower.validateBatterySet(consumer,batteries)
    if type(batteries)~="table" or #batteries<1 then return false,"battery set required" end
    local required,reason=B47ANCEDPower.getRequiredCellCount(consumer,batteries[1])
    if not required then return false,reason end
    if #batteries~=required then return false,"requires "..required.." compatible cell(s)" end
    local physicalSize=nil
    local seen={}
    for index,battery in ipairs(batteries) do
        if seen[battery] then return false,"duplicate physical cell" end
        seen[battery]=true
        if not B47ANCEDPower.accepts(consumer,battery) then return false,"cell "..index.." is incompatible" end
        local profile=B47ANCEDPower.getBatteryProfile(battery)
        if not profile then return false,"cell "..index.." is unregistered" end
        if index==1 then physicalSize=profile.size
        elseif profile.size~=physicalSize then return false,"mixed battery sizes are not supported" end
        if (B47ANCEDPower.getCharge(battery) or 0)<=0 then return false,"cell "..index.." is empty" end
    end
    return true,required
end

function B47ANCEDPower.selectBatterySet(consumer,candidates,preferred)
    if type(candidates)~="table" then return nil,"candidate list required" end
    local groups={}
    for _,battery in ipairs(candidates) do
        if battery and B47ANCEDPower.accepts(consumer,battery) and (B47ANCEDPower.getCharge(battery) or 0)>0 then
            local profile=B47ANCEDPower.getBatteryProfile(battery)
            local key=profile and profile.size or nil
            if key then groups[key]=groups[key] or {}; groups[key][#groups[key]+1]=battery end
        end
    end
    local order={}
    if preferred then
        local profile=B47ANCEDPower.getBatteryProfile(preferred)
        if profile then order[1]=profile.size end
    end
    for size in pairs(groups) do
        local found=false; for _,known in ipairs(order) do if known==size then found=true break end end
        if not found then order[#order+1]=size end
    end
    table.sort(order,function(a,b)
        if preferred then
            local profile=B47ANCEDPower.getBatteryProfile(preferred)
            if profile and a==profile.size then return true end
            if profile and b==profile.size then return false end
        end
        return a<b
    end)
    for _,size in ipairs(order) do
        local group=groups[size]
        table.sort(group,function(a,b)
            local left,right=B47ANCEDPower.getCharge(a) or 0,B47ANCEDPower.getCharge(b) or 0
            if left==right then return tostring(a)<tostring(b) end
            return left>right
        end)
        local required=B47ANCEDPower.getRequiredCellCount(consumer,group[1])
        if required and #group>=required then
            local result={}; for index=1,required do result[index]=group[index] end
            local valid=B47ANCEDPower.validateBatterySet(consumer,result)
            if valid then return result end
        end
    end
    return nil,"insufficient compatible charged cells"
end

B47ANCEDPower.CellSet=CellSet
return CellSet
