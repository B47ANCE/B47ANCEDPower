local B47ANCEDPower=require "B47ANCEDPower/API"
local batteries={
    {item="Base.Battery",size="LEGACY",capacity=2.5,nominalVoltage=1.5,displayName="Vanilla Battery"},
    {item="B47ANCEDPower.BatteryAAA",size="AAA",capacity=1.0,nominalVoltage=1.5,displayName="AAA Battery"},
    {item="B47ANCEDPower.BatteryAA",size="AA",capacity=2.5,nominalVoltage=1.5,displayName="AA Battery"},
    {item="B47ANCEDPower.BatteryC",size="C",capacity=8.0,nominalVoltage=1.5,displayName="C Battery"},
    {item="B47ANCEDPower.BatteryD",size="D",capacity=12.0,nominalVoltage=1.5,displayName="D Battery"},
    {item="B47ANCEDPower.Battery9V",size="9V",capacity=5.0,nominalVoltage=9.0,displayName="9V Battery"},
    {item="B47ANCEDPower.BatteryLithiumPack",size="PACK",capacity=15.0,nominalVoltage=3.7,rechargeable=true,displayName="Rechargeable Lithium Pack"},
    {item="B47ANCEDPower.BatteryCoin",size="COIN",capacity=0.25,nominalVoltage=3.0,displayName="Coin Cell Battery"},
    {item="B47ANCEDPower.BatteryPackSmall",size="AA_PACK",capacity=9.0,nominalVoltage=6.0,pack=true,improvised=true,resistance=1.1,displayName="Taped AA Battery Pack"},
    {item="B47ANCEDPower.BatteryPackLarge",size="D_PACK",capacity=30.0,nominalVoltage=6.0,pack=true,improvised=true,resistance=1.15,displayName="Large Taped D Battery Pack"},
    {item="B47ANCEDPower.BatteryAAImprovised",size="AA",capacity=2.5,nominalVoltage=1.5,efficiency=0.82,improvised=true,resistance=1.25,displayName="Improvised AA Battery"},
}
for _,definition in ipairs(batteries) do B47ANCEDPower.registerBattery(definition) end
require "B47ANCEDPower/CellSet"
require "B47ANCEDPower/MultiCellService"
require "B47ANCEDPower/VanillaGeneratorProvider"
for _,itemType in ipairs({"Base.WristWatch_Right_DigitalBlack","Base.WristWatch_Left_DigitalBlack",
    "Base.WristWatch_Right_DigitalRed","Base.WristWatch_Left_DigitalRed",
    "Base.WristWatch_Right_DigitalDress","Base.WristWatch_Left_DigitalDress",
    "Base.WristWatch_Right_Expensive","Base.WristWatch_Left_Expensive"}) do
    B47ANCEDPower.registerConsumer({item=itemType,sizes={"COIN"},storageMode="modData",referenceCapacity=0.25,
        baseUseDelta=0.00002,installTime=80,removeTime=70,provider="B47ANCEDPowerWatch"})
end
return B47ANCEDPower
