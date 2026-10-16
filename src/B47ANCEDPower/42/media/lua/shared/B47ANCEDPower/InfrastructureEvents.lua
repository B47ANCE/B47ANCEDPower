local B47ANCEDPower=rawget(_G,"B47ANCEDPower")or{}
local Registry=B47ANCEDPower.InfrastructureRegistry or require "B47ANCEDPower/InfrastructureRegistry"
local EventsAPI={SCHEMA_VERSION=1,STORE_KEY="B47ANCEDPower.InfrastructureEvents.v1",MAX_HANDLERS=64,
    MAX_HISTORY=256,MAX_PAGE=32,MAX_TARGETS_PER_KIND=64}
local TYPES={high_wind=true,severe_storm=true,lightning=true,tornado=true,flood=true,
    wildfire=true,earthquake=true,acid_rain=true,fallout=true,nuclear_winter=true}
local PHASES={started=true,updated=true,ended=true};local PHASE_RANK={started=1,updated=2,ended=3}
local EVIDENCE={temperature=true,precipitation=true,snowStrength=true,fog=true,cloud=true,
    windPower=true,windIntensity=true,daylight=true,humidity=true,weatherActive=true,season=true}
local handlers={};local handlerCount=0;local attachedStore=nil;local failures={};local recoveredDispatches=0

local function authoritative()
    return not(type(isClient)=="function"and isClient()==true and not(type(isServer)=="function"and isServer()==true))
end
local function finite(value)
    value=tonumber(value);return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end
local function valid(value,maximum)
    return type(value)=="string"and value~=""and #value<=(maximum or 160)
        and value:match("^[%w_.:%-]+$")~=nil
end
local function copy(value,depth,seen)
    if type(value)~="table"then return value end
    depth=(depth or 0)+1;if depth>5 then return nil end
    seen=seen or{};if seen[value]then return nil end;seen[value]=true
    local result,count={},0
    for key,entry in pairs(value)do
        count=count+1;if count>128 then break end
        if type(key)=="string"or type(key)=="number"then
            if type(entry)=="table"then result[key]=copy(entry,depth,seen)
            elseif type(entry)=="string"or type(entry)=="number"or type(entry)=="boolean"then result[key]=entry end
        end
    end
    seen[value]=nil;return result
end
local function newStore()
    return {schemaVersion=EventsAPI.SCHEMA_VERSION,revision=0,history={},processed={},latestByStream={}}
end
local function storeOk(store)
    return type(store)=="table"and store.schemaVersion==EventsAPI.SCHEMA_VERSION
        and type(store.history)=="table"and type(store.processed)=="table"and type(store.latestByStream)=="table"
end
local function normalizeRegion(value)
    if type(value)~="table"or not valid(value.key,192)then return nil,"bounded infrastructure region required"end
    local result={key=value.key}
    for _,key in ipairs({"minX","minY","maxX","maxY","z"})do
        if value[key]~=nil then
            local number=finite(value[key]);if not number then return nil,"invalid infrastructure region"end
            result[key]=number
        end
    end
    if result.minX and result.maxX and result.minX>result.maxX
        or result.minY and result.maxY and result.minY>result.maxY then return nil,"invalid infrastructure region bounds"end
    return result
end
local function normalizeEvidence(value)
    if type(value)~="table"then return nil,"infrastructure event evidence required"end
    local result,count={},0
    for key,entry in pairs(value)do
        if EVIDENCE[key]then
            count=count+1;if count>16 then return nil,"infrastructure event evidence limit exceeded"end
            if type(entry)=="number"then
                entry=finite(entry);if not entry then return nil,"invalid infrastructure event evidence"end;result[key]=entry
            elseif type(entry)=="boolean"then result[key]=entry
            elseif type(entry)=="string"and#entry<=48 and not entry:find("[%c]",1)then result[key]=entry
            else return nil,"invalid infrastructure event evidence"end
        end
    end
    if count==0 then return nil,"recognized infrastructure event evidence required"end
    return result
