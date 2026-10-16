local minuteCallback,commandCallback
Events={
    EveryOneMinute={Add=function(callback) minuteCallback=callback end},
    OnClientCommand={Add=function(callback) commandCallback=callback end},
}
local consumed,initialized,synced=0,0,0
local item={data={},id=42,alarm=false}
function item:getID() return self.id end
function item:getModData() return self.data end
function item:isAlarmSet() return self.alarm end
function item:setAlarmSet(value) self.alarm=value end
local player={}
local api={
    Config={DigitalWatchDrainPerMinute=0.25},
    findOwnedItemById=function(got,id,limit)
        assert(got==player and limit==512)
        return id==42 and item or nil,id==42 and nil or "not found"
    end,
    getConsumerProfile=function(got) return got==item and {provider="B47ANCEDPowerWatch"} or nil end,
    getInstalledBatteryType=function(got) return got.data.B47ANCEDPower and got.data.B47ANCEDPower.batteryType end,
    initializeEmbeddedBattery=function(got,battery,fraction)
        assert(got==item and battery=="B47ANCEDPower.BatteryCoin" and fraction>=.25 and fraction<=1)
        initialized=initialized+1; got.data.B47ANCEDPower={batteryType=battery,chargeFraction=fraction}; return true
    end,
    consumeEnergy=function(got,amount) assert(got==item and amount==.25); consumed=consumed+1; return true end,
}
local realRequire=require
require=function(name) if name=="B47ANCEDPower/Definitions" then return api end return realRequire(name) end
syncItemModData=function(gotPlayer,gotItem) assert(gotPlayer==player and gotItem==item); synced=synced+1 end

local server=dofile(assert(arg[1]))
assert(type(commandCallback)=="function" and type(minuteCallback)=="function")
commandCallback("other","maintainWatch",player,{itemId=42})
assert(consumed==0)
commandCallback("B47ANCEDPower","maintainWatch",player,{itemId=42})
assert(initialized==1 and consumed==1 and synced==1 and item.data.B47ANCEDPowerWatchInitialized)
commandCallback("B47ANCEDPower","maintainWatch",player,{itemId=42})
assert(consumed==1,"duplicate requests in one server minute must be ignored")
minuteCallback()
commandCallback("B47ANCEDPower","maintainWatch",player,{itemId=42})
assert(initialized==1 and consumed==2 and synced==2)
assert(not server.handleWatchMaintenance(player,{itemId=99}))
item.data.B47ANCEDPowerServiceRecovery={}
minuteCallback()
assert(not server.handleWatchMaintenance(player,{itemId=42}))
assert(consumed==2,"quarantined watches must not drain")

print("B47ANCEDPower server-authoritative watch maintenance checks passed")
