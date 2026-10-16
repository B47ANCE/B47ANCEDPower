local B47ANCEDPower=rawget(_G,"B47ANCEDPower") or require "B47ANCEDPower/API"
local Registry=B47ANCEDPower.InfrastructureRegistry or require "B47ANCEDPower/InfrastructureRegistry"
local Provider={}

local function call(object,method,...)
    if object==nil then return false,nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end

local function finite(value)
    value=tonumber(value)
    if value==nil or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end

local function isGenerator(object)
    if type(instanceof)=="function" then
        local ok,result=pcall(instanceof,object,"IsoGenerator")
        if ok and result==true then return true end
    end
    local ok,name=call(object,"getObjectName")
    return ok and name=="IsoGenerator"
end

local function snapshot(object)
    if not isGenerator(object) then return nil,"not an IsoGenerator" end
    local gotSquare,square=call(object,"getSquare")
    local gotIndex,index=call(object,"getObjectIndex")
    index=finite(index)
    if not gotSquare or square==nil or not gotIndex or not index or index<0 or index~=math.floor(index) then
        return nil,"loaded generator identity required"
    end
    local coordinates={}
    for _,key in ipairs({"X","Y","Z"}) do
        local ok,value=call(square,"get"..key);value=finite(value)
        if not ok or not value then return nil,"generator coordinates unavailable" end
        coordinates[string.lower(key)]=value
    end
    local gotFuel,fuel=call(object,"getFuel");fuel=finite(fuel)
    local gotMaximum,maximumFuel=call(object,"getMaxFuel");maximumFuel=finite(maximumFuel)
    local gotCondition,condition=call(object,"getCondition");condition=finite(condition)
    local gotActive,active=call(object,"isActivated")
    local gotConnected,connected=call(object,"isConnected")
    if not gotFuel or not fuel or fuel<0 or not gotMaximum or not maximumFuel or maximumFuel<=0
        or not gotCondition or not condition or condition<0 or not gotActive or type(active)~="boolean"
        or not gotConnected or type(connected)~="boolean" then
        return nil,"generator state unavailable"
    end
    local gotUse,nativeUse=call(object,"getTotalPowerUsing");nativeUse=finite(nativeUse)
    if not gotUse or not nativeUse or nativeUse<0 then nativeUse=nil end
    local gotType,itemType=call(object,"getGeneratorItemType")
    if not gotType or type(itemType)~="string" or itemType=="" then itemType="Base.Generator" end
    local stableKey=table.concat({"generator",coordinates.x,coordinates.y,coordinates.z,index},":")
    return {stableKey=stableKey,networkId="vanilla:"..stableKey,x=coordinates.x,y=coordinates.y,z=coordinates.z,
        fuel=fuel,maximumFuel=maximumFuel,condition=math.min(100,condition),activated=active,
        connected=connected,nativeFuelUsePerHour=nativeUse,itemType=itemType,
        enabled=active and connected and fuel>0 and condition>0}
end

local function sourceDescriptor(object)
    local state,err=snapshot(object);if not state then return nil,err end
    return {stableKey=state.stableKey,x=state.x,y=state.y,z=state.z,enabled=state.enabled,
        powerKnown=false,metadata={itemType=state.itemType,fuel=state.fuel,maximumFuel=state.maximumFuel,
            fuelFraction=math.max(0,math.min(1,state.fuel/state.maximumFuel)),
            conditionFraction=math.max(0,math.min(1,state.condition/100)),activated=state.activated,
            connected=state.connected,nativeFuelUsePerHour=state.nativeFuelUsePerHour}}
end

local function networkDescriptor(object)
    local state,err=snapshot(object);if not state then return nil,err end
    local status="offline"
    if not state.connected then status="disconnected"
    elseif state.enabled then status="online"
    elseif state.condition<=0 then status="failed"
    elseif state.fuel<=0 then status="empty" end
    return {stableKey=state.stableKey,networkId=state.networkId,x=state.x,y=state.y,z=state.z,
        enabled=state.enabled,status=status,metadata={itemType=state.itemType}}
end

local source,sourceCreated=Registry.register("source",{id="B47ANCEDPower.vanillaGeneratorSource",
    owner="B47ANCEDPower",priority=100,revision=1,matches=isGenerator,describe=sourceDescriptor})
local network,networkCreated=Registry.register("network",{id="B47ANCEDPower.vanillaGeneratorNetwork",
    owner="B47ANCEDPower",priority=100,revision=1,matches=isGenerator,describe=networkDescriptor})

Provider.sourceRegistered=source~=nil
Provider.networkRegistered=network~=nil
Provider.sourceCreated=sourceCreated==true
Provider.networkCreated=networkCreated==true
Provider.snapshot=snapshot
B47ANCEDPower.VanillaGeneratorProvider=Provider
return Provider
