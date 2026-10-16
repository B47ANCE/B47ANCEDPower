local B47ANCEDPower=rawget(_G,"B47ANCEDPower") or {}
local Registry=B47ANCEDPower.InfrastructureRegistry or require "B47ANCEDPower/InfrastructureRegistry"
local Events=B47ANCEDPower.InfrastructureEvents or require "B47ANCEDPower/InfrastructureEvents"

local Diagnostics={API_VERSION="1.0.0",MAX_PAGE=32}
local KINDS={"source","storage","load","network"}

local function authoritative()
    local client=type(rawget(_G,"isClient"))=="function" and isClient()==true
    local server=type(rawget(_G,"isServer"))=="function" and isServer()==true
    return server or not client
end

local function finite(value)
    value=tonumber(value)
    return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end

local function cleanText(value,maximum)
    if value==nil then return nil end
    value=tostring(value)
    if value:find("[%c]") then return nil end
    return value:sub(1,maximum or 160)
end

local function eventView(record)
    if type(record)~="table" then return nil end
    local event=type(record.event)=="table" and record.event or {}
    local result={
        eventId=cleanText(record.eventId,160),
        occurrenceId=cleanText(record.occurrenceId,160),
        status=cleanText(record.status,48) or "unknown",
        recoveryReason=cleanText(record.recoveryReason,160),
        type=cleanText(event.type,48),
        source=cleanText(event.source,64),
        phase=cleanText(event.phase,24),
        worldAgeHours=finite(record.worldAgeHours),
        severity=finite(event.severity),
        handlers={},queries={},
    }
    for _,entry in ipairs(type(record.handlerResults)=="table" and record.handlerResults or {}) do
        if #result.handlers>=Events.MAX_HANDLERS then break end
        if type(entry)=="table" then
            result.handlers[#result.handlers+1]={id=cleanText(entry.id,96),committed=entry.committed==true,
                reason=cleanText(entry.reason,160)}
        end
    end
    for _,kind in ipairs(KINDS) do
        local report=type(record.queryReports)=="table" and record.queryReports[kind] or nil
        result.queries[kind]={failures=math.max(0,math.floor(finite(report and report.failures) or 0)),
            truncated=report and report.truncated==true or false}
    end
    return result
end

function Diagnostics.summary()
    if not authoritative() then return nil,"non-authority" end
    local result={apiVersion=Diagnostics.API_VERSION,providers={},events=Events.getDiagnostics()}
    for _,kind in ipairs(KINDS) do
        local entries,err=Registry.list(kind)
        if not entries then return nil,err end
        result.providers[kind]={count=#entries,entries=entries}
    end
    return result
end

function Diagnostics.inspectRegion(region,limit)
    if not authoritative() then return nil,"non-authority" end
    limit=math.max(1,math.min(Registry.MAX_QUERY_RESULTS,math.floor(finite(limit) or Registry.MAX_QUERY_RESULTS)))
    local result={regionKey=type(region)=="table" and cleanText(region.key,192) or nil,kinds={}}
    for _,kind in ipairs(KINDS) do
        local entries,report=Registry.queryRegion(kind,region,limit)
        if not entries then return nil,report end
        result.kinds[kind]={entries=entries,report=report}
    end
    return result
end

function Diagnostics.listEvents(cursor,limit)
    if not authoritative() then return nil,"non-authority" end
    limit=math.max(1,math.min(Diagnostics.MAX_PAGE,math.floor(finite(limit) or Diagnostics.MAX_PAGE)))
    local page,err=Events.list(cursor,limit)
    if not page then return nil,err end
    local result={schemaVersion=1,revision=page.revision,nextCursor=page.nextCursor,
        complete=page.complete==true,items={}}
    for _,record in ipairs(page.items or {}) do
        local view=eventView(record)
        if view then result.items[#result.items+1]=view end
    end
    return result
end

B47ANCEDPower.InfrastructureDiagnostics=Diagnostics
B47ANCEDPower.inspectInfrastructureSummary=Diagnostics.summary
B47ANCEDPower.inspectInfrastructureRegion=Diagnostics.inspectRegion
B47ANCEDPower.listInfrastructureEventDiagnostics=Diagnostics.listEvents
_G.B47ANCEDPower=B47ANCEDPower
return Diagnostics
