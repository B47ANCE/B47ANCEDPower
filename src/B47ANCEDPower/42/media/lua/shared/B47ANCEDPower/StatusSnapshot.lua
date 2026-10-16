B47ANCEDPower=B47ANCEDPower or {}
B47ANCEDPower.StatusSnapshot=B47ANCEDPower.StatusSnapshot or {}
local Snapshot=B47ANCEDPower.StatusSnapshot
Snapshot.SCHEMA_VERSION=1

local kinds={"source","storage","load","network"}
local labels={source="ContextMenu_B47ANCEDPower_Source",storage="ContextMenu_B47ANCEDPower_Storage",
 load="ContextMenu_B47ANCEDPower_Load",network="ContextMenu_B47ANCEDPower_Network",
 events="ContextMenu_B47ANCEDPower_Events",failures="ContextMenu_B47ANCEDPower_Failures"}
local function title()return "ContextMenu_B47ANCEDPower_Infrastructure" end
local function countFailures(failures)
    local count=0
    for _,entry in pairs(type(failures)=="table" and failures or {}) do
        count=count+math.max(0,math.floor(tonumber(type(entry)=="table" and entry.count) or 0))
    end
    return count
end

function Snapshot.fromDiagnostics(summary)
    if type(summary)~="table" or type(summary.providers)~="table" then return nil,"INVALID_DIAGNOSTICS" end
    local rows={}
    for _,kind in ipairs(kinds) do
        local provider=summary.providers[kind]
        rows[#rows+1]={id=kind,label=labels[kind],count=math.max(0,math.min(4096,math.floor(tonumber(provider and provider.count) or 0)))}
    end
    local events=type(summary.events)=="table" and summary.events or {}
    rows[#rows+1]={id="events",label=labels.events,count=math.max(0,math.min(100000,math.floor(tonumber(events.historyCount) or 0)))}
    rows[#rows+1]={id="failures",label=labels.failures,count=math.min(100000,countFailures(events.failures)),warning=true}
    return {schemaVersion=Snapshot.SCHEMA_VERSION,title=title(),rows=rows,actions={}}
end

function Snapshot.validate(value)
    if type(value)~="table" or value.schemaVersion~=Snapshot.SCHEMA_VERSION or type(value.rows)~="table" then
        return nil,"INVALID_SNAPSHOT"
    end
    local result={schemaVersion=Snapshot.SCHEMA_VERSION,title=tostring(value.title or title()):sub(1,128),rows={},actions={}}
    local seen={}
    for _,row in ipairs(value.rows) do
        if #result.rows>=16 then break end
        if type(row)~="table" or type(row.id)~="string" or not row.id:match("^[%w_%.%-]+$") or seen[row.id] then
            return nil,"INVALID_ROW"
        end
        local count=tonumber(row.count)
        if not count or count~=count or count<0 then return nil,"INVALID_COUNT" end
        seen[row.id]=true
        result.rows[#result.rows+1]={id=row.id,label=tostring(row.label or row.id):sub(1,64),
            count=math.min(100000,math.floor(count)),warning=row.warning==true}
    end
    return result
end

return Snapshot
