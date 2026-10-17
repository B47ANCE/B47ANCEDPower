local Power=require "B47ANCEDPower/Definitions"
local root={items={}};local sequence=0
function root:contains(item)for _,v in ipairs(self.items)do if v==item then return true end end return false end
function root:AddItem(item)self.items[#self.items+1]=item;item.container=self;return item end
function root:Remove(item)for i,v in ipairs(self.items)do if v==item then table.remove(self.items,i);item.container=nil;return end end end
local function item(kind)
 sequence=sequence+1;local data={};local fraction=1
 local value={id=sequence,container=root,getFullType=function()return kind end,getModData=function()return data end,
 getCurrentUsesFloat=function()return fraction end,setCurrentUsesFloat=function(_,v)fraction=v end,
 getOutermostContainer=function()return root end}
 function value:getContainer()return self.container end
 function value:getID()return self.id end
 return value
end
local player={getInventory=function()return root end,isDead=function()return false end}
Power.registerConsumer{item="Fixture.ModDataSet",sizes={"AA"},nominalCellCount=2,storageMode="modData",baseUseDelta=.01}
local device=item("Fixture.ModDataSet");root:AddItem(device)
local a,b=item("B47ANCEDPower.BatteryAA"),item("B47ANCEDPower.BatteryAA");root:AddItem(a);root:AddItem(b)
Power.setCharge(a,1);Power.setCharge(b,.5)
local removals,additions=0,0
sendRemoveItemFromContainer=function(_,cell)assert(cell==a or cell==b);removals=removals+1 end
sendAddItemToContainer=function()additions=additions+1 end
assert(Power.installBatterySet(player,device,{a,b}))
assert(removals==2 and not root:contains(a) and not root:contains(b))
assert(math.abs(device:getModData().B47ANCEDPower.chargeFraction-.3)<.000001)
assert(Power.beginEnergyTransaction(device,.5,"set-reservation"))
assert(not Power.extractBatterySet(player,device))
assert(not Power.migrateInstalledLegacyBattery(device))
assert(Power.rollbackEnergyTransaction(device,"set-reservation"))
instanceItem=item
local ok,cells=Power.extractBatterySet(player,device)
assert(ok and #cells==2 and additions==2)
assert(math.abs(Power.getCharge(cells[1])+Power.getCharge(cells[2])-1.5)<.000001)
assert(Power.getInstalledBatteryType(device)==nil)
print("ModData cell-set conservation, energy locks and exact remove/add packets passed")
