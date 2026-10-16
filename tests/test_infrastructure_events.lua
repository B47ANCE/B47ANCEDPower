isClient=function()return false end;isServer=function()return true end
B47ANCEDPower={};local registry=dofile(arg[1]);local events=dofile(arg[2])
local function provider(kind)
    registry.register(kind,{id="test."..kind,owner="test",matches=function()return false end,describe=function()end,
        queryRegion=function(region,limit)
            local result={};for index=1,math.min(2,limit)do
                local common={stableKey=kind..":"..index,regionKey=region.key}
                if kind=="source"then common.availablePowerWatts=100;common.maximumPowerWatts=120
                elseif kind=="storage"then common.storedEnergyWh=10;common.capacityWh=20
                elseif kind=="load"then common.demandWatts=5
                else common.networkId="grid:1";common.status="online"end
                result[#result+1]=common
            end;return result
        end})
end
for _,kind in ipairs({"source","storage","load","network"})do provider(kind)end
local store={};assert(events.attachStore(store))
local applied={}
assert(events.registerHandler{id="test.good",priority=10,supports=function(event)return event.type=="severe_storm"end,
    apply=function(event,proposal,targets)
        applied[#applied+1]={id=event.id,outage=proposal.outageRisk,sources=#targets.source};return true
    end})
assert(events.registerHandler{id="test.broken",priority=0,supports=function(event)return event.type=="high_wind"end,
    apply=function()error("expected failure")end})
local function event(id,kind,phase,hour,region)
    return {schemaVersion=1,id=id,occurrenceId=id:gsub(":ended$",""),type=kind,source="weatherWorks.climate",
        phase=phase,severity=phase=="ended"and 0 or .8,worldAgeHours=hour,region={key=region or"world"},
        evidence={windPower=.8,precipitation=.8,weatherActive=true}}
end
local ok,result=events.ingest(event("weatherWorks:storm:1","severe_storm","started",10))
assert(ok and result.status=="committed"and math.abs(result.consequence.outageRisk-.56)<0.000001)
assert(result.targetCounts.source==2 and result.targetCounts.network==2 and applied[1].sources==2)
local replayOk,replay=events.ingest(event("weatherWorks:storm:1","severe_storm","started",10))
assert(replayOk and replay.duplicate and #applied==1,"event replay must not reapply handlers")
local windOk,wind=events.ingest(event("weatherWorks:wind:1","high_wind","started",11))
assert(windOk and wind.status=="inspection_required")
local diagnostics=events.getDiagnostics();assert(diagnostics.failures["test.broken"].count==1)
local endOk,ended=events.ingest(event("weatherWorks:storm:1:ended","severe_storm","ended",12))
assert(endOk and ended.consequence.restorationSignal and ended.consequence.outageRisk==0)
local stale=events.ingest(event("weatherWorks:storm:old","severe_storm","started",9));assert(stale==false)
local page=assert(events.list(nil,2));assert(#page.items==2 and page.nextCursor)
local tail=assert(events.list(page.nextCursor,2));assert(#tail.items==1 and tail.complete)
local invalidRegion=events.ingest(event("weatherWorks:bad:region","high_wind","started",12,{bad=true}))
assert(invalidRegion==false,"unbounded region data must fail closed")
local invalidEvidence=event("weatherWorks:bad:evidence","high_wind","started",12)
invalidEvidence.evidence={unknown=true};assert(events.ingest(invalidEvidence)==false)
weatherWorks={listActiveEnvironmentalEvents=function()
    return {event("weatherWorks:storm:1","severe_storm","started",10),
        event("weatherWorks:wind:other","high_wind","started",13,"cell:other")}
end}
local caught,catchup=events.catchUpWeather()
assert(caught and catchup.available and catchup.examined==2 and catchup.processed==1)
assert(#store.history==4,"catch-up must deduplicate existing active events")
assert(events.attachStore(store)and store.revision==4,"persistent store reattach must preserve state")
registry.register("source",{id="test.failed",owner="test",matches=function()return false end,describe=function()end,
    queryRegion=function()error("expected query failure")end})
local beforeApplied=#applied
local partialOk,partial=events.ingest(event("weatherWorks:partial","severe_storm","started",14,"cell:partial"))
assert(partialOk and partial.status=="inspection_required"and#applied==beforeApplied,
    "incomplete provider discovery must not dispatch mutation handlers")
local interrupted={schemaVersion=1,revision=1,history={{eventId="interrupted",status="dispatching"}},processed={},latestByStream={}}
assert(events.attachStore(interrupted)and interrupted.history[1].status=="inspection_required")
assert(events.getDiagnostics().recoveredDispatches==1)
isClient=function()return true end;isServer=function()return false end
assert(events.ingest(event("weatherWorks:client","high_wind","started",14))==false)
print("B47ANCEDPower bounded environmental-infrastructure ingress checks passed")
