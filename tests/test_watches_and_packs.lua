local apiPath,definitionsPath,watchesPath=arg[1],arg[2],arg[3]
dofile(apiPath)
local realRequire=require
require=function(name)
    if name=="B47ANCEDPower/API" then return B47ANCEDPower end
    if name=="B47ANCEDPower/Definitions" then return B47ANCEDPower end
    if name=="B47ANCEDPower/B47ANCEDPower_BatteryAction" then
        B47ANCEDPower.queueExtractBattery=function() end
        B47ANCEDPower.queueReplaceBattery=function() end
        B47ANCEDPower.queueInstallBattery=function() end
        return B47ANCEDPower
    end
    return realRequire(name)
end
dofile(definitionsPath)

assert(B47ANCEDPower.getBatteryProfile("B47ANCEDPower.BatteryCoin").size=="COIN")
assert(B47ANCEDPower.getBatteryProfile("B47ANCEDPower.BatteryPackSmall").size=="AA_PACK")
assert(B47ANCEDPower.getBatteryProfile("B47ANCEDPower.BatteryPackLarge").size=="D_PACK")

local minuteTick,contextCallback
Events={EveryOneMinute={Add=function(callback) minuteTick=callback end},OnFillInventoryObjectContextMenu={Add=function(callback) contextCallback=callback end}}
getSpecificPlayer=function() return nil end
ZombRand=function() return 0 end
getText=function(key,...)
    local values={ContextMenu_B47ANCEDPower_RemoveCoinCell="Localized Remove Cell",
        ContextMenu_B47ANCEDPower_ReplaceCoinCell="Localized Replace Cell",
        ContextMenu_B47ANCEDPower_InsertCoinCell="Localized Insert Cell",
        ContextMenu_B47ANCEDPower_CoinCellCharge="Localized Cell (%1%)"}
    local value=values[key] or key
    local args={...};return (value:gsub("%%(%d+)",function(index)return tostring(args[tonumber(index)]or"%"..index)end))
end
dofile(watchesPath)

local data={}; local alarm=true; local stopped=false; local synced=false
local watch={
    getFullType=function() return "Base.WristWatch_Left_DigitalBlack" end,
    getDisplayName=function() return "Digital Watch" end,
    getModData=function() return data end,
    isAlarmSet=function() return alarm end,
    setAlarmSet=function(_,value) alarm=value end,
    stopRinging=function() stopped=true end,
    syncAlarmClock=function() synced=true end,
}
B47ANCEDPower.ensurePoweredWatch(watch)
assert(B47ANCEDPower.getInstalledBatteryType(watch)=="B47ANCEDPower.BatteryCoin",
    "new digital watches must initialize with an embedded coin cell")
assert(data.B47ANCEDPower.chargeFraction>0 and data.B47ANCEDPower.chargeFraction<1,
    "spawned digital watches need bounded partial charge")
local initializedCharge=data.B47ANCEDPower.chargeFraction
B47ANCEDPower.ensurePoweredWatch(watch)
assert(data.B47ANCEDPower.chargeFraction==initializedCharge,
    "display refresh must not consume watch energy")
-- Alarm draining and minute scheduling are tested against the real server module.
local classic={getFullType=function() return "Base.WristWatch_Left_ClassicBlack" end,getModData=function() return {} end}
B47ANCEDPower.maintainPoweredWatch(classic)
assert(B47ANCEDPower.getInstalledBatteryType(classic)==nil,"classic watches must remain mechanical")
data={B47ANCEDPower="invalid saved state"}
B47ANCEDPower.ensurePoweredWatch(watch)
assert(data.B47ANCEDPower=="invalid saved state" and not data.B47ANCEDPowerWatchInitialized)
data={}
local refresh=B47ANCEDPower.refreshConsumer
B47ANCEDPower.refreshConsumer=function() error("simulated initialization failure") end
B47ANCEDPower.ensurePoweredWatch(watch)
assert(not data.B47ANCEDPowerWatchInitialized and data.B47ANCEDPower.batteryType==nil)
assert(data.B47ANCEDPowerServiceRecovery.status=="inspection_required")
assert(not B47ANCEDPower.consumeEnergy(watch,0.1))
B47ANCEDPower.refreshConsumer=refresh
B47ANCEDPower.ensurePoweredWatch(watch)
assert(not data.B47ANCEDPowerWatchInitialized,"quarantine must not be bypassed by watch maintenance")
data={}
local bad={getFullType=watch.getFullType,getModData=function() error("broken mod item") end}
local contents={bad,watch}
local list={size=function() return #contents end,get=function(_,index) return contents[index+1] end}
getSpecificPlayer=function(index)
    if index==0 then return {getInventory=function() return {getItems=function() return list end} end} end
end
assert(minuteTick==nil,"client module must not own periodic watch drain")

-- Remote clients request canonical maintenance and do not initialize or drain
-- the item locally.
local sent
isClient=function() return true end
isServer=function() return false end
sendClientCommand=function(player,module,command,args) sent={player,module,command,args} end
data={}
watch.getID=function() return 77 end
local remotePlayer={}
B47ANCEDPower.maintainPoweredWatch(watch,remotePlayer)
assert(data.B47ANCEDPower==nil and data.B47ANCEDPowerWatchInitialized==nil)
assert(sent and sent[1]==remotePlayer and sent[2]=="B47ANCEDPower" and sent[3]=="maintainWatch" and sent[4].itemId==77)
assert(not B47ANCEDPower.consumeEnergy(watch,0.1),"remote clients cannot mutate canonical charge")

-- The watch-owned service menu must use translation keys without changing the
-- authoritative battery transactions it invokes.
isClient=function() return false end
isServer=function() return false end
data={}
B47ANCEDPower.ensurePoweredWatch(watch) -- explicit authority fixture setup, never menu-owned initialization
local cell={getFullType=function()return"B47ANCEDPower.BatteryCoin"end,getUsedDelta=function()return.5 end}
contents={watch,cell}
local menuPlayer={getInventory=function()return{getItems=function()return list end}end}
getSpecificPlayer=function()return menuPlayer end
local menus={}
ISContextMenu={getNew=function()local menu={options={}};function menu:addOption(label,...)local option={label=label,args={...}};self.options[#self.options+1]=option;return option end;function menu:addSubMenu(option,sub)option.sub=sub end;menus[#menus+1]=menu;return menu end}
local context={options={}}
function context:getOptionFromName()return nil end
function context:addOption(label,...)local option={label=label,args={...}};self.options[#self.options+1]=option;return option end
function context:addSubMenu(option,sub)option.sub=sub end
assert(contextCallback and pcall(contextCallback,0,context,{watch}))
local deviceMenu=context.options[1]and context.options[1].sub
assert(deviceMenu and deviceMenu.options[1].label=="Localized Remove Cell")
assert(deviceMenu.options[2].label=="Localized Replace Cell")
assert(deviceMenu.options[2].sub.options[1].label=="Localized Cell (50%)")
print("B47ANCEDPower watch and battery-pack checks passed")
