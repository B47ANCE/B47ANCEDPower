unpack=unpack or table.unpack
package.loaded["TimedActions/ISBaseTimedAction"]=true
local cleaned=0
ISBaseTimedAction={derive=function(_,name)
    local class={Type=name}; class.__index=class; return setmetatable(class,{__index=ISBaseTimedAction})
end,new=function(class,character) return setmetatable({character=character},class) end,
perform=function() cleaned=cleaned+1 end,stop=function() end}
local inventory={}
local dead=false
local character={getInventory=function() return inventory end,isDead=function() return dead end}
local owner=inventory
local present=true
local bag={contains=function() return present end}
local function item() return {getOutermostContainer=function() return owner end,getContainer=function() return bag end} end
local consumer,battery=item(),item()
local consumerData={}
consumer.getModData=function() return consumerData end
local installed=false
local mutations=0
local api={accepts=function() return true end,getCharge=function() return 1 end,
    ownsServiceItem=function(character,item)
        return item:getOutermostContainer()==character:getInventory() and item:getContainer():contains(item)
    end,
    getInstalledBatteryType=function() return installed and "cell" or nil end,
    getBatteryRemoveTime=function() return 10 end,getBatteryReplaceTime=function() return 18 end,
    getBatteryInstallTime=function() return 10 end,
    installBattery=function() mutations=mutations+1; installed=true; return true end,
    replaceBattery=function() mutations=mutations+1; return true end,
    extractBattery=function() mutations=mutations+1; installed=false; return true end}
package.loaded["B47ANCEDPower/Definitions"]=api
local Action=require "B47ANCEDPower/B47ANCEDPower_BatteryAction"
assert(_G[Action.Type]==Action,"network Type must resolve globally")
assert(not package.loaded["TimedActions/ISTimedActionQueue"],"server load must not require client queue")
local action=Action:new(character,consumer,"install",battery)
local synced={}
syncItemModData=function(_,item) assert(item==consumer); synced.metadata=true end
syncItemFields=function(_,item) assert(item==consumer); synced.fields=true end
syncItemActivated=function(_,item) assert(item==consumer); synced.active=true end
action:perform(); assert(mutations==0 and cleaned==1)
isClient=function() return true end
assert(not action:complete() and mutations==0)
isClient=function() return false end
owner={}; assert(not action:complete()); owner=inventory
present=false; assert(not action:complete()); present=true
dead=true; assert(not action:complete()); dead=false
consumerData.B47ANCEDPowerServiceRecovery={status="inspection_required"}
assert(not action:complete() and mutations==0)
consumerData.B47ANCEDPowerServiceRecovery=nil
assert(action:complete() and mutations==1)
assert(synced.metadata and synced.fields and synced.active)
assert(not action:complete() and mutations==1)
local replace=Action:new(character,consumer,"replace",battery)
assert(replace:complete() and mutations==2 and installed)
assert(Action:new(character,consumer,"remove",nil):complete() and not installed and mutations==3)
assert(not Action:new(character,consumer,"invalid",battery):complete())
for _,args in ipairs({{nil,consumer,"install",battery},{character,nil,"install",battery},{character,consumer,"install",nil}}) do
    assert(not Action:new(args[1],args[2],args[3],args[4]):complete())
end
local throwing=Action:new(character,consumer,"install",battery)
api.installBattery=function() mutations=mutations+1; error("uncertain write") end
assert(not throwing:complete())
local after=mutations
assert(not throwing:complete() and mutations==after)
print("B47ANCEDPower authoritative battery action lifecycle and ownership checks passed")
