local Power=require "B47ANCEDPower/API"
local Events=Power.InfrastructureEvents;local store={};assert(Events.attachStore(store))
local function event(index)
 return{schemaVersion=1,id="retention:"..index,occurrenceId="retention:"..index,source="fixture",type="high_wind",phase="started",
 severity=.5,worldAgeHours=index,region={key="region:"..index},evidence={windPower=.5}}
end
for i=1,600 do assert(Events.ingest(event(i))) end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
assert(#store.history==256 and count(store.processed)==256 and count(store.latestByStream)==256)
assert(not Events.ingest(event(1)),"evicting a stream must not permit an exact old replay")
assert(Events.ingest(event(600)))
assert(Events.attachStore(store))
assert(not Events.ingest(event(2)),"retention floor must survive reattachment/restart")
assert(Events.ingest(event(601)))
local bad={schemaVersion=1,revision=0,history={{bad=true}},processed={},latestByStream={}}
assert(not Events.attachStore(bad) and bad.history[1].bad,"malformed saves must be preserved for inspection")
assert(Events.attachStore(store))
print("Bounded persistent history/maps, restart replay floor and malformed-save preservation passed")
