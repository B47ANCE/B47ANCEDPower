require "B47ANCEDPower/Definitions"

local function roll(chance)
    if ZombRand then return ZombRand(10000)<math.floor(chance*10000) end
    return math.random()<chance
end

local function add(container,itemType)
    local ok,item=pcall(function() return container:AddItem(itemType) end)
    return ok and item~=nil
end

local function convertVanillaBatteryLoot(container)
    if B47ANCEDPower.Config.EnableVanillaBatteryLootConversion==false then return 0 end
    local ok,items=pcall(function() return container:getItems() end)
    if not ok or not items then return 0 end
    local legacy={}
    for index=0,items:size()-1 do
        local item=items:get(index)
        if item and item:getFullType()=="Base.Battery" then legacy[#legacy+1]=item end
    end
    local converted=0
    for _,old in ipairs(legacy) do
        local ok,result=pcall(B47ANCEDPower.convertLegacyBatteryInContainer,container,old)
        if ok and result==true then converted=converted+1 end
    end
    return converted
end

local function onFillContainer(roomType,containerType,container)
    if not container or tostring(container):find("ItemPickerContainer",1,true) then return end
    local context=string.lower(tostring(roomType or "").." "..tostring(containerType or ""))
    local electronics=context:find("elect",1,true) or context:find("garage",1,true)
        or context:find("tool",1,true) or context:find("military",1,true)
    local literature=context:find("book",1,true) or context:find("library",1,true)
        or context:find("magazine",1,true)
    local military=context:find("military",1,true) or context:find("army",1,true)
        or context:find("surplus",1,true)
    if electronics then
        if roll(math.max(0,math.min(1,tonumber(B47ANCEDPower.Config.CoinCellLootChance) or 0.10))) then
            add(container,"B47ANCEDPower.BatteryCoin")
        end
        if roll(0.08) then add(container,"B47ANCEDPower.BatteryAAA") end
        if roll(0.10) then add(container,"B47ANCEDPower.BatteryAA") end
        if roll(0.045) then add(container,"B47ANCEDPower.BatteryC") end
        if roll(0.04) then add(container,"B47ANCEDPower.BatteryD") end
        if roll(0.025) then add(container,"B47ANCEDPower.Battery9V") end
        if roll(0.01) then add(container,"B47ANCEDPower.BatteryLithiumPack") end
    end
    if literature and roll(0.012) then add(container,"B47ANCEDPower.BatteryAdapterMagazine") end
    if military and roll(math.max(0,math.min(1,tonumber(B47ANCEDPower.Config.SolarMilitaryWatchLootChance) or 0.003))) then
        add(container,roll(0.5) and "B47ANCEDPower.SolarMilitaryWatch_Left" or "B47ANCEDPower.SolarMilitaryWatch_Right")
    end
    convertVanillaBatteryLoot(container)
end

B47ANCEDPower.convertVanillaBatteryLoot=convertVanillaBatteryLoot

if Events and Events.OnFillContainer then Events.OnFillContainer.Add(onFillContainer) end
