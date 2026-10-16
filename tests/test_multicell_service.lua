local B47ANCEDPower=dofile(arg[1])
package.loaded["B47ANCEDPower/API"]=B47ANCEDPower

local inventory={items={}}
function inventory:AddItem(item) self.items[#self.items+1]=item; item.container=self; return item end
function inventory:Remove(item)
    for index,value in ipairs(self.items) do if value==item then table.remove(self.items,index); item.container=nil; return true end end
end
function inventory:contains(item) for _,value in ipairs(self.items) do if value==item then return true end end return false end

local nextId=1
local function battery(fullType,fraction)
    local data={}; local item={container=inventory,id=nextId}; nextId=nextId+1
    function item:getFullType() return fullType end
    function item:getModData() return data end
    function item:getUsedDelta() return fraction end
    function item:setUsedDelta(value) fraction=value end
    function item:getContainer() return self.container end
    function item:getOutermostContainer() return inventory end
    function item:getID() return self.id end
    return item
end
local function consumer()
    local data={}; local fraction,use,active=0,0.01,false
    local item={container=inventory,id=nextId}; nextId=nextId+1
    function item:getFullType() return "Test.TwoCellLight" end
    function item:getModData() return data end
    function item:getUsedDelta() return fraction end
    function item:setUsedDelta(value) fraction=value end
    function item:getUseDelta() return use end
    function item:setUseDelta(value) use=value end
    function item:isActivated() return active end
    function item:setActivated(value) active=value end
    function item:getContainer() return inventory end
    function item:getOutermostContainer() return inventory end
    function item:getID() return self.id end
    function item:values() return fraction,use,active end
    return item
end
local player={}
function player:getInventory() return inventory end
function player:isDead() return false end
function player:removeFromHands() end

B47ANCEDPower.registerBattery{item="Test.AA",size="AA",capacity=2.5}
B47ANCEDPower.registerConsumer{item="Test.TwoCellLight",sizes={"AA"},nominalCellCount=2,referenceCapacity=2.5}
package.loaded["B47ANCEDPower/CellSet"]=nil; package.loaded["B47ANCEDPower/MultiCellService"]=nil
require "B47ANCEDPower/CellSet"; require "B47ANCEDPower/MultiCellService"

instanceItem=function(fullType) return battery(fullType,1) end
local light=consumer(); local a=battery("Test.AA",1); local b=battery("Test.AA",0.5)
inventory:AddItem(light); inventory:AddItem(a); inventory:AddItem(b)
assert(not B47ANCEDPower.installBattery(player,light,a),"legacy single-cell entry point must enforce physical count")
assert(B47ANCEDPower.installBatterySet(player,light,{a,b}))
assert(not inventory:contains(a) and not inventory:contains(b))
local installed=assert(B47ANCEDPower.getInstalledCellSet(light))
local summary=assert(B47ANCEDPower.CellSet.summary(installed))
assert(summary.cellCount==2 and math.abs(summary.totalCharge-3.75)<0.000001)
local fraction,use=light:values()
assert(math.abs(fraction-0.75)<0.000001 and math.abs(use-(0.01*2.5/5))<0.000001,
    "aggregate energy must drive native fraction and capacity-adjusted drain")

light:setUsedDelta(0.375)
local removed,outputs=B47ANCEDPower.extractBattery(player,light)
assert(removed and #outputs==2 and B47ANCEDPower.getInstalledBatteryType(light)==nil)
assert(math.abs(B47ANCEDPower.getCharge(outputs[1])-1.25)<0.000001)
assert(math.abs(B47ANCEDPower.getCharge(outputs[2])-0.625)<0.000001)
assert(math.abs((B47ANCEDPower.getCharge(outputs[1])+B47ANCEDPower.getCharge(outputs[2]))-1.875)<0.000001)

local broken=consumer(); local c=battery("Test.AA",1); local d=battery("Test.AA",1)
inventory:AddItem(broken); inventory:AddItem(c); inventory:AddItem(d)
local realRemove=inventory.Remove; local removals=0
inventory.Remove=function(self,item)
    removals=removals+1
    if removals==2 then return nil end
    return realRemove(self,item)
end
assert(not B47ANCEDPower.installBatterySet(player,broken,{c,d}))
inventory.Remove=realRemove
assert(inventory:contains(c) and inventory:contains(d),"partial input removal must restore the exact cells")
assert(B47ANCEDPower.getInstalledBatteryType(broken)==nil and broken:getModData().B47ANCEDPowerServiceRecovery==nil)

local legacy=consumer(); legacy:setUsedDelta(0.5); inventory:AddItem(legacy)
assert(B47ANCEDPower.migrateInstalledLegacyBattery(legacy))
local legacySet=assert(B47ANCEDPower.getInstalledCellSet(legacy)); local legacySummary=assert(B47ANCEDPower.CellSet.summary(legacySet))
assert(#legacySet.cells==2 and math.abs(legacySummary.totalCharge-1.25)<0.000001,
    "migration must preserve the legacy absolute energy without multiplying it into two full cells")
assert(math.abs(legacy:getUsedDelta()-0.25)<0.000001,
    "native fraction must be recalibrated against aggregate two-cell capacity")

local priorCanonical=consumer(); inventory:AddItem(priorCanonical)
priorCanonical:getModData().B47ANCEDPower={batteryType="Test.AA",capacity=2.5,baseUseDelta=0.01,
    resistance=1,storageMode="usedDelta",batteryMetadata={B47ANCEDPowerSource="legacy-adapter"}}
priorCanonical:setUsedDelta(0.4)
assert(B47ANCEDPower.migrateInstalledLegacyBattery(priorCanonical))
local upgraded=assert(B47ANCEDPower.getInstalledCellSet(priorCanonical)); local upgradedSummary=assert(B47ANCEDPower.CellSet.summary(upgraded))
assert(math.abs(upgradedSummary.totalCharge-1.0)<0.000001 and math.abs(priorCanonical:getUsedDelta()-0.2)<0.000001)
assert(upgraded.cells[1].metadata.B47ANCEDPowerSource=="legacy-adapter"
    and upgraded.cells[2].metadata.B47ANCEDPowerSource==nil,"legacy provenance must not be duplicated")

print("B47ANCEDPower atomic multi-cell install/extract and rollback checks passed")
