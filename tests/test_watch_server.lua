local Power=require "B47ANCEDPower/Definitions"
local clock=600
getGameTime=function()return{getWorldAgeHours=function()return clock/60 end}end
isClient=function()return false end;isServer=function()return true end
ZombRand=function()return 0 end
local tick,command
Events={EveryOneMinute={Add=function(fn)tick=fn end},OnClientCommand={Add=function(fn)command=fn end}}
local root,bag={},{}
local player={getInventory=function()return root end,isDead=function()return false end}
local watch={data={},alarm=true}
function watch:getFullType()return "Base.WristWatch_Right_DigitalBlack" end
function watch:getModData()return self.data end
function watch:getID()return 42 end
function watch:getCurrentUsesFloat()return 1 end -- inherited generic native field is NOT its charge surface
function watch:getOutermostContainer()return root end
function watch:getContainer()return bag end
function watch:isAlarmSet()return self.alarm end
function watch:setAlarmSet(v)self.alarm=v end
function watch:stopRinging()self.stopped=true end
function watch:syncAlarmClock()self.alarmSynced=true end
local broken={getFullType=watch.getFullType,getModData=function()error("broken item")end,getOutermostContainer=function()return root end}
local containerItem={getInventory=function()return bag end,getOutermostContainer=function()return root end}
local rootItems={broken,containerItem}
root.getItems=function()return{size=function()return #rootItems end,get=function(_,i)return rootItems[i+1]end}end
bag.getItems=function()return{size=function()return 1 end,get=function()return watch end}end
getOnlinePlayers=function()return{size=function()return 1 end,get=function()return player end}end
local syncs=0;syncItemModData=function(p,item)assert(p==player and item==watch);syncs=syncs+1 end
Power.Config.DigitalWatchDrainPerMinute=.001
local server=dofile(arg[1])
assert(type(tick)=="function" and type(command)=="function")
tick() -- discovers nested watch without ANY client request; isolates earlier broken watch
assert(watch.data.B47ANCEDPowerWatchInitialized and watch.data.B47ANCEDPower.chargeFraction==.25)
assert(Power.findOwnedItemById(player,42,512)==watch,"real lookup must traverse nested containers")
clock=clock+2;tick()
assert(math.abs(watch.data.B47ANCEDPower.chargeFraction-(.0625-.002)/.25)<.0000001)
local fraction=watch.data.B47ANCEDPower.chargeFraction
assert(server.handleWatchMaintenance(player,{itemId=42}))
assert(watch.data.B47ANCEDPower.chargeFraction==fraction,"duplicate requests cannot accelerate drain")
assert(not server.handleWatchMaintenance(player,{itemId=99}))
assert(not server.handleWatchMaintenance(player,{itemId=0/0}))
watch.data.B47ANCEDPowerEnergyRecovery={};clock=clock+1;tick()
assert(watch.data.B47ANCEDPower.chargeFraction==fraction,"energy reservation blocks background drain")
watch.data.B47ANCEDPowerEnergyRecovery=nil
package.loaded["B47ANCEDPower/WatchServer"]=nil
require "B47ANCEDPower/WatchServer" -- persisted item clock survives module restart
clock=clock+1;tick()
assert(watch.data.B47ANCEDPower.chargeFraction<fraction)
watch.data.B47ANCEDPower.chargeFraction=0;clock=clock+1;tick()
assert(watch.alarm==false and watch.stopped and watch.alarmSynced,"empty watch alarm is disabled and synchronized")
watch.data.B47ANCEDPowerServiceRecovery={};fraction=watch.data.B47ANCEDPower.chargeFraction;clock=clock+1;tick()
assert(watch.data.B47ANCEDPower.chargeFraction==fraction)
assert(syncs>0)
print("B47ANCEDPower real server watch scheduling, nested lookup, restart and alarm checks passed")
