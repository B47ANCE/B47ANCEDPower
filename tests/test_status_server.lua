local sent={}; local tick=1000
getTimestampMs=function()return tick end
sendServerCommand=function(_,_,_,payload)sent[#sent+1]=payload end
Events={OnClientCommand={Add=function()end}}
B47ANCEDPower={inspectInfrastructureSummary=function()
    return {providers={source={count=1},storage={count=0},load={count=0},network={count=0}},events={}}
end}
package.preload["B47ANCEDPower/API"]=function()return B47ANCEDPower end
package.preload["B47ANCEDPower/StatusSnapshot"]=function()return dofile("src/B47ANCEDPower/42/media/lua/shared/B47ANCEDPower/StatusSnapshot.lua")end
dofile("src/B47ANCEDPower/42/media/lua/server/B47ANCEDPower/StatusServer.lua")
local player={}
assert(B47ANCEDPower.handleStatusSummaryRequest(player,{requestId=1})); assert(#sent==1 and not sent[1].cached)
assert(B47ANCEDPower.handleStatusSummaryRequest(player,{requestId=1})); assert(#sent==2 and sent[2].cached,"duplicate must replay cached snapshot")
tick=1100; assert(B47ANCEDPower.handleStatusSummaryRequest(player,{requestId=2})); assert(sent[3].cached,"rapid request must use cache")
assert(select(2,B47ANCEDPower.handleStatusSummaryRequest(player,{requestId=2.5}))=="INVALID_REQUEST")
assert(select(2,B47ANCEDPower.handleStatusSummaryRequest(player,{requestId=0/0}))=="INVALID_REQUEST")
print("test_status_server.lua: PASS")
