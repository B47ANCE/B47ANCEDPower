isClient=function()return false end;isServer=function()return true end
B47ANCEDPower={}
local registry=dofile(arg[1]);local events=dofile(arg[2]);local diagnostics=dofile(arg[3])

local function descriptor(kind,index,region)
    local value={stableKey=kind..":"..index,regionKey=region.key}
    if kind=="source"then value.availablePowerWatts=20;value.maximumPowerWatts=30
    elseif kind=="storage"then value.storedEnergyWh=5;value.capacityWh=10
    elseif kind=="load"then value.demandWatts=2
    else value.networkId="grid:1";value.status="online"end
    return value
end
for _,kind in ipairs({"source","storage","load","network"})do
    assert(registry.register(kind,{id="fixture."..kind,owner="fixture",matches=function()return false end,
        describe=function()end,queryRegion=function(region)return{descriptor(kind,1,region)}end}))
end
local store={};assert(events.attachStore(store))
assert(events.registerHandler{id="fixture.failure",apply=function()return false,"unsafe"end})
local accepted=result
accepted,result=events.ingest{schemaVersion=1,id="weather:1",occurrenceId="weather:1",type="high_wind",
    source="weatherWorks",phase="started",severity=.5,worldAgeHours=4,region={key="cell:1"},
    evidence={windPower=.5}}
assert(accepted and result.status=="inspection_required")

local summary=assert(diagnostics.summary())
assert(summary.providers.source.count==1 and summary.providers.network.count==1)
assert(summary.providers.source.entries[1].matches==nil,"diagnostics must not expose callbacks")
assert(summary.events.historyCount==1 and summary.events.failures["fixture.failure"].count==1)
local region=assert(diagnostics.inspectRegion({key="cell:1"},4))
assert(#region.kinds.source.entries==1 and region.kinds.source.entries[1].availablePowerWatts==20)
assert(region.kinds.load.entries[1].demandWatts==2)
local page=assert(diagnostics.listEvents(nil,1))
assert(#page.items==1 and page.complete and page.items[1].status=="inspection_required")
assert(page.items[1].handlers[1].id=="fixture.failure" and page.items[1].handlers[1].reason=="unsafe")
assert(page.items[1].queries.source.failures==0 and page.items[1].event==nil,
    "event diagnostics must expose a bounded sanitized view, not raw records")

isClient=function()return true end;isServer=function()return false end
assert(diagnostics.summary()==nil and diagnostics.inspectRegion({key="cell:1"})==nil
    and diagnostics.listEvents()==nil,"remote clients must not inspect authority-only state")
print("B47ANCEDPower bounded infrastructure diagnostic checks passed")