end
local function normalizeEvent(value)
    if type(value)~="table"or tonumber(value.schemaVersion)~=1 or not valid(value.id,160)
        or not valid(value.occurrenceId or value.id,160)or not TYPES[value.type]
        or not valid(value.source,64)or not PHASES[value.phase]then return nil,"unsupported infrastructure event"end
    local severity,hour=finite(value.severity),finite(value.worldAgeHours)
    if not severity or severity<0 or severity>1 or not hour or hour<0 then return nil,"invalid infrastructure event"end
    local region,regionErr=normalizeRegion(value.region);if not region then return nil,regionErr end
    local evidence,evidenceErr=normalizeEvidence(value.evidence);if not evidence then return nil,evidenceErr end
    return {schemaVersion=1,id=value.id,occurrenceId=value.occurrenceId or value.id,type=value.type,
        source=value.source,phase=value.phase,severity=severity,worldAgeHours=hour,
        region=region,evidence=evidence}
end
local function stream(event)return table.concat({event.source,event.type,event.region.key},":")end
local function risk(value)return math.max(0,math.min(1,value))end
local function consequence(event)
    local severity=event.phase=="ended"and 0 or event.severity
    local result={schemaVersion=1,eventId=event.id,occurrenceId=event.occurrenceId,phase=event.phase,
        type=event.type,severity=severity,region=copy(event.region),restorationSignal=event.phase=="ended",
        outageRisk=0,surgeRisk=0,physicalDamageRisk=0,shortRisk=0,solarDerate=0,maintenanceBurden=0}
    if event.type=="high_wind"then
        result.outageRisk=risk(severity*.55);result.physicalDamageRisk=risk(severity*.35);result.surgeRisk=risk(severity*.10)
    elseif event.type=="severe_storm"then
        result.outageRisk=risk(severity*.70);result.surgeRisk=risk(severity*.65)
        result.physicalDamageRisk=risk(severity*.40);result.shortRisk=risk(severity*.30)
    elseif event.type=="lightning"then result.outageRisk=risk(severity*.6);result.surgeRisk=risk(severity)
    elseif event.type=="tornado"then result.outageRisk=risk(severity);result.physicalDamageRisk=risk(severity)
    elseif event.type=="flood"then result.outageRisk=risk(severity*.8);result.shortRisk=risk(severity)
    elseif event.type=="wildfire"then result.outageRisk=risk(severity*.9);result.physicalDamageRisk=risk(severity*.8)
    elseif event.type=="earthquake"then result.outageRisk=risk(severity);result.physicalDamageRisk=risk(severity*.9)
    elseif event.type=="acid_rain"then result.maintenanceBurden=risk(severity*.7);result.shortRisk=risk(severity*.2)
    elseif event.type=="fallout"then result.maintenanceBurden=risk(severity);result.solarDerate=risk(severity*.35)
    elseif event.type=="nuclear_winter"then result.solarDerate=risk(severity);result.maintenanceBurden=risk(severity*.25)end
    return result
end
local function targets(event)
    local all,reports={},{ }
    for _,kind in ipairs({"source","storage","load","network"})do
        local values,report=Registry.queryRegion(kind,copy(event.region),EventsAPI.MAX_TARGETS_PER_KIND)
        all[kind]=type(values)=="table"and values or{};reports[kind]=report or{failures=1,truncated=false}
    end
    return all,reports
