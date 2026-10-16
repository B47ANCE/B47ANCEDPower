local B47ANCEDPower=rawget(_G,"B47ANCEDPower") or {}

local Registry={
    API_VERSION="1.0.0",
    MAX_PROVIDERS_PER_KIND=64,
    MAX_QUERY_RESULTS=256,
    MAX_RESULTS_PER_PROVIDER=64,
}

local kinds={source=true,storage=true,load=true,network=true}
local providers={source={},storage={},load={},network={}}
local counts={source=0,storage=0,load=0,network=0}

local function finite(value)
    value=tonumber(value)
    if value==nil or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end

local function validId(value,maximum)
    return type(value)=="string" and value~="" and #value<=(maximum or 96)
        and value:match("^[%w_.:%-]+$")~=nil
end

local function copy(value,depth,seen)
    if type(value)~="table" then return value end
    depth=(depth or 0)+1
    if depth>4 then return nil end
    seen=seen or {}
    if seen[value] then return nil end
    seen[value]=true
    local result={}
    local entries=0
    for key,entry in pairs(value) do
        entries=entries+1
        if entries>64 then break end
        if type(key)=="string" or type(key)=="number" then
            local entryType=type(entry)
            if entryType=="string" or entryType=="number" or entryType=="boolean" then
                result[key]=entry
            elseif entryType=="table" then
                result[key]=copy(entry,depth,seen)
            end
        end
    end
    seen[value]=nil
    return result
end

