-- Shared schema; server sandbox values govern shared gameplay. Unknown keys and
-- non-finite/wrong-type values cannot become gameplay configuration.
local Sandbox={}
Sandbox.specs={
 BatteryCapacityMultiplier={1,.1,10},GlobalConsumptionMultiplier={1,0,10},UVConsumptionMultiplier={1,0,10},
 EnableImprovisedAdapters={true},ImprovisedEfficiencyMultiplier={1,0,2},ImprovisedResistanceMultiplier={1,.1,5},
 EnableVanillaBatteryLootConversion={true},
 LootWeightAAA={30,0,1000,true},LootWeightAA={42,0,1000,true},LootWeightC={10,0,1000,true},
 LootWeightD={10,0,1000,true},LootWeight9V={6,0,1000,true},LootWeightLithiumPack={2,0,1000,true},
 BatteryServiceTimeMultiplier={1,.1,5},ToolAssistedReplaceTimeBonus={.1,0,.5},
 DefaultBatteryInstallTime={55,1,1000,true},DefaultBatteryRemoveTime={35,1,1000,true},
 BatteryPackAssemblyEfficiency={.9,.1,1},DigitalWatchDrainPerMinute={.0000002,0,.001},
 CoinCellLootChance={.1,0,1},SolarMilitaryWatchLootChance={.003,0,.1},
 ExtraBatteryLootMultiplier={1,0,10},AdapterMagazineLootChance={.012,0,1},
}
function Sandbox.read(values)
    local result={}
    for key,spec in pairs(Sandbox.specs) do
        local value
        if type(values)=="table" then value=values[key] end
        if type(spec[1])=="boolean" then
            if type(value)~="boolean" then value=spec[1] end
        else
            if type(value)~="number" or value~=value or math.abs(value)==math.huge then value=spec[1] end
            value=math.max(spec[2],math.min(spec[3],value))
            if spec[4] then value=math.floor(value) end
        end
        result[key]=value
    end
    return result
end
return Sandbox
