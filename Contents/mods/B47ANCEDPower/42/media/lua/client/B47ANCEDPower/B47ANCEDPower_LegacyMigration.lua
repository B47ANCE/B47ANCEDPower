local B47ANCEDPower=require "B47ANCEDPower/Definitions"

local function migratePlayer(player)
    if not player then return end
    local lights={}
    local lightWorks=rawget(_G,"lightWorks")
    if lightWorks and lightWorks.collectPlayerLights then
        local ok,result=pcall(lightWorks.collectPlayerLights,player)
        if ok and type(result)=="table" then lights=result end
    end
    for _,consumer in ipairs(lights) do pcall(B47ANCEDPower.migrateInstalledLegacyBattery,consumer) end
    if B47ANCEDPower.Config.EnableVanillaBatteryLootConversion~=false and player.getInventory then
        local items=player:getInventory():getItems()
        local legacy={}
        for index=0,items:size()-1 do local item=items:get(index); if item and item:getFullType()=="Base.Battery" then legacy[#legacy+1]=item end end
        for _,battery in ipairs(legacy) do pcall(B47ANCEDPower.convertLooseLegacyBattery,player,battery) end
    end
end
local function migrateAll() for index=0,3 do migratePlayer(getSpecificPlayer(index)) end end
if Events and Events.OnGameStart then Events.OnGameStart.Add(migrateAll) end
if Events and Events.EveryOneMinute then Events.EveryOneMinute.Add(migrateAll) end
B47ANCEDPower.migratePlayerLegacyBatteries=migratePlayer
return B47ANCEDPower
