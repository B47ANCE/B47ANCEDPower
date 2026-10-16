local Power=require "B47ANCEDPower/API"
local root,bag,foreign={},{},{}
local function list(values)return{size=function()return #values end,get=function(_,i)return values[i+1]end}end
local watch={getID=function()return 42 end,getOutermostContainer=function()return root end}
local nested={getInventory=function()return bag end,getOutermostContainer=function()return root end}
local foreignItem={getID=function()return 99 end,getOutermostContainer=function()return foreign end}
root.getItems=function()return list({foreignItem,nested})end
bag.getItems=function()return list({watch,nested})end -- deliberately cyclic bag reference
local player={getInventory=function()return root end}
assert(Power.findOwnedItemById(player,42)==watch)
assert(Power.findOwnedItemById(player,99)==nil)
assert(Power.findOwnedItemById(player,42,1)==nil)
assert(Power.findOwnedItemById(player,math.huge)==nil and Power.findOwnedItemById(player,1.5)==nil)
local ok,report=Power.visitOwnedInventory(player,function()end,512)
assert(ok and report.visited==4 and not report.truncated,"cycles cannot create repeated container scans")
print("Bounded root/nested lookup, foreign rejection, cyclic containers and malformed IDs passed")