end
local function orderedHandlers()
    local result={};for _,entry in pairs(handlers)do result[#result+1]=entry end
    table.sort(result,function(a,b)return a.priority==b.priority and a.id<b.id or a.priority>b.priority end)
    return result
end
local function fail(id,reason)
    local entry=failures[id]or{count=0};entry.count=entry.count+1
    entry.lastError=tostring(reason or"handler failure"):sub(1,200);failures[id]=entry
end
-- Retention is a technical storage bound. An eviction advances a persistent
-- time floor so discarding an old stream never makes its exact replay valid.
local function retain(store)
    if #store.history>4096 then return false,"oversized legacy history requires inspection" end
    local floor=finite(store.expiredThrough) or -1
    local history,processed,latest={},{},{}
    local start=math.max(1,#store.history-EventsAPI.MAX_HISTORY+1)
    for index,record in ipairs(store.history) do
        if type(record)~="table" or not valid(record.eventId,160) or not valid(record.stream,512)
            or not finite(record.worldAgeHours) or type(record.event)~="table" or not PHASES[record.event.phase] then
            return false,"malformed legacy event history requires inspection"
        end
        if index<start then floor=math.max(floor,record.worldAgeHours)
        else
            history[#history+1]=record;processed[record.eventId]=true
            latest[record.stream]={id=record.eventId,worldAgeHours=record.worldAgeHours,phase=record.event.phase}
        end
    end
    local inspected=0
    for key,record in pairs(store.latestByStream) do
        inspected=inspected+1;if inspected>4096 then return false,"oversized legacy streams require inspection" end
        if not latest[key] then
            local hour=type(record)=="table" and finite(record.worldAgeHours) or nil
            if not hour then return false,"malformed legacy stream requires inspection" end
            floor=math.max(floor,hour)
        end
    end
    store.history=history;store.processed=processed;store.latestByStream=latest;store.expiredThrough=floor
    return true
end

function EventsAPI.attachStore(store)
    if not authoritative() then return false,"non-authority" end
    if type(store)~="table"then return false,"infrastructure event store required"end
    local empty=true;for _ in pairs(store)do empty=false;break end
    if empty then local created=newStore();for key,value in pairs(created)do store[key]=value end end
    if not storeOk(store)then return false,"unsupported infrastructure event store"end
    local retained,reason=retain(store);if not retained then return false,reason end
    for _,record in ipairs(store.history)do
        if type(record)=="table"and record.status=="dispatching"then
            record.status="inspection_required";record.recoveryReason="interrupted handler dispatch"
            recoveredDispatches=recoveredDispatches+1
        end
    end
    attachedStore=store;return true,store
end

function EventsAPI.registerHandler(definition)
    assert(type(definition)=="table"and valid(definition.id,96),"infrastructure event handler id required")
    assert(type(definition.apply)=="function","infrastructure event apply callback required")
    assert(not handlers[definition.id],"duplicate infrastructure event handler: "..definition.id)
    assert(handlerCount<EventsAPI.MAX_HANDLERS,"infrastructure event handler limit reached")
    handlers[definition.id]={id=definition.id,priority=finite(definition.priority)or 0,
        supports=definition.supports,apply=definition.apply};handlerCount=handlerCount+1;return true
end

function EventsAPI.ingest(value)
    if not authoritative()then return false,"non-authority"end
    if not attachedStore then return false,"infrastructure event store unavailable"end
    local event,err=normalizeEvent(value);if not event then return false,err end
    if attachedStore.processed[event.id]then return true,{duplicate=true,eventId=event.id}end
    if event.worldAgeHours<=(attachedStore.expiredThrough or -1) then return false,"event predates retention floor" end
    local key=stream(event);local latest=attachedStore.latestByStream[key]
    if type(latest)=="table"then
        local latestHour=tonumber(latest.worldAgeHours)or 0
        if event.worldAgeHours<latestHour or event.worldAgeHours==latestHour
            and(PHASE_RANK[event.phase]or 0)<=(PHASE_RANK[latest.phase]or 0)then return false,"stale infrastructure event"end
    end
    local proposal=consequence(event);local regional,queryReports=targets(event)
    local queryFailed=false
    for _,report in pairs(queryReports)do
        if(type(report.failures)~="number"or report.failures>0)then queryFailed=true;break end
    end
    local record={schemaVersion=1,eventId=event.id,occurrenceId=event.occurrenceId,stream=key,
        worldAgeHours=event.worldAgeHours,status="dispatching",event=copy(event),consequence=copy(proposal),
        queryReports=copy(queryReports),handlerResults={}}
    attachedStore.history[#attachedStore.history+1]=record;attachedStore.processed[event.id]=true
    attachedStore.latestByStream[key]={id=event.id,worldAgeHours=event.worldAgeHours,phase=event.phase}
    assert(retain(attachedStore))
    attachedStore.revision=(tonumber(attachedStore.revision)or 0)+1
    local uncertain=queryFailed
    for _,handler in ipairs(queryFailed and{}or orderedHandlers())do
        local supported=true
        if type(handler.supports)=="function"then
            local ok,result=pcall(handler.supports,copy(event),copy(proposal));supported=ok and result==true
            if not ok then fail(handler.id,result);uncertain=true end
        end
        if supported then
            local ok,result,reason=pcall(handler.apply,copy(event),copy(proposal),copy(regional))
            local committed=ok and result==true
            record.handlerResults[#record.handlerResults+1]={id=handler.id,committed=committed,
                reason=committed and nil or tostring(ok and reason or result):sub(1,160)}
            if not committed then fail(handler.id,ok and reason or result);uncertain=true end
        end
    end
    record.status=uncertain and"inspection_required"or"committed"
    return true,{duplicate=false,eventId=event.id,status=record.status,consequence=copy(proposal),
        targetCounts={source=#regional.source,storage=#regional.storage,load=#regional.load,network=#regional.network}}
end

function EventsAPI.catchUpWeather()
    if not authoritative()then return false,"non-authority"end
    local weather=rawget(_G,"weatherWorks");local list=weather and weather.listActiveEnvironmentalEvents
    if type(list)~="function"then return true,{available=false,examined=0,processed=0}end
    local ok,events=pcall(list);if not ok or type(events)~="table"then return false,"weather event query failed"end
    local examined,processed=0,0
    for index=1,math.min(#events,EventsAPI.MAX_PAGE)do
        local accepted,result=EventsAPI.ingest(events[index])
        if accepted then
            examined=examined+1
            if not(result and result.duplicate)then processed=processed+1 end
        end
    end
    return true,{available=true,examined=examined,processed=processed}
end

function EventsAPI.list(cursor,limit)
    if not attachedStore then return nil,"infrastructure event store unavailable"end
    limit=math.max(1,math.min(EventsAPI.MAX_PAGE,math.floor(finite(limit)or EventsAPI.MAX_PAGE)))
    local start=1
    if cursor~=nil then
        if not valid(cursor,160)then return nil,"invalid infrastructure event cursor"end
        local found=false;for index,entry in ipairs(attachedStore.history)do
            if entry.eventId==cursor then start=index+1;found=true;break end
        end
        if not found then return nil,"unknown infrastructure event cursor"end
    end
    local items,last={},nil
    for index=start,math.min(#attachedStore.history,start+limit-1)do
        items[#items+1]=copy(attachedStore.history[index]);last=attachedStore.history[index].eventId
    end
    local complete=start+#items>#attachedStore.history;local nextCursor=last;if complete then nextCursor=nil end
    return {schemaVersion=1,revision=attachedStore.revision,items=items,nextCursor=nextCursor,complete=complete}
end

function EventsAPI.getDiagnostics()
    local result={handlerCount=handlerCount,failures={},historyCount=attachedStore and#attachedStore.history or 0,
        revision=attachedStore and attachedStore.revision or nil,recoveredDispatches=recoveredDispatches}
    for id,entry in pairs(failures)do result.failures[id]=copy(entry)end;return result
end

B47ANCEDPower.InfrastructureEvents=EventsAPI
B47ANCEDPower.attachInfrastructureEventStore=EventsAPI.attachStore
B47ANCEDPower.registerInfrastructureEventHandler=EventsAPI.registerHandler
B47ANCEDPower.ingestInfrastructureEvent=EventsAPI.ingest
B47ANCEDPower.listInfrastructureEvents=EventsAPI.list
_G.B47ANCEDPower=B47ANCEDPower
return EventsAPI
