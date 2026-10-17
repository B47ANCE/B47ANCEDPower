local Power=require "B47ANCEDPower/Definitions"
local fraction=.2;local data={B47ANCEDPowerCharge=2.5}
local cell={getFullType=function()return "B47ANCEDPower.BatteryAA" end,getModData=function()return data end,
getCurrentUsesFloat=function()return fraction end,setUsedDelta=function(_,v)fraction=v end}
assert(Power.getCharge(cell)==.5,"native discharge must beat stale cached absolute charge")
assert(Power.setCharge(cell,1) and fraction==.4)
local profile=Power.getBatteryProfile(cell);profile.capacity=25
assert(Power.getCharge(cell)==1,"a capacity multiplier change must not multiply recorded cell energy")
profile.capacity=2.5
cell.setUsedDelta=function()end
assert(not Power.setCharge(cell,2) and fraction==.4 and data.B47ANCEDPowerCharge==1,"no-op setters cannot publish invented charge")
assert(not Power.setCharge(cell,0/0) and not Power.setCharge(cell,math.huge))
local unknown={getFullType=cell.getFullType,getModData=function()return{}end}
assert(Power.getCharge(unknown)==nil and not Power.setCharge(unknown,1),"unreadable cells fail closed")
isClient=function()return true end;isServer=function()return false end
assert(not Power.setCharge(cell,2))
local saved={};local watch={getFullType=function()return "Base.WristWatch_Right_DigitalBlack" end,getModData=function()return saved end}
assert(not Power.initializeEmbeddedBattery(watch,"B47ANCEDPower.BatteryCoin",1) and saved.B47ANCEDPower==nil)
isClient=function()return false end
saved.B47ANCEDPowerEnergyRecovery={}
assert(not Power.initializeEmbeddedBattery(watch,"B47ANCEDPower.BatteryCoin",1))
print("Native charge readback, stale cache, malformed inputs and authority checks passed")
