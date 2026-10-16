local Snapshot=require "B47ANCEDPower/StatusSnapshot"
B47ANCEDPower=B47ANCEDPower or {}
local MODULE,REQUEST,RESPONSE="B47ANCEDPower","requestStatusSummary","statusSummary"
local state={nextRequestId=0,snapshot=nil,revision=0,pending=false}

function B47ANCEDPower.requestStatusSummary(player)
    if state.pending then return false,"REQUEST_PENDING" end
    state.nextRequestId=state.nextRequestId+1; state.pending=true
    if type(sendClientCommand)~="function" then state.pending=false return false,"COMMAND_UNAVAILABLE" end
    local ok=pcall(sendClientCommand,player,MODULE,REQUEST,{requestId=state.nextRequestId})
    if not ok then state.pending=false;state.error="COMMAND_FAILED";return false,state.error end
    return true,state.nextRequestId
end
function B47ANCEDPower.getClientStatusSummary() return state.snapshot,state.revision,state.pending end
local function onCommand(module,command,args)
    if module~=MODULE or command~=RESPONSE or type(args)~="table" then return end
    local requestId=tonumber(args.requestId)
    if not requestId or requestId~=requestId or requestId%1~=0 then return end
    if requestId~=state.nextRequestId then return end
    if args.error~=nil then state.pending=false; state.error=tostring(args.error):sub(1,64)
    else
        local snapshot=Snapshot.validate(args.snapshot)
        if not snapshot then
            state.pending=false;state.error="INVALID_SNAPSHOT"
            if uiWorks and type(uiWorks.markProviderDirty)=="function" then pcall(uiWorks.markProviderDirty,"B47ANCEDPower.status") end
            return
        end
        state.snapshot=snapshot; state.revision=state.revision+1; state.pending=false; state.error=nil
    end
    if uiWorks and type(uiWorks.markProviderDirty)=="function" then pcall(uiWorks.markProviderDirty,"B47ANCEDPower.status") end
end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(onCommand) end
B47ANCEDPower.receiveStatusSummary=onCommand
function B47ANCEDPower.getClientStatusError() return state.error end
return B47ANCEDPower