local function ordered(kind)
    local result={}
    for _,provider in pairs(providers[kind]) do result[#result+1]=provider end
    table.sort(result,function(a,b)
        if a.priority==b.priority then return a.id<b.id end
        return a.priority>b.priority
    end)
    return result
end

local function metadata(provider)
    return {id=provider.id,owner=provider.owner,kind=provider.kind,priority=provider.priority,
        revision=provider.revision,apiVersion=Registry.API_VERSION,
        supportsRegionQuery=type(provider.queryRegion)=="function"}
end

local function normalizeCommon(kind,provider,descriptor)
    if type(descriptor)~="table" then return nil,"provider descriptor required" end
    if not validId(descriptor.stableKey,192) then return nil,"stableKey is required" end
    local result={kind=kind,providerId=provider.id,owner=provider.owner,
        stableKey=descriptor.stableKey,enabled=descriptor.enabled~=false}
    if descriptor.regionKey~=nil then
        if not validId(descriptor.regionKey,192) then return nil,"invalid regionKey" end
        result.regionKey=descriptor.regionKey
    end
    for _,key in ipairs({"x","y","z"}) do
        if descriptor[key]~=nil then
            local value=finite(descriptor[key]); if not value then return nil,"invalid "..key end
            result[key]=value
        end
    end
    result.metadata=copy(descriptor.metadata or {}) or {}
    return result
end

local function nonNegative(descriptor,key,required)
    local value=finite(descriptor[key])
    if value==nil then
        if required then return nil,key.." is required" end
        return nil
    end
    if value<0 then return nil,key.." must be non-negative" end
    return value
end

local function normalize(kind,provider,descriptor)
    local result,err=normalizeCommon(kind,provider,descriptor); if not result then return nil,err end
    if kind=="source" then
        result.powerKnown=descriptor.powerKnown~=false
        result.availablePowerWatts,err=nonNegative(descriptor,"availablePowerWatts",result.powerKnown)
        if result.powerKnown and result.availablePowerWatts==nil then return nil,err end
        if not result.powerKnown and descriptor.availablePowerWatts~=nil then
            return nil,"unknown power cannot declare available watts"
        end
        result.maximumPowerWatts,err=nonNegative(descriptor,"maximumPowerWatts",false)
        if err then return nil,err end
        if result.maximumPowerWatts and result.availablePowerWatts
            and result.availablePowerWatts>result.maximumPowerWatts then
            return nil,"available power exceeds maximum"
        end
    elseif kind=="storage" then
        result.storedEnergyWh,err=nonNegative(descriptor,"storedEnergyWh",true)
        if not result.storedEnergyWh then return nil,err end
        result.capacityWh,err=nonNegative(descriptor,"capacityWh",true)
        if not result.capacityWh then return nil,err end
        if result.storedEnergyWh>result.capacityWh then return nil,"stored energy exceeds capacity" end
        for _,key in ipairs({"maximumChargeWatts","maximumDischargeWatts"}) do
            result[key],err=nonNegative(descriptor,key,false); if err then return nil,err end
        end
        if descriptor.health~=nil then
            result.health=finite(descriptor.health)
            if not result.health or result.health<0 or result.health>1 then return nil,"health must be between zero and one" end
        end
    elseif kind=="load" then
        result.demandWatts,err=nonNegative(descriptor,"demandWatts",true)
        if not result.demandWatts then return nil,err end
        result.priority=finite(descriptor.priority) or 0
    else
        if not validId(descriptor.networkId,192) then return nil,"networkId is required" end
        result.networkId=descriptor.networkId
        result.nominalVoltage=nonNegative(descriptor,"nominalVoltage",false)
        if descriptor.nominalVoltage~=nil and result.nominalVoltage==nil then return nil,"invalid nominalVoltage" end
        result.status=tostring(descriptor.status or "unknown")
        if #result.status>48 or result.status:find("[%c]") then return nil,"invalid network status" end
    end
    return result
end

local function safeCall(callback,...)
    local ok,a,b=pcall(callback,...)
    if not ok then return nil,"provider callback failed" end
    return a,b
end

function Registry.register(kind,definition)
    assert(kinds[kind],"invalid infrastructure provider kind")
    assert(type(definition)=="table","provider definition required")
    assert(validId(definition.id,96),"provider id required")
    assert(validId(definition.owner,96),"provider owner required")
    assert(type(definition.matches)=="function" and type(definition.describe)=="function",
        "matches and describe callbacks required")
    local existing=providers[kind][definition.id]
    if existing then
        if existing.owner==definition.owner and existing.matches==definition.matches
            and existing.describe==definition.describe and existing.queryRegion==definition.queryRegion then
            return existing,false
        end
        return nil,"provider id already registered"
    end
    if counts[kind]>=Registry.MAX_PROVIDERS_PER_KIND then return nil,"provider limit reached" end
    local provider={id=definition.id,owner=definition.owner,kind=kind,
        priority=finite(definition.priority) or 0,revision=math.max(1,math.floor(finite(definition.revision) or 1)),
        matches=definition.matches,describe=definition.describe,queryRegion=definition.queryRegion}
    providers[kind][provider.id]=provider;counts[kind]=counts[kind]+1
    return provider,true
end

function Registry.get(kind,id)
    if not kinds[kind] then return nil,"invalid provider kind" end
    local provider=providers[kind][id]
    return provider and metadata(provider) or nil,provider and nil or "unknown provider"
end

function Registry.list(kind)
    if not kinds[kind] then return nil,"invalid provider kind" end
    local result={}
    for _,provider in ipairs(ordered(kind)) do result[#result+1]=metadata(provider) end
    return result
end

function Registry.describe(kind,object,context)
    if not kinds[kind] then return nil,"invalid provider kind" end
    if object==nil then return nil,"object required" end
    for _,provider in ipairs(ordered(kind)) do
        local matched,matchErr=safeCall(provider.matches,object,context)
        if not matchErr and matched==true then
            local descriptor,describeErr=safeCall(provider.describe,object,context)
            if not descriptor then return nil,describeErr or "provider rejected object" end
            return normalize(kind,provider,descriptor)
        end
    end
    return nil,"no infrastructure provider"
end

function Registry.queryRegion(kind,region,limit)
    if not kinds[kind] then return nil,"invalid provider kind" end
    if type(region)~="table" or not validId(region.key,192) then return nil,"bounded region key required" end
    limit=math.max(1,math.min(Registry.MAX_QUERY_RESULTS,math.floor(finite(limit) or Registry.MAX_QUERY_RESULTS)))
    local results,failures,truncated={},0,false
    for _,provider in ipairs(ordered(kind)) do
        if #results>=limit then truncated=true break end
        if type(provider.queryRegion)=="function" then
            local providerLimit=math.min(Registry.MAX_RESULTS_PER_PROVIDER,limit-#results)
            local entries,queryErr=safeCall(provider.queryRegion,copy(region) or {},providerLimit)
            if queryErr or type(entries)~="table" then failures=failures+1
            else
                for index=1,providerLimit do
                    local entry=entries[index];if entry==nil then break end
                    local normalized=normalize(kind,provider,entry)
                    if normalized then results[#results+1]=normalized else failures=failures+1 end
                end
                if entries[providerLimit+1]~=nil then truncated=true end
            end
        end
    end
    return results,{kind=kind,providerCount=counts[kind],failures=failures,truncated=truncated,limit=limit}
end

Registry.Kinds=kinds
B47ANCEDPower.InfrastructureRegistry=Registry
B47ANCEDPower.registerInfrastructureProvider=function(kind,definition) return Registry.register(kind,definition) end
B47ANCEDPower.getInfrastructureProvider=function(kind,id) return Registry.get(kind,id) end
B47ANCEDPower.listInfrastructureProviders=function(kind) return Registry.list(kind) end
B47ANCEDPower.describeInfrastructure=function(kind,object,context) return Registry.describe(kind,object,context) end
B47ANCEDPower.queryInfrastructureRegion=function(kind,region,limit) return Registry.queryRegion(kind,region,limit) end
_G.B47ANCEDPower=B47ANCEDPower
return Registry
