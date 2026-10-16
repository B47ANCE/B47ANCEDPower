local B47ANCEDPower={Batteries={
    ["Test.AA"]={item="Test.AA",size="AA",capacity=2.5},
    ["Test.AAImprovised"]={item="Test.AAImprovised",size="AA",capacity=2.5},
    ["Test.AAPack"]={item="Test.AAPack",size="AA_PACK",capacity=9,pack=true},
}}
function B47ANCEDPower.getBatteryProfile(value) return B47ANCEDPower.Batteries[value] end
function B47ANCEDPower.getConsumerProfile() return {sizes={"AA","AA_PACK"},nominalCellCount=2} end
function B47ANCEDPower.accepts(_,battery)
    local profile=B47ANCEDPower.getBatteryProfile(battery)
    return profile and (profile.size=="AA" or profile.size=="AA_PACK")
end
function B47ANCEDPower.getCharge(battery) return battery.charge end
package.loaded["B47ANCEDPower/API"]=B47ANCEDPower
package.loaded["B47ANCEDPower/CellSet"]=nil
local CellSet=require "B47ANCEDPower/CellSet"

local set=assert(CellSet.create({
    {batteryType="Test.AA",charge=2.5,metadata={B47ANCEDPowerSource="factory",foreign={bad=true}}},
    {batteryType="Test.AAImprovised",charge=1.25,metadata={B47ANCEDPowerImprovised=true,B47ANCEDPowerResistance=1.25}},
}))
local summary=assert(CellSet.summary(set))
assert(summary.cellCount==2 and summary.totalCapacity==5 and summary.totalCharge==3.75)
assert(math.abs(summary.chargeFraction-0.75)<0.000001)
assert(set.cells[1].metadata.foreign==nil,"third-party tables must not enter persisted cell state")

assert(CellSet.reconcileFraction(set,0.375))
summary=assert(CellSet.summary(set))
assert(math.abs(summary.totalCharge-1.875)<0.000001)
assert(math.abs(set.cells[1].charge-1.25)<0.000001 and math.abs(set.cells[2].charge-0.625)<0.000001,
    "discharge must preserve relative cell imbalance")
assert(not CellSet.reconcileFraction(set,0.9),"passive observation must never synthesize charge")

local copy=assert(CellSet.copyCells(set)); copy[1].charge=0
assert(set.cells[1].charge>0,"public descriptors must not expose canonical mutable tables")
assert(not CellSet.create({{batteryType="Unknown.Cell",charge=1}}))
assert(not CellSet.create({{batteryType="Test.AA",charge=99}}))
assert(not CellSet.validate({schemaVersion=99,cells={}}))
assert(not CellSet.validate(set,1) and CellSet.validate(set,2))

local a={kind="a",charge=2.0}; setmetatable(a,{__tostring=function() return "a" end})
local b={kind="b",charge=1.0}; setmetatable(b,{__tostring=function() return "b" end})
local c={kind="c",charge=0.5}; setmetatable(c,{__tostring=function() return "c" end})
B47ANCEDPower.Batteries[a]=B47ANCEDPower.Batteries["Test.AA"]
B47ANCEDPower.Batteries[b]=B47ANCEDPower.Batteries["Test.AAImprovised"]
B47ANCEDPower.Batteries[c]=B47ANCEDPower.Batteries["Test.AA"]
assert(B47ANCEDPower.getRequiredCellCount({},a)==2)
local selected=assert(B47ANCEDPower.selectBatterySet({}, {c,b,a}))
assert(#selected==2 and selected[1]==a and selected[2]==b,"selection prefers the strongest compatible cells")
assert(B47ANCEDPower.validateBatterySet({},selected))
assert(not B47ANCEDPower.validateBatterySet({}, {a,a}),"one physical item cannot fill two slots")
local pack={charge=8}; B47ANCEDPower.Batteries[pack]=B47ANCEDPower.Batteries["Test.AAPack"]
assert(B47ANCEDPower.getRequiredCellCount({},pack)==1 and B47ANCEDPower.validateBatterySet({}, {pack}))

print("B47ANCEDPower versioned cell-set energy and validation checks passed")
