local Snapshot=require "B47ANCEDPower/StatusSnapshot"
B47ANCEDPower=B47ANCEDPower or {}
local MODULE,REQUEST,RESPONSE="B47ANCEDPower","requestStatusSummary","statusSummary"
local TIMEOUT_MS=5000 -- Technical transport timeout, not a gameplay setting.
local state={nextRequestId=0,snapshot=nil,revision=0,pending=false}
local function now()
    if type(getTimestampMs)~="function" then return nil end
    local ok,value=pcall(getTimestampMs);value=ok and tonumber(value) or nil
    return value and value==value and math.abs(value)<math.huge and value or nil
end
local function dirty()
    if uiWorks and type(uiWorks.markProviderDirty)=="function" then pcall(uiWorks.markProviderDirty,"B47ANCEDPower.status") end
end
local function clear(reason)
    state.pending=false;state.sentAt=nil;state.error=reason
end
local function expire()
    if not state.pending then return end
    local time=now()
    if not time or time<state.sentAt or time-state.sentAt>=TIMEOUT_MS then clear("REQUEST_TIMEOUT");dirty() end
end
local function reset()
    clear("CONNECTION_RESET");state.snapshot=nil;state.revision=state.revision+1;dirty()
end
function B47ANCEDPower.requestStatusSummary(player)
    expire()
    if state.pending then return false,"REQUEST_PENDING" end
    local time=now();if not time then return false,"CLOCK_UNAVAILABLE" end
    if state.nextRequestId>=2147483647 then return false,"REQUEST_LIMIT" end
    state.nextRequestId=state.nextRequestId+1;state.pending=true;state.sentAt=time
    if type(sendClientCommand)~="function" then clear("COMMAND_UNAVAILABLE");return false,state.error end
    local ok=pcall(sendClientCommand,player,MODULE,REQUEST,{requestId=state.nextRequestId})
    if not ok then clear("COMMAND_FAILED");return false,state.error end
    return true,state.nextRequestId
end
function B47ANCEDPower.getClientStatusSummary()expire();return state.snapshot,state.revision,state.pending end
local function onCommand(module,command,args)
    expire()
    if not state.pending or module~=MODULE or command~=RESPONSE or type(args)~="table" then return end
    local id=args.requestId
    if type(id)~="number" or id~=id or id%1~=0 or id~=state.nextRequestId then return end
    if args.error~=nil then clear(tostring(args.error):sub(1,64))
    else
        local snapshot=Snapshot.validate(args.snapshot)
        if not snapshot then clear("INVALID_SNAPSHOT");dirty();return end
        if type(getText)=="function" then
            snapshot.title=getText(snapshot.title)
            for _,row in ipairs(snapshot.rows) do row.label=getText(row.label) end
        end
        state.snapshot=snapshot;state.revision=state.revision+1;clear(nil)
    end
    dirty()
end
if Events then
    if Events.OnServerCommand then Events.OnServerCommand.Add(onCommand) end
    if Events.OnDisconnect then Events.OnDisconnect.Add(reset) end
    if Events.OnConnected then Events.OnConnected.Add(reset) end
    if Events.OnTick then Events.OnTick.Add(expire) end
end
B47ANCEDPower.receiveStatusSummary=onCommand
function B47ANCEDPower.getClientStatusError()expire();return state.error end
return B47ANCEDPower
