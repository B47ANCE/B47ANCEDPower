require "B47ANCEDPower/B47ANCEDPower_BatteryAction"
local B47ANCEDPower=require "B47ANCEDPower/Definitions"

local function tr(key,fallback,...)
    local args={...}
    local function substitute(value)
        return (tostring(value):gsub("%%(%d+)",function(index)
            local replacement=args[tonumber(index)]
            return replacement==nil and "%"..index or tostring(replacement)
        end))
    end
    local get=rawget(_G,"getText")
    if type(get)~="function" then return substitute(fallback) end
    local expand=table.unpack or unpack
    local ok,value=pcall(get,key,expand(args))
    if ok and type(value)=="string" and value~="" and value~=key then return value end
    return substitute(fallback)
end

local function fullType(item)
    local ok,value=pcall(function() return item:getFullType() end)
    return ok and value or nil
end

local function isPoweredWatch(item)
    local profile=B47ANCEDPower.getConsumerProfile(item)
    return profile and profile.provider=="B47ANCEDPowerWatch"
end

local function eachInventoryItem(player,callback)
    local ok,items=pcall(function() return player:getInventory():getItems() end)
    if not ok or not items then return end
    for index=0,items:size()-1 do pcall(function() callback(items:get(index)) end) end
end

local function ensureWatch(item)
    if not isPoweredWatch(item) then return end
    local data=item:getModData()
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil then return false end
    if not B47ANCEDPower.getInstalledBatteryType(item) then
        if not data.B47ANCEDPowerWatchInitialized then
            local ok=B47ANCEDPower.initializeEmbeddedBattery(item,"B47ANCEDPower.BatteryCoin",0.25+(ZombRand and ZombRand(7501)/10000 or math.random()*0.75))
            if ok then data.B47ANCEDPowerWatchInitialized=true end
        end
    end
end

local function remoteClient()
    return type(isClient)=="function" and isClient()==true
        and not (type(isServer)=="function" and isServer()==true)
end

local function requestMaintenance(player,item)
    if not player or type(sendClientCommand)~="function" then return false end
    local ok,id=pcall(function() return item:getID() end)
    if not ok or type(id)~="number" then return false end
    return pcall(sendClientCommand,player,"B47ANCEDPower","maintainWatch",{itemId=id})
end

local function maintainWatch(item,player)
    if remoteClient() then
        if isPoweredWatch(item) then requestMaintenance(player,item) end
        return
    end
    ensureWatch(item)
    if not isPoweredWatch(item) then return end
    local data=item:getModData()
    if type(data)~="table" or data.B47ANCEDPowerServiceRecovery~=nil then return end
    if B47ANCEDPower.getInstalledBatteryType(item) then
        B47ANCEDPower.consumeEnergy(item,math.max(0,tonumber(B47ANCEDPower.Config.DigitalWatchDrainPerMinute) or 0.0000002))
    end
    local state=data.B47ANCEDPower
    if state~=nil and type(state)~="table" then return end
    if (not state or (tonumber(state.chargeFraction) or 0)<=0) and item.isAlarmSet and item:isAlarmSet() then
        item:setAlarmSet(false)
        if item.stopRinging then item:stopRinging() end
        if item.syncAlarmClock then item:syncAlarmClock() end
    end
end

local function updateWatches()
    for playerIndex=0,3 do
        local player=getSpecificPlayer(playerIndex)
        if player then eachInventoryItem(player,function(item) maintainWatch(item,player) end) end
    end
end

local function unwrap(entry)
    local ok,item=pcall(function() return entry.items and entry.items[1] or entry end)
    return ok and item or nil
end

local function onContext(playerIndex,context,rawItems)
    if type(rawItems)~="table" or not context then return end
    local watch
    for _,entry in ipairs(rawItems) do local item=unwrap(entry); if isPoweredWatch(item) then watch=item break end end
    if not watch then return end
    local player=getSpecificPlayer(playerIndex); if not player then return end
    ensureWatch(watch)
    local name=watch:getDisplayName(); local option=context:getOptionFromName(name)
    local menu
    if option and option.subOption~=nil then menu=context:getSubMenu(option.subOption) end
    if not menu then
        option=option or context:addOption(name,watch,nil)
        menu=ISContextMenu:getNew(context); context:addSubMenu(option,menu)
    end
    local cells={}
    eachInventoryItem(player,function(item)
        if fullType(item)=="B47ANCEDPower.BatteryCoin" and (B47ANCEDPower.getCharge(item) or 0)>0 then cells[#cells+1]=item end
    end)
    local installed=B47ANCEDPower.getInstalledBatteryType(watch)
    if installed then menu:addOption(tr("ContextMenu_B47ANCEDPower_RemoveCoinCell","Remove Coin Cell"),player,B47ANCEDPower.queueExtractBattery,watch) end
    if #cells>0 then
        local root=menu:addOption(installed and tr("ContextMenu_B47ANCEDPower_ReplaceCoinCell","Replace Coin Cell")
            or tr("ContextMenu_B47ANCEDPower_InsertCoinCell","Insert Coin Cell"),watch,nil)
        local sub=ISContextMenu:getNew(context); menu:addSubMenu(root,sub)
        for _,cell in ipairs(cells) do
            local pct=math.floor((B47ANCEDPower.getCharge(cell)/B47ANCEDPower.getBatteryProfile(cell).capacity)*100+0.5)
            sub:addOption(tr("ContextMenu_B47ANCEDPower_CoinCellCharge","Coin Cell (%1%)",pct),player,
                installed and B47ANCEDPower.queueReplaceBattery or B47ANCEDPower.queueInstallBattery,watch,cell)
        end
    end
end

local reported=false
local function safeContext(...)
    local ok,err=pcall(onContext,...)
    if not ok and not reported then reported=true; print("[B47ANCE'd Power] Watch menu failed safely: "..tostring(err)) end
end

if Events and Events.EveryOneMinute then Events.EveryOneMinute.Add(updateWatches) end
if Events and Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(safeContext) end
B47ANCEDPower.maintainPoweredWatch=maintainWatch
B47ANCEDPower.ensurePoweredWatch=ensureWatch
B47ANCEDPower.requestWatchMaintenance=requestMaintenance
return B47ANCEDPower
