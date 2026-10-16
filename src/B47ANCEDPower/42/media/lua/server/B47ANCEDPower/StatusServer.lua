local B47ANCEDPower=require "B47ANCEDPower/API"
local Snapshot=require "B47ANCEDPower/StatusSnapshot"
local MODULE,REQUEST,RESPONSE="B47ANCEDPower","requestStatusSummary","statusSummary"
local records=setmetatable({},{__mode="k"})

local function now()
    if type(getTimestampMs)=="function" then local ok,value=pcall(getTimestampMs); if ok then return tonumber(value) or 0 end end
    return 0
end
local function send(player,payload)
    if type(sendServerCommand)=="function" then pcall(sendServerCommand,player,MODULE,RESPONSE,payload) end
end
local function handle(player,args)
    if type(args)~="table" or type(args.requestId)~="number" or args.requestId~=args.requestId
        or args.requestId%1~=0 or args.requestId<1 or args.requestId>2147483647 then return false,"INVALID_REQUEST" end
    local requestId=args.requestId
    local record=records[player]; local timestamp=now()
    if record and requestId<=record.requestId then
        send(player,{requestId=requestId,snapshot=record.snapshot,cached=true}); return true,"REPLAYED"
    end
    if record and timestamp>0 and record.at>0 and timestamp-record.at<500 then
        record.requestId=requestId; send(player,{requestId=requestId,snapshot=record.snapshot,cached=true}); return true,"THROTTLED_CACHE"
    end
    local summary,reason=B47ANCEDPower.inspectInfrastructureSummary()
    if not summary then return false,reason or "SUMMARY_UNAVAILABLE" end
    local snapshot,errorCode=Snapshot.fromDiagnostics(summary)
    if not snapshot then return false,errorCode end
    records[player]={requestId=requestId,at=timestamp,snapshot=snapshot}
    send(player,{requestId=requestId,snapshot=snapshot,cached=false})
    return true,"SENT"
end
local function onCommand(module,command,player,args)
    if module~=MODULE or command~=REQUEST then return end
    local ok,accepted,reason=pcall(handle,player,args)
    if not ok or not accepted then
        local requestId=type(args)=="table" and math.floor(tonumber(args.requestId) or -1) or -1
        if requestId>=1 then send(player,{requestId=requestId,error=ok and "SUMMARY_UNAVAILABLE" or "SERVER_ERROR"}) end
        if print then print("[B47ANCE'd Power] Status summary rejected: "..tostring(ok and reason or accepted)) end
    end
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(onCommand) end
B47ANCEDPower.handleStatusSummaryRequest=handle
return B47ANCEDPower
