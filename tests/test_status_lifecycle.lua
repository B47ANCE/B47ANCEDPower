local clock=100;getTimestampMs=function()return clock end
local connected,disconnected,tick
Events={OnServerCommand={Add=function()end},OnConnected={Add=function(fn)connected=fn end},
OnDisconnect={Add=function(fn)disconnected=fn end},OnTick={Add=function(fn)tick=fn end}}
sendClientCommand=function()end
local Power=require "B47ANCEDPower/StatusClient"
assert(Power.requestStatusSummary({}))
clock=5100;tick()
assert(not select(3,Power.getClientStatusSummary()) and Power.getClientStatusError()=="REQUEST_TIMEOUT")
assert(Power.requestStatusSummary({}))
Power.receiveStatusSummary("B47ANCEDPower","statusSummary",{requestId=1,snapshot={schemaVersion=1,rows={}}})
assert(select(3,Power.getClientStatusSummary()),"late timed-out response cannot satisfy a newer request")
disconnected();assert(not select(3,Power.getClientStatusSummary()))
Power.receiveStatusSummary("B47ANCEDPower","statusSummary",{requestId=2,snapshot={schemaVersion=1,rows={}}})
assert(Power.getClientStatusSummary()==nil,"disconnected/stale replies cannot restore old UI state")
assert(Power.requestStatusSummary({}));connected();assert(not select(3,Power.getClientStatusSummary()))
getTimestampMs=nil
assert(not Power.requestStatusSummary({}),"missing clock must not create an unexpiring request")
print("Status timeout, late replies, disconnect/reconnect and unavailable clock checks passed")
