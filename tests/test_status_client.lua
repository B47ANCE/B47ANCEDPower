local sent={}; local callback=nil; local dirty=0
sendClientCommand=function(_,_,_,args)sent[#sent+1]=args end
Events={OnServerCommand={Add=function(fn)callback=fn end}}
uiWorks={markProviderDirty=function(id)assert(id=="B47ANCEDPower.status");dirty=dirty+1 end}
B47ANCEDPower={}
package.preload["B47ANCEDPower/StatusSnapshot"]=function()return dofile("src/B47ANCEDPower/42/media/lua/shared/B47ANCEDPower/StatusSnapshot.lua")end
dofile("src/B47ANCEDPower/42/media/lua/client/B47ANCEDPower/StatusClient.lua")
assert(B47ANCEDPower.requestStatusSummary({}) and not B47ANCEDPower.requestStatusSummary({}),"only one request may be pending")
callback("B47ANCEDPower","statusSummary",{requestId=99,snapshot={schemaVersion=1}})
assert(select(3,B47ANCEDPower.getClientStatusSummary()),"stale response must be ignored")
callback("B47ANCEDPower","statusSummary",{requestId=1,snapshot={schemaVersion=1,rows={}}})
local snapshot,revision,pending=B47ANCEDPower.getClientStatusSummary()
assert(snapshot and revision==1 and not pending and dirty==1)
assert(B47ANCEDPower.requestStatusSummary({})); callback("B47ANCEDPower","statusSummary",{requestId=2,error="SUMMARY_UNAVAILABLE"})
assert(not select(3,B47ANCEDPower.getClientStatusSummary()) and B47ANCEDPower.getClientStatusError()=="SUMMARY_UNAVAILABLE","failure response must clear pending state")
assert(B47ANCEDPower.requestStatusSummary({}));callback("B47ANCEDPower","statusSummary",{requestId=3,snapshot={schemaVersion=99,rows={}}})
assert(not select(3,B47ANCEDPower.getClientStatusSummary())and B47ANCEDPower.getClientStatusError()=="INVALID_SNAPSHOT",
    "malformed matching response must release pending state")
sendClientCommand=function()error("transport failed")end
assert(not B47ANCEDPower.requestStatusSummary({})and not select(3,B47ANCEDPower.getClientStatusSummary())
    and B47ANCEDPower.getClientStatusError()=="COMMAND_FAILED","send failure must release pending state")
print("test_status_client.lua: PASS")
