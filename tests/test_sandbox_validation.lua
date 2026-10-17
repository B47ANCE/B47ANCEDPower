local Sandbox=require "B47ANCEDPower/Sandbox"
local defaults=Sandbox.read(nil)
local values=Sandbox.read{EnableImprovisedAdapters=false,EnableVanillaBatteryLootConversion=false,
 BatteryCapacityMultiplier=0/0,GlobalConsumptionMultiplier=math.huge,ExtraBatteryLootMultiplier=100,
 AdapterMagazineLootChance=-2,LootWeightAA=4.9,UnknownProtocolValue=100}
assert(values.EnableImprovisedAdapters==false and values.EnableVanillaBatteryLootConversion==false)
assert(values.BatteryCapacityMultiplier==defaults.BatteryCapacityMultiplier)
assert(values.GlobalConsumptionMultiplier==defaults.GlobalConsumptionMultiplier)
assert(values.ExtraBatteryLootMultiplier==10 and values.AdapterMagazineLootChance==0)
assert(values.LootWeightAA==4 and values.UnknownProtocolValue==nil)
SandboxVars={B47ANCEDPower={EnableImprovisedAdapters=false,ExtraBatteryLootMultiplier=0,AdapterMagazineLootChance=0}}
local Power=require "B47ANCEDPower/Definitions"
assert(Power.Config.EnableImprovisedAdapters==false and Power.Config.ExtraBatteryLootMultiplier==0)
local callback;Events={OnFillContainer={Add=function(fn)callback=fn end}}
local calls={};local container={AddItem=function(_,name)calls[#calls+1]=name;return{}end,
getItems=function()return{size=function()return 0 end}end}
ZombRand=function()return 0 end
require "B47ANCEDPower/Distribution"
callback("garage","electronic",container)
assert(#calls==1 and calls[1]=="B47ANCEDPower.BatteryCoin","extra loot multiplier must disable ordinary additions only")
callback("library","books",container)
assert(#calls==1,"zero magazine chance must disable magazine additions")
print("Sandbox validation, existing-save defaults and grouped loot controls passed")
