B47ANCEDPower={}
local Registry=dofile(arg[1])
local Provider=dofile(arg[2])
assert(Provider.sourceRegistered and Provider.networkRegistered)

local square={}
function square:getX() return 10 end
function square:getY() return 20 end
function square:getZ() return 0 end
local generator={fuel=5,condition=80,activated=true,connected=true,total=0.14,index=2}
function generator:getObjectName() return "IsoGenerator" end
function generator:getSquare() return square end
function generator:getObjectIndex() return self.index end
function generator:getFuel() return self.fuel end
function generator:getMaxFuel() return 10 end
function generator:getCondition() return self.condition end
function generator:isActivated() return self.activated end
function generator:isConnected() return self.connected end
function generator:getTotalPowerUsing() return self.total end
function generator:getGeneratorItemType() return "Base.Generator" end

local source=assert(Registry.describe("source",generator))
assert(source.stableKey=="generator:10:20:0:2" and source.powerKnown==false)
assert(source.availablePowerWatts==nil and source.enabled==true)
assert(source.metadata.fuelFraction==0.5 and source.metadata.conditionFraction==0.8)
assert(source.metadata.nativeFuelUsePerHour==0.14)
local network=assert(Registry.describe("network",generator))
assert(network.networkId=="vanilla:generator:10:20:0:2" and network.status=="online")

generator.connected=false
source=assert(Registry.describe("source",generator));network=assert(Registry.describe("network",generator))
assert(source.enabled==false and network.status=="disconnected")
generator.connected=true;generator.fuel=0
assert(Registry.describe("network",generator).status=="empty")
generator.fuel=5;generator.condition=0
assert(Registry.describe("network",generator).status=="failed")
generator.condition=80;generator.activated=false
assert(Registry.describe("network",generator).status=="offline")

generator.index=-1
assert(Registry.describe("source",generator)==nil,"unloaded generator must fail closed")
assert(Registry.describe("source",{getObjectName=function() return "Other" end})==nil)
print("B47ANCEDPower vanilla generator observation-provider checks passed")
