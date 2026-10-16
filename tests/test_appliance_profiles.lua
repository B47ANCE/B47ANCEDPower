B47ANCEDPower={}
local Registry=dofile(arg[1]);local Profiles=dofile(arg[2])
local function object(sprite,group,active)return{getSprite=function()return{getName=function()return sprite end}end,group=group,active=active}end
Profiles.register{id="fixture.walkinCooler",owner="fixture",spriteNames={"fixture_cooler_left","fixture_cooler_right"},
    demandWatts=850,logicalIdentity=function(value)return"cooler:"..value.group end,isActive=function(value)return value.active end}
local left=object("fixture_cooler_left","10:20:0",true);local right=object("fixture_cooler_right","10:20:0",true)
local loads,report=Profiles.describeObjects({right,left},nil,8)
assert(#loads==1 and loads[1].demandWatts==850 and loads[1].metadata.absoluteDemand==true)
assert(report.inspected==2 and report.logicalLoads==1 and report.failures==0)
local off=object("fixture_cooler_left","11:20:0",false);loads=assert(Profiles.describeObjects({off},nil,8));assert(loads[1].demandWatts==0)
loads,report=Profiles.describeObjects({left,object("fixture_cooler_right","10:20:0",false)},nil,8)
assert(#loads==0 and report.failures==1,"conflicting squares must quarantine the logical load")
local reversed=assert(Profiles.describeObjects({object("fixture_cooler_right","10:20:0",false),left},nil,8))
assert(#reversed==0,"ambiguous billing must not depend on object order")
local unknown=object("other","x",true);loads,report=Profiles.describeObjects({unknown},nil,8);assert(#loads==0 and report.failures==0)
local invalid=object("fixture_cooler_left","bad\nkey",true);loads,report=Profiles.describeObjects({invalid},nil,8);assert(#loads==0 and report.failures==1)
assert(Profiles.describeObjects({},nil,257)==nil)
local ok=pcall(Profiles.register,{id="fixture.inferred",owner="fixture",spriteNames={"fixture"},logicalIdentity=function()return"x"end})
assert(not ok,"profiles must never infer absent demand from footprint")
print("B47ANCEDPower absolute appliance profile and logical deduplication checks passed")
