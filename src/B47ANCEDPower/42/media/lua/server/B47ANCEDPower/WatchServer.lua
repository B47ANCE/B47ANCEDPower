local Power=require "B47ANCEDPower/Definitions"
local MODULE,COMMAND="B47ANCEDPower","maintainWatch"
-- Technical workload and transport limits; gameplay drain is a sandbox option.
local MAX_PLAYERS,MAX_ITEMS,MAX_REQUESTS=64,512,32
local requestCounts=setmetatable({},{__mode="k"})
local playerCursor=0
local function call(object,method,...)
    if not object then return false,nil end
    local ok,fn=pcall(function()return object[method]end)
    if not ok or type(fn)~="function" then return false,nil end
    return pcall(fn,object,...)
end
local function finite(value)
    value=tonumber(value)
    return value and value==value and math.abs(value)<math.huge and value or nil
end
local function worldMinute()
    if type(getGameTime)~="function" then return nil end
    local ok,time=pcall(getGameTime)
    local read,hours=call(ok and time or nil,"getWorldAgeHours");hours=finite(hours)
    if not read or not hours or hours<0 then return nil end
    return math.floor(hours*60+0.000001)
end
local function sync(player,item)
    if type(syncItemModData)=="function" then pcall(syncItemModData,player,item) end
end
local function maintainItem(player,item,minute)
    if not Power.isAuthority() then return false,"non-authority" end
    local profile=Power.getConsumerProfile(item)
    if not profile or profile.provider~="B47ANCEDPowerWatch" then return false,"item is not a powered watch" end
    local read,data=call(item,"getModData")
    if not read or type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil
        or data.B47ANCEDPowerEnergyRecovery~=nil then return false,"watch requires inspection" end
    local last=data.B47ANCEDPowerWatchLastMinute
    if last~=nil and (not finite(last) or last<0 or last%1~=0 or last>minute) then
        return false,"watch clock requires inspection"
    end
    if not Power.getInstalledBatteryType(item) and not data.B47ANCEDPowerWatchInitialized then
        local fraction=0.25+(ZombRand and ZombRand(7501)/10000 or math.random()*0.75)
        local initialized,reason=Power.initializeEmbeddedBattery(item,"B47ANCEDPower.BatteryCoin",fraction)
        if not initialized then return false,reason end
        data.B47ANCEDPowerWatchInitialized=true
    end
    local elapsed=last and minute-last or 0
    if Power.getInstalledBatteryType(item) and elapsed>0 then
        local rate=finite(Power.Config.DigitalWatchDrainPerMinute)
        if not rate or rate<0 or rate>.001 then return false,"invalid watch drain configuration" end
        local consumed,reason=Power.consumeEnergy(item,elapsed*rate)
        if not consumed then return false,reason end
    end
    -- Item-owned time survives handoff, reconnect and restart. Requests cannot
    -- choose elapsed time or cause another drain in the same world minute.
    data.B47ANCEDPowerWatchLastMinute=minute
    local state=data.B47ANCEDPower
    if type(state)=="table" and (tonumber(state.chargeFraction) or 0)<=0 then
        local readAlarm,alarm=call(item,"isAlarmSet")
        if readAlarm and alarm then
            call(item,"setAlarmSet",false);call(item,"stopRinging");call(item,"syncAlarmClock")
        end
    end
    sync(player,item)
    return true
end
local function maintain(player,args)
    if not Power.isAuthority() then return false,"non-authority" end
    if type(args)~="table" or not finite(args.itemId) or args.itemId%1~=0 then return false,"invalid request" end
    local deadOK,dead=call(player,"isDead")
    if not deadOK or dead~=false then return false,"actor unavailable" end
    local minute=worldMinute();if not minute then return false,"world clock unavailable" end
    local rate=requestCounts[player]
    if not rate or rate.minute~=minute then rate={minute=minute,count=0};requestCounts[player]=rate end
    if rate.count>=MAX_REQUESTS then return false,"request budget exceeded" end
    rate.count=rate.count+1
    local item,reason=Power.findOwnedItemById(player,args.itemId,MAX_ITEMS)
    if not item then return false,reason end
    return maintainItem(player,item,minute)
end
local function servicePlayer(player,minute)
    local deadOK,dead=call(player,"isDead")
    if not deadOK or dead~=false then return false,"actor unavailable" end
    return Power.visitOwnedInventory(player,function(item)
        local profile=Power.getConsumerProfile(item)
        if profile then
            if profile.provider=="B47ANCEDPowerWatch" then
                local ok,err=pcall(maintainItem,player,item,minute)
                if not ok then print("[B47ANCE'd Power] Watch maintenance failed: "..tostring(err)) end
            else
                local ok,migrated=pcall(Power.migrateInstalledLegacyBattery,item)
                if ok and migrated then
                    local parent=Power.ItemAccess.findWeaponForPart(player,item)
                    Power.ItemAccess.syncConsumer(player,item,parent)
                end
            end
        end
    end,MAX_ITEMS)
end
local function onMinute()
    if not Power.isAuthority() then return false,"non-authority" end
    local minute=worldMinute();if not minute then return false,"world clock unavailable" end
    local server=type(isServer)=="function" and isServer()==true
    local players,count
    if server then
        if type(getOnlinePlayers)~="function" then return false,"online players unavailable" end
        local ok,list=pcall(getOnlinePlayers);if not ok then return false,"online players unavailable" end
        players=list
        local read,size=call(players,"size");count=read and finite(size) or nil
    else
        count=type(getNumActivePlayers)=="function" and getNumActivePlayers() or 4
    end
    if not finite(count) or count<0 then return false,"player count unavailable" end
    count=math.floor(count);if count==0 then return true end
    for offset=0,math.min(count,MAX_PLAYERS)-1 do
        local index=(playerCursor+offset)%count
        local player
        if server then local ok,value=call(players,"get",index);if ok then player=value end
        elseif type(getSpecificPlayer)=="function" then player=getSpecificPlayer(index) end
        if player then servicePlayer(player,minute) end
    end
    playerCursor=(playerCursor+math.min(count,MAX_PLAYERS))%count
    return true
end
local function onCommand(module,command,player,args)
    if module~=MODULE or command~=COMMAND then return end
    local ok,err=pcall(maintain,player,args)
    if not ok then print("[B47ANCE'd Power] Watch maintenance failed: "..tostring(err)) end
end
if Events and Events.EveryOneMinute then Events.EveryOneMinute.Add(onMinute) end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(onCommand) end
Power.handleWatchMaintenance=maintain
Power.maintainServerWatches=onMinute
return Power
