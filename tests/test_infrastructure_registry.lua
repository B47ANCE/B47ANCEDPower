B47ANCEDPower={}
local Registry=dofile(arg[1])
assert(Registry.API_VERSION=="1.0.0")

local brokenMatches=function() error("broken") end
local sourceMatches=function(object) return object.source==true end
local sourceDescribe=function(object)
    return {stableKey=object.id,regionKey="cell:1",x=object.x,y=2,z=0,
        availablePowerWatts=80,maximumPowerWatts=100,metadata={fuel="owned"}}
end
assert(Registry.register("source",{id="thirdparty.broken",owner="thirdparty",priority=20,
    matches=brokenMatches,describe=function() error("unused") end}))
local provider,created=assert(Registry.register("source",{id="fixture.generator",owner="fixture",priority=10,
    matches=sourceMatches,describe=sourceDescribe,queryRegion=function(region,limit)
        local entries={}
        for index=1,limit+1 do entries[index]={stableKey="source:"..index,regionKey=region.key,
            availablePowerWatts=index,maximumPowerWatts=100} end
        return entries
    end}))
assert(created==true and provider.owner=="fixture")
local same,sameCreated=Registry.register("source",{id="fixture.generator",owner="fixture",priority=10,
    matches=sourceMatches,describe=sourceDescribe,queryRegion=provider.queryRegion})
assert(same==provider and sameCreated==false,"same callback registration must be idempotent")
assert(Registry.register("source",{id="fixture.generator",owner="hijack",matches=function() end,
    describe=function() end})==nil,"provider takeover must fail")

local described=assert(Registry.describe("source",{source=true,id="generator:1",x=1}))
assert(described.providerId=="fixture.generator" and described.availablePowerWatts==80)
assert(described.metadata.fuel=="owned")
local list=assert(Registry.list("source"));assert(#list==2 and list[1].id=="thirdparty.broken")
assert(list[1].matches==nil,"provider callbacks must not leak through metadata")
local queried,report=Registry.queryRegion("source",{key="cell:1"},3)
assert(#queried==3 and report.truncated==true and report.failures==0)
queried[1].metadata.changed=true
assert(#Registry.queryRegion("source",{key="cell:1"},1)==1)

local function registerFixture(kind,descriptor)
    return assert(Registry.register(kind,{id="fixture."..kind,owner="fixture",
        matches=function(object) return object.kind==kind end,
        describe=function() return descriptor end}))
end
registerFixture("storage",{stableKey="battery-bank",storedEnergyWh=50,capacityWh=100,
    maximumChargeWatts=20,maximumDischargeWatts=30,health=0.8})
registerFixture("load",{stableKey="lamp",demandWatts=12,priority=5})
registerFixture("network",{stableKey="grid",networkId="grid:1",nominalVoltage=120,status="online"})
assert(Registry.describe("storage",{kind="storage"}).storedEnergyWh==50)
assert(Registry.describe("load",{kind="load"}).demandWatts==12)
assert(Registry.describe("network",{kind="network"}).networkId=="grid:1")
assert(Registry.describe("storage",{kind="storage"},nil).health==0.8)

local invalid=Registry.register("storage",{id="fixture.invalid",owner="fixture",
    matches=function(object) return object.invalid end,
    describe=function() return {stableKey="bad",storedEnergyWh=2,capacityWh=1} end})
assert(invalid)
assert(Registry.describe("storage",{invalid=true})==nil,"over-capacity snapshot must fail closed")
local unknownPower=assert(Registry.register("source",{id="fixture.unknown",owner="fixture",priority=30,
    matches=function(object) return object.unknown==true end,
    describe=function() return {stableKey="unknown",powerKnown=false} end}))
local unknownSnapshot=assert(Registry.describe("source",{unknown=true}))
assert(unknownSnapshot.powerKnown==false and unknownSnapshot.availablePowerWatts==nil)
assert(Registry.register("source",{id="fixture.invalidUnknown",owner="fixture",priority=31,
    matches=function(object) return object.invalidUnknown==true end,
    describe=function() return {stableKey="invalid-unknown",powerKnown=false,availablePowerWatts=1} end}))
assert(Registry.describe("source",{invalidUnknown=true})==nil)
assert(Registry.queryRegion("source",{},2)==nil,"unbounded region query must fail")
assert(Registry.describe("invalid",{})==nil)
print("B47ANCEDPower bounded infrastructure provider registry checks passed")
