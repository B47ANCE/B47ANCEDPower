local B47ANCEDPower=require "B47ANCEDPower/Definitions"

local MODULE="B47ANCEDPower"
local COMMAND="maintainWatch"
local epoch=0
local serviced=setmetatable({},{__mode="k"})

local function sync(player,item)
    if type(syncItemModData)=="function" then pcall(syncItemModData,player,item) end
end

local function maintain(player,args)
    if type(args)~="table" or type(args.itemId)~="number" then return false,"invalid request" end
    local item,reason=B47ANCEDPower.findOwnedItemById(player,args.itemId,512)
    if not item then return false,reason end
    local profile=B47ANCEDPower.getConsumerProfile(item)
    if not profile or profile.provider~="B47ANCEDPowerWatch" then return false,"item is not a powered watch" end
    local claims=serviced[player]
    if not claims then claims={}; serviced[player]=claims end
    if claims[args.itemId]==epoch then return false,"watch already serviced this minute" end
    claims[args.itemId]=epoch

    local data=item:getModData()
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil then return false,"watch requires inspection" end
    if not B47ANCEDPower.getInstalledBatteryType(item) and not data.B47ANCEDPowerWatchInitialized then
        local fraction=0.25+(ZombRand and ZombRand(7501)/10000 or math.random()*0.75)
        local initialized=B47ANCEDPower.initializeEmbeddedBattery(item,"B47ANCEDPower.BatteryCoin",fraction)
        if initialized then data.B47ANCEDPowerWatchInitialized=true end
    end
    if B47ANCEDPower.getInstalledBatteryType(item) then
        B47ANCEDPower.consumeEnergy(item,math.max(0,tonumber(B47ANCEDPower.Config.DigitalWatchDrainPerMinute) or 0.0000002))
    end
    local state=data.B47ANCEDPower
    if type(state)=="table" and (tonumber(state.chargeFraction) or 0)<=0
        and item.isAlarmSet and item:isAlarmSet() then
        item:setAlarmSet(false)
        if item.stopRinging then item:stopRinging() end
        if item.syncAlarmClock then item:syncAlarmClock() end
    end
    sync(player,item)
    return true
end

local function onCommand(module,command,player,args)
    if module~=MODULE or command~=COMMAND then return end
    local ok,err=pcall(maintain,player,args)
    if not ok then print("[B47ANCE'd Power] Watch maintenance failed safely: "..tostring(err)) end
end

if Events and Events.EveryOneMinute then Events.EveryOneMinute.Add(function() epoch=epoch+1 end) end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(onCommand) end

B47ANCEDPower.handleWatchMaintenance=maintain
return B47ANCEDPower
