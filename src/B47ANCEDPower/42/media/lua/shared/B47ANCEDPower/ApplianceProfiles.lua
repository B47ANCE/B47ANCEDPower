local B47ANCEDPower=rawget(_G,"B47ANCEDPower")or{}
local Registry=B47ANCEDPower.InfrastructureRegistry or require "B47ANCEDPower/InfrastructureRegistry"
local Profiles={MAX_PROFILES=64,MAX_IDENTITIES=64,MAX_OBJECTS=256}
local profiles={};local count=0

local function validId(value,maximum)return type(value)=="string"and value~=""and#value<=maximum and value:match("^[%w_.:%-]+$")~=nil end
local function finite(value)value=tonumber(value);return value and value==value and value~=math.huge and value~=-math.huge and value or nil end
local function call(object,method,...)
    local ok,fn=pcall(function()return object and object[method]end);if not ok or type(fn)~="function"then return nil end
    local called,result=pcall(fn,object,...);return called and result or nil
end
local function fullType(object)return call(object,"getFullType")or call(call(object,"getItem"),"getFullType")end
local function spriteName(object)return call(call(object,"getSprite"),"getName")end
local function identitySet(values)
    assert(type(values)=="table"and#values>0 and#values<=Profiles.MAX_IDENTITIES,"one to 64 exact identities required")
    local result={};for _,value in ipairs(values)do assert(validId(value,160),"invalid exact appliance identity");result[value]=true end;return result
end

function Profiles.register(definition)
    assert(type(definition)=="table"and validId(definition.id,64),"bounded appliance profile id required")
    assert(validId(definition.owner,96),"bounded appliance owner required")
    local demand=finite(definition.demandWatts);assert(demand and demand>=0 and demand<=1000000,"absolute demandWatts required")
    assert(type(definition.logicalIdentity)=="function","logical appliance identity callback required")
    assert(not profiles[definition.id],"duplicate appliance profile: "..definition.id)
    count=count+1;assert(count<=Profiles.MAX_PROFILES,"appliance profile limit reached")
    local itemTypes=definition.itemTypes and identitySet(definition.itemTypes)or{}
    local spriteNames=definition.spriteNames and identitySet(definition.spriteNames)or{}
    assert(next(itemTypes)or next(spriteNames),"exact item or sprite identities required")
    local profile={id=definition.id,owner=definition.owner,demandWatts=demand,itemTypes=itemTypes,spriteNames=spriteNames,
        logicalIdentity=definition.logicalIdentity,isActive=definition.isActive,priority=finite(definition.priority)or 0}
    local provider,created=Registry.register("load",{id=profile.id,owner=profile.owner,priority=profile.priority,
        matches=function(object)return itemTypes[tostring(fullType(object)or"")]==true or spriteNames[tostring(spriteName(object)or"")]==true end,
        describe=function(object,context)
            local ok,key=pcall(profile.logicalIdentity,object,context or{});if not ok or not validId(key,192)then return nil end
            local active=true;if type(profile.isActive)=="function"then local activeOk,value=pcall(profile.isActive,object,context or{});if not activeOk then return nil end;active=value==true end
            return{stableKey=key,demandWatts=active and demand or 0,metadata={profileId=profile.id,absoluteDemand=true}}
        end})
    if not provider then error(tostring(created))end
    profiles[profile.id]=profile
    return{id=profile.id,owner=profile.owner,demandWatts=profile.demandWatts}
end
function Profiles.describeObjects(objects,context,limit)
    if type(objects)~="table"then return nil,"bounded object list required"end
    limit=math.floor(finite(limit)or Profiles.MAX_OBJECTS);if limit<1 or limit>Profiles.MAX_OBJECTS then return nil,"limit must be 1 to 256"end
    local result,byKey,conflicted,failures,truncated={}, {},{},0,#objects>limit
    for index=1,math.min(#objects,limit)do
        local descriptor,err=Registry.describe("load",objects[index],context)
        if descriptor then
            local existing=byKey[descriptor.stableKey]
            if existing and(existing.providerId~=descriptor.providerId or existing.demandWatts~=descriptor.demandWatts)then
                if not conflicted[descriptor.stableKey]then failures=failures+1 end
                conflicted[descriptor.stableKey]=true
            elseif not existing then byKey[descriptor.stableKey]=descriptor end
        elseif err~="no infrastructure provider"then failures=failures+1 end
    end
    for key,descriptor in pairs(byKey)do if not conflicted[key]then result[#result+1]=descriptor end end
    table.sort(result,function(a,b)return a.stableKey<b.stableKey end)
    return result,{inspected=math.min(#objects,limit),logicalLoads=#result,failures=failures,truncated=truncated}
end

B47ANCEDPower.ApplianceProfiles=Profiles
_G.B47ANCEDPower=B47ANCEDPower
return Profiles
