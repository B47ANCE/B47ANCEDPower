unpack=unpack or table.unpack
package.loaded["TimedActions/ISBaseTimedAction"]=true
ISBaseTimedAction={derive=function(_,name)local c={Type=name};c.__index=c;return setmetatable(c,{__index=ISBaseTimedAction})end,new=function(class,character)return setmetatable({character=character},class)end,perform=function()end,stop=function()end}
local function list(values)return{size=function()return #values end,get=function(_,i)return values[i+1]end}end
local Access=require "B47ANCEDPower/ItemAccess"
local carried,parts={},{};local inventory={getItems=function()return list(carried)end};local present=true;local bag={contains=function()return present end}
local weapon={getContainer=function()return bag end,getOutermostContainer=function()return inventory end,getAllWeaponParts=function()return list(parts)end}
local partData={};local part={getID=function()return 41 end,getModData=function()return partData end};local replacement={getID=function()return 42 end,getModData=function()return{}end}
local battery={getContainer=function()return bag end,getOutermostContainer=function()return inventory end};parts={part};carried={weapon}
local player={getInventory=function()return inventory end,isDead=function()return false end,isTimedActionInstant=function()return false end}
local installed=false;local serviced=0
local api={ItemAccess=Access,ownsServiceItem=Access.ownsItem,accepts=function()return true end,getCharge=function()return 1 end,
getInstalledBatteryType=function()return installed and"cell"or nil end,getBatteryInstallTime=function()return 10 end,getBatteryRemoveTime=function()return 8 end,getBatteryReplaceTime=function()return 16 end,
installBattery=function(_,consumer)assert(consumer==part);installed=true;serviced=serviced+1;return true end,
extractBattery=function(_,consumer)assert(consumer==part);installed=false;serviced=serviced+1;return true end,
replaceBattery=function(_,consumer)assert(consumer==part);serviced=serviced+1;return true end}
package.loaded["B47ANCEDPower/Definitions"]=api
local Action=require "B47ANCEDPower/B47ANCEDPower_BatteryAction"
local action=Action:new(player,part,"install",battery)
assert(action.consumer==nil,"mounted part should not serialize directly");assert(action.parentWeapon==weapon);assert(action.partId==41);assert(action:resolveConsumer()==part);assert(action:isValid())
local restored=Action:new(action.character,action.consumer,action.mode,action.battery,action.parentWeapon,action.partId)
local synced=0;syncHandWeaponFields=function(_,target)assert(target==weapon);synced=synced+1 end
assert(restored:complete()and installed and serviced==1 and synced==1)
parts={replacement};assert(not restored:isValid() and restored:resolveConsumer()==nil)
parts={part,part};assert(not Access.resolveWeaponPart(player,weapon,41));parts={part}
present=false;assert(not Action:new(player,nil,"remove",nil,weapon,41):isValid());present=true
carried={};assert(not Action:new(player,nil,"remove",nil,weapon,41):isValid())
print("B47ANCEDPower mounted weapon-part ownership and transport checks passed")
