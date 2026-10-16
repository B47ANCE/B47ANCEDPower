local B47ANCEDPower=dofile(arg[1])
local inventory
local function carried(value,container)
    value.getContainer=function() return container end
    value.getOutermostContainer=function() return container.root or container end
    container.items[#container.items+1]=value
    return value
end
local function item(fullType,delta,container)
    local data={}
    return {getFullType=function() return fullType end,getModData=function() return data end,
        getUsedDelta=function() return delta end,setUsedDelta=function(_,value) delta=value end,
        getContainer=function() return container end,
        getOutermostContainer=function() return container and (container.root or container) end}
end
local function consumer(fullType,delta,useDelta)
    local data={}; local active=false
    return carried({getFullType=function() return fullType end,getModData=function() return data end,
        getUsedDelta=function() return delta end,setUsedDelta=function(_,value) delta=value end,
        getUseDelta=function() return useDelta end,setUseDelta=function(_,value) useDelta=value end,
        isActivated=function() return active end,setActivated=function(_,value) active=value end,
        values=function() return delta,useDelta,active,data end},inventory)
end
local function currentUsesConsumer(fullType,delta,useDelta)
    local data={}; local active=false
    return carried({getFullType=function() return fullType end,getModData=function() return data end,
        getCurrentUsesFloat=function() return delta end,setCurrentUsesFloat=function(_,value) delta=value end,
        getUseDelta=function() return useDelta end,setUseDelta=function(_,value) useDelta=value end,
        isActivated=function() return active end,setActivated=function(_,value) active=value end,
        values=function() return delta,useDelta,active,data end},inventory)
end
local function modDataConsumer(fullType,container)
    local data={}
    return carried({getFullType=function() return fullType end,getModData=function() return data end},container)
end
B47ANCEDPower.registerBattery({item="Test.AAA",size="AAA",capacity=1.0})
B47ANCEDPower.registerBattery({item="Test.AdapterAA",size="AA",capacity=2.5,efficiency=0.82,resistance=1.25})
B47ANCEDPower.registerConsumer({item="Test.Light",sizes={"AA"},nominalCellCount=2,nominalVoltage=3.0,runtimeTargetHours=5.25})
assert(B47ANCEDPower.getConsumerProfile("Test.Light").nominalCellCount==2)
assert(B47ANCEDPower.getConsumerProfile("Test.Light").nominalVoltage==3.0)
B47ANCEDPower.registerConsumer({item="Test.SealedLight",sizes={"AA"},installTime=100,removeTime=80,accessToolRequired=true})
B47ANCEDPower.registerBattery({item="Test.Coin",size="COIN",capacity=0.25})
B47ANCEDPower.registerConsumer({item="Test.Watch",sizes={"COIN"},storageMode="modData",baseUseDelta=0.00002,referenceCapacity=0.25})
local source=item("Test.AAA",0.5)
local result=item("Test.AdapterAA",0)
assert(B47ANCEDPower.makeAdapter(source,result,"Test.AdapterAA"))
assert(math.abs(B47ANCEDPower.getCharge(result)-0.41)<0.0001,"adapter must preserve energy with efficiency loss")
assert(B47ANCEDPower.accepts("Test.Light",result))
assert(not B47ANCEDPower.accepts("Test.Light",source))
B47ANCEDPower.registerLoad({item="Test.UV",consumptionMultiplier=2.0})
B47ANCEDPower.registerConsumer({item="Test.UVLight",sizes={"AA"},drainMultiplier=1.25,loadResolver=function() return "Test.UV" end})
assert(B47ANCEDPower.getEffectiveConsumptionMultiplier("Test.UVLight")==2.5,"device and load consumption must multiply")
B47ANCEDPower.registerConsumer({item="Test.PatternLight",sizes={"AA"},drainMultiplier=2,
    consumptionResolver=function()return .25 end})
local patternMultiplier,_,dynamic=B47ANCEDPower.getEffectiveConsumptionMultiplier("Test.PatternLight")
assert(patternMultiplier==.5 and dynamic==.25,"dynamic consumer demand must compose with device drain")
B47ANCEDPower.registerConsumer({item="Test.BadDynamic",sizes={"AA"},consumptionResolver=function()error("bad provider")end})
assert(B47ANCEDPower.getEffectiveConsumptionMultiplier("Test.BadDynamic")==1,"throwing dynamic demand must fail safely to baseline")
B47ANCEDPower.Config.GlobalConsumptionMultiplier=2.0
B47ANCEDPower.Config.UVConsumptionMultiplier=3.0
assert(B47ANCEDPower.getEffectiveConsumptionMultiplier("Test.UVLight")==15.0,"sandbox consumption multipliers must compose")
B47ANCEDPower.Config.GlobalConsumptionMultiplier=1.0
B47ANCEDPower.Config.UVConsumptionMultiplier=1.0

inventory={items={}}
instanceItem=function(fullType) return item(fullType,1,inventory) end
function inventory:AddItem(created)
    self.items[#self.items+1]=created
    return created
end
function inventory:contains(target)
    for _,value in ipairs(self.items) do if value==target then return true end end
    return false
end
function inventory:Remove(target)
    for index,value in ipairs(self.items) do
        if value==target then table.remove(self.items,index); return true end
    end
    return false
end
local player={getInventory=function() return inventory end,removeFromHands=function() end,isDead=function() return false end}

local cell=item("Test.AdapterAA",0.5,inventory)
inventory.items[#inventory.items+1]=cell
local light=consumer("Test.Light",0,0.01)
assert(B47ANCEDPower.installBattery(player,light,cell)==true,"compatible charged battery should install")
local installedDelta,installedUse=light.values()
assert(math.abs(installedDelta-0.5)<0.0001,"installed relative charge must be preserved")
assert(math.abs(installedUse-0.01)<0.0001,"equal reference capacity must preserve base drain")
assert(#inventory.items==1,"successful install leaves the device and consumes exactly one physical cell")
local powerState=B47ANCEDPower.getConsumerPowerState(light)
assert(powerState.known and powerState.powered and powerState.batteryType=="Test.AdapterAA")

local publishedCharge
sendAddItemToContainer=function(_,output) publishedCharge=B47ANCEDPower.getCharge(output) end
local extracted,returned=B47ANCEDPower.extractBattery(player,light)
assert(extracted==true and returned,"installed battery should extract")
assert(math.abs(B47ANCEDPower.getCharge(returned)-1.25)<0.0001,"extracted cell must preserve absolute remaining energy")
assert(math.abs(publishedCharge-1.25)<0.0001,"publish only the final remaining charge, never factory-full charge")
local clearedDelta,restoredUse=light.values()
assert(clearedDelta==0 and math.abs(restoredUse-0.01)<0.0001,"extraction must clear charge and restore native drain")
assert(B47ANCEDPower.getInstalledBatteryType(light)==nil,"extraction must clear B47ANCEDPower state")
powerState=B47ANCEDPower.getConsumerPowerState(light)
assert(powerState.known and not powerState.powered,"empty consumers must not advertise power")

local watch=modDataConsumer("Test.Watch",inventory)
assert(B47ANCEDPower.initializeEmbeddedBattery(watch,"Test.Coin",0.5)==true,"non-drainable consumers need embedded-cell initialization")
assert(B47ANCEDPower.getInstalledBatteryType(watch)=="Test.Coin")
local consumed,watchRemaining=B47ANCEDPower.consumeEnergy(watch,0.025)
assert(consumed and math.abs(watchRemaining-0.1)<0.0001,"mod-data consumers must drain absolute stored energy")
local watchRemoved,watchCell=B47ANCEDPower.extractBattery(player,watch)
assert(watchRemoved and math.abs(B47ANCEDPower.getCharge(watchCell)-0.1)<0.0001,"mod-data consumer extraction must preserve charge")

local original=item("Test.AdapterAA",0.25,inventory)
local replacement=item("Test.AdapterAA",0.8,inventory)
inventory.items[#inventory.items+1]=original
inventory.items[#inventory.items+1]=replacement
assert(B47ANCEDPower.installBattery(player,light,original)==true,"original replacement-test cell should install")
local replaced,returnedOriginal=B47ANCEDPower.replaceBattery(player,light,replacement)
assert(replaced==true and returnedOriginal,"charged compatible cell should replace installed cell")
local replacementDelta=light.values()
assert(math.abs(replacementDelta-0.8)<0.0001,"replacement charge must become the consumer charge")
assert(math.abs(B47ANCEDPower.getCharge(returnedOriginal)-0.625)<0.0001,"replaced cell must return with its remaining energy")
assert(B47ANCEDPower.extractBattery(player,light)==true,"replacement-test consumer should cleanly extract")

local currentCell=item("Test.AdapterAA",0.6,inventory)
inventory.items[#inventory.items+1]=currentCell
local currentLight=currentUsesConsumer("Test.Light",0,0.02)
assert(B47ANCEDPower.installBattery(player,currentLight,currentCell)==true,
    "B42 current-uses consumers must accept B47ANCEDPower batteries")
local currentDelta=currentLight.values()
assert(math.abs(currentDelta-0.6)<0.0001,"current-uses charge must preserve relative state")
assert(B47ANCEDPower.extractBattery(player,currentLight)==true,"current-uses consumer battery must extract")

local legacyLight=consumer("Test.Light",0.4,0.01)
local migrated,migratedType=B47ANCEDPower.migrateInstalledLegacyBattery(legacyLight)
assert(migrated and migratedType=="Test.AdapterAA","installed legacy charge must adopt the standard sized battery")
assert(B47ANCEDPower.getInstalledBatteryType(legacyLight)=="Test.AdapterAA")
local migratedDelta=legacyLight.values()
assert(math.abs(migratedDelta-0.4)<0.0001,"installed legacy migration must preserve remaining charge")
local malformed=consumer("Test.Light",0.4,0.01)
malformed:getModData().B47ANCEDPower="unreadable existing state"
assert(not B47ANCEDPower.migrateInstalledLegacyBattery(malformed))
assert(not B47ANCEDPower.initializeEmbeddedBattery(malformed,"Test.AdapterAA",0.5))
assert(B47ANCEDPower.getInstalledBatteryType(malformed)==nil)
assert(malformed:getModData().B47ANCEDPower=="unreadable existing state")
local quarantined=consumer("Test.Light",0.4,0.01)
local marker={status="inspection_required"}
quarantined:getModData().B47ANCEDPowerServiceRecovery=marker
assert(not B47ANCEDPower.migrateInstalledLegacyBattery(quarantined))
assert(not B47ANCEDPower.initializeEmbeddedBattery(quarantined,"Test.AdapterAA",0.5))
assert(quarantined:getModData().B47ANCEDPowerServiceRecovery==marker and quarantined:getUsedDelta()==0.4)
powerState=B47ANCEDPower.getConsumerPowerState(quarantined)
assert(not powerState.known and not powerState.powered,"quarantined consumers must fail closed")
local failedMigration=consumer("Test.UVLight",0.4,0.01)
failedMigration.setUseDelta=function() end
assert(not B47ANCEDPower.migrateInstalledLegacyBattery(failedMigration))
assert(B47ANCEDPower.getInstalledBatteryType(failedMigration)==nil)
assert(failedMigration:getUsedDelta()==0.4)
assert(failedMigration:getModData().B47ANCEDPowerServiceRecovery.status=="inspection_required")
assert(not B47ANCEDPower.migrateInstalledLegacyBattery(failedMigration),"failed embedded migration must not repeat")
assert(B47ANCEDPower.getBatteryInstallTime(legacyLight)==55 and B47ANCEDPower.getBatteryRemoveTime(legacyLight)==35,
    "default battery service times must be exposed through the API")
assert(B47ANCEDPower.getBatteryReplaceTime(legacyLight)==90,
    "tool-free replacement must take the complete remove-plus-install time")
assert(B47ANCEDPower.getBatteryReplaceTime("Test.SealedLight")==162,
    "tool-assisted replacement must apply the default ten-percent kept-open bonus")

local failingContainer={root=inventory,contains=function() return true end,Remove=function() error("simulated removal failure") end}
local failedCell=item("Test.AdapterAA",0.4,failingContainer)
local failedLight=consumer("Test.Light",0,0.015)
local installed,reason=B47ANCEDPower.installBattery(player,failedLight,failedCell)
assert(installed==false and reason=="could not consume battery","failed physical removal must reject transaction")
local rollbackDelta,rollbackUse=failedLight.values()
assert(rollbackDelta==0 and math.abs(rollbackUse-0.015)<0.0001,"failed install must restore native light state")
assert(B47ANCEDPower.getInstalledBatteryType(failedLight)==nil,"failed install must restore B47ANCEDPower state")
assert(failedLight:getModData().B47ANCEDPowerServiceRecovery.status=="inspection_required")
assert(not B47ANCEDPower.installBattery(player,failedLight,failedCell),"failed mutation must not retry automatically")
-- Test fixture reset only, after verifying the mocked rollback above.
failedLight:getModData().B47ANCEDPowerServiceRecovery=nil
failedCell:getModData().B47ANCEDPowerServiceRecovery=nil

local description=B47ANCEDPower.describeConsumer(failedLight)
local realRemove=inventory.Remove
local realAdd=inventory.AddItem
local noOpCell=item("Test.AdapterAA",0.3,inventory)
inventory.items[#inventory.items+1]=noOpCell
inventory.Remove=function() end
assert(not B47ANCEDPower.installBattery(player,failedLight,noOpCell))
assert(inventory:contains(noOpCell) and B47ANCEDPower.getInstalledBatteryType(failedLight)==nil)
noOpCell:getModData().B47ANCEDPowerServiceRecovery=nil
failedLight:getModData().B47ANCEDPowerServiceRecovery=nil
inventory.Remove=realRemove
assert(B47ANCEDPower.installBattery(player,failedLight,noOpCell))
inventory.AddItem=function(_,output) return output end
assert(not B47ANCEDPower.extractBattery(player,failedLight))
assert(B47ANCEDPower.getInstalledBatteryType(failedLight)=="Test.AdapterAA","failed output insertion must not clear consumer")
failedLight:getModData().B47ANCEDPowerServiceRecovery=nil
inventory.AddItem=function(self,output) realAdd(self,output); error("inserted then threw") end
assert(B47ANCEDPower.extractBattery(player,failedLight),"verified insertion must survive a throwing wrapper without another output")
inventory.AddItem=realAdd
-- Silent native setters must not consume a battery or claim a drain succeeded.
local inertLight=consumer("Test.Light",0,0.01)
local inertCell=item("Test.AdapterAA",0.5,inventory)
inventory:AddItem(inertCell)
inertLight.setUsedDelta=function() end
assert(not B47ANCEDPower.installBattery(player,inertLight,inertCell))
assert(inventory:contains(inertCell) and B47ANCEDPower.getInstalledBatteryType(inertLight)==nil)
assert(inertCell:getModData().B47ANCEDPowerServiceRecovery.status=="inspection_required")
local untouchedLight=consumer("Test.Light",0,0.01)
assert(not B47ANCEDPower.installBattery(player,untouchedLight,inertCell),"quarantined input cannot move to another service")
assert(untouchedLight:getUsedDelta()==0 and untouchedLight:getModData().B47ANCEDPowerServiceRecovery==nil)
inertCell:getModData().B47ANCEDPowerServiceRecovery=nil -- inspected mock reset only
local resistantLight=consumer("Test.Light",0,0.01)
resistantLight.setUseDelta=function() end
inertCell:getModData().B47ANCEDPowerResistance=1.25
assert(not B47ANCEDPower.installBattery(player,resistantLight,inertCell))
assert(inventory:contains(inertCell) and resistantLight:getUsedDelta()==0)
inertCell:getModData().B47ANCEDPowerServiceRecovery=nil
local adapterLight=consumer("Test.Light",0,0.01)
inertCell:getModData().B47ANCEDPowerSource="Test.AAA"
inertCell:getModData().B47ANCEDPowerImprovised=true
assert(B47ANCEDPower.installBattery(player,adapterLight,inertCell))
local realSet=adapterLight.setUsedDelta
adapterLight.setUsedDelta=function() end
local beforeCount=#inventory.items
assert(not B47ANCEDPower.consumeEnergy(adapterLight,0.2))
assert(not B47ANCEDPower.extractBattery(player,adapterLight))
assert(#inventory.items==beforeCount and B47ANCEDPower.getInstalledBatteryType(adapterLight)=="Test.AdapterAA")
adapterLight:getModData().B47ANCEDPowerServiceRecovery=nil
adapterLight.setUsedDelta=realSet
local adapterRemoved,adapterReturned=B47ANCEDPower.extractBattery(player,adapterLight)
assert(adapterRemoved and adapterReturned:getModData().B47ANCEDPowerSource=="Test.AAA")
assert(adapterReturned:getModData().B47ANCEDPowerImprovised==true)
assert(adapterReturned:getModData().B47ANCEDPowerResistance==1.25)
assert(B47ANCEDPower.installBattery(player,adapterLight,adapterReturned))
assert(math.abs(adapterLight:getUseDelta()-0.0125)<0.000001,"reinstall must retain adapter resistance")
local realUse=adapterLight.setUseDelta
adapterLight.setUseDelta=function() end
beforeCount=#inventory.items
assert(not B47ANCEDPower.extractBattery(player,adapterLight),"no-op native drain restoration must fail extraction")
assert(#inventory.items==beforeCount and B47ANCEDPower.getInstalledBatteryType(adapterLight))
adapterLight:getModData().B47ANCEDPowerServiceRecovery=nil
adapterLight.setUseDelta=realUse
adapterLight:setActivated(true)
local realActive=adapterLight.setActivated
adapterLight.setActivated=function() end
assert(not B47ANCEDPower.extractBattery(player,adapterLight),"no-op deactivation must fail extraction")
assert(#inventory.items==beforeCount and adapterLight:isActivated())
adapterLight:getModData().B47ANCEDPowerServiceRecovery=nil
adapterLight.setActivated=realActive
assert(B47ANCEDPower.extractBattery(player,adapterLight))
local guardLight=consumer("Test.Light",0,0.01)
local guardCell=item("Test.AdapterAA",0.5,inventory)
inventory:AddItem(guardCell)
isClient=function() return true end
assert(not B47ANCEDPower.installBattery(player,guardLight,guardCell))
assert(inventory:contains(guardCell) and guardLight:getModData().B47ANCEDPowerServiceRecovery==nil)
isClient=function() return false end
local nestedResult
local otherDevice=consumer("Test.Light",0,0.01)
local otherResult
local originalSetter=guardLight.setUsedDelta
guardLight.setUsedDelta=function(self,value)
    nestedResult=B47ANCEDPower.installBattery(player,guardLight,guardCell)
    otherResult=B47ANCEDPower.installBattery(player,otherDevice,guardCell)
    originalSetter(self,value)
end
assert(B47ANCEDPower.installBattery(player,guardLight,guardCell))
assert(nestedResult==false and guardLight:getModData().B47ANCEDPowerServiceRecovery==nil)
assert(otherResult==false and otherDevice:getUsedDelta()==0)
assert(guardCell:getModData().B47ANCEDPowerServiceRecovery==nil,"successful service releases the input claim")
assert(not inventory:contains(guardCell),"reentry must not consume another battery")
guardLight.setUsedDelta=originalSetter
local countBeforeFailure=#inventory.items
guardLight:setActivated(true)
guardLight.setActivated=function() end
inventory.Remove=function() end -- output cleanup cannot be verified
assert(not B47ANCEDPower.extractBattery(player,guardLight))
assert(#inventory.items==countBeforeFailure+1)
local uncertainOutput=inventory.items[#inventory.items]
assert(uncertainOutput:getModData().B47ANCEDPowerServiceRecovery.status=="inspection_required")
assert(not B47ANCEDPower.installBattery(player,otherDevice,uncertainOutput),"uncertain output cannot be reused")
inventory.Remove=realRemove
local recoveryReport=B47ANCEDPower.inspectServiceRecovery(guardLight,{uncertainOutput})
assert(recoveryReport.status=="rollback-output-found" and recoveryReport.operationId,
    "failed extraction must expose its exact rollback output")
local recoveryResolved,resolvedReport=B47ANCEDPower.resolveServiceRecovery(player,guardLight,{uncertainOutput})
assert(recoveryResolved and resolvedReport.resolved and not inventory:contains(uncertainOutput))
assert(guardLight:getModData().B47ANCEDPowerServiceRecovery==nil,
    "verified rollback reconciliation must clear the consumer quarantine")
assert(description.consumerType=="Test.Light" and description.installedBatteryType==nil,"consumer diagnostics must be safe and complete")
local ownershipLight=consumer("Test.Light",0,0.01)
local foreign={items={},contains=inventory.contains,Remove=realRemove}
local foreignCell=item("Test.AdapterAA",0.5,foreign)
foreign.items[1]=foreignCell
assert(not B47ANCEDPower.installBattery(player,ownershipLight,foreignCell))
assert(foreign:contains(foreignCell) and ownershipLight:getUsedDelta()==0)
assert(ownershipLight:getModData().B47ANCEDPowerServiceRecovery==nil,"ownership rejection must not quarantine untouched devices")
local bag={root=inventory,items={},contains=inventory.contains,Remove=realRemove}
local nestedCell=item("Test.AdapterAA",0.5,bag)
bag.items[1]=nestedCell
local outer=ownershipLight.getOutermostContainer
ownershipLight.getOutermostContainer=function() return foreign end
assert(not B47ANCEDPower.installBattery(player,ownershipLight,nestedCell))
assert(bag:contains(nestedCell))
ownershipLight.getOutermostContainer=outer
player.isDead=function() return true end
assert(not B47ANCEDPower.installBattery(player,ownershipLight,nestedCell))
player.isDead=function() return false end
assert(B47ANCEDPower.installBattery(player,ownershipLight,nestedCell),"nested owned battery remains serviceable")
assert(not bag:contains(nestedCell))
ownershipLight.getOutermostContainer=function() return foreign end
assert(not B47ANCEDPower.extractBattery(player,ownershipLight),"foreign consumer cannot be extracted")
assert(B47ANCEDPower.getInstalledBatteryType(ownershipLight)=="Test.AdapterAA")
ownershipLight.getOutermostContainer=outer
assert(B47ANCEDPower.extractBattery(player,ownershipLight))
B47ANCEDPower.Config.EnableImprovisedAdapters=false
local disabled,disabledReason=B47ANCEDPower.makeAdapter(source,result,"Test.AdapterAA")
assert(disabled==false and disabledReason=="improvised adapters disabled")
print("B47ANCEDPower API checks passed")
