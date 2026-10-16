isClient=function() return false end
local api=dofile(arg[1])
api.registerBattery({item="Test.Cell",size="PACK",capacity=10})
api.registerConsumer({item="Test.Pump",sizes={"PACK"},storageMode="modData",referenceCapacity=10,baseUseDelta=.01})
local consumer={data={B47ANCEDPower={batteryType="Test.Cell",capacity=10,chargeFraction=.8,storageMode="modData",baseUseDelta=.01}}}
function consumer:getFullType()return "Test.Pump" end; function consumer:getModData()return self.data end
assert(math.abs(api.getConsumerEnergyRatePerHour(consumer)-.6)<.000001,
    "world consumers must expose absolute hourly demand from native ten-minute drain")
local ok,reservation=api.beginEnergyTransaction(consumer,3,"pump-1")
assert(ok and reservation.remaining==5 and consumer.data.B47ANCEDPower.chargeFraction==.5)
assert(api.consumeEnergy(consumer,1)==false,"pending reservation must block unrelated drain")
assert(api.getConsumerPowerState(consumer).known==false)
assert(api.rollbackEnergyTransaction(consumer,"pump-1"))
assert(consumer.data.B47ANCEDPower.chargeFraction==.8 and api.inspectEnergyRecovery(consumer)==nil)
assert(api.beginEnergyTransaction(consumer,2,"pump-2"))
assert(api.commitEnergyTransaction(consumer,"pump-2"))
assert(consumer.data.B47ANCEDPower.chargeFraction==.6 and api.inspectEnergyRecovery(consumer)==nil)
assert(api.beginEnergyTransaction(consumer,20,"too-much")==false)
print("B47ANCEDPower energy reserve/commit/rollback checks passed")
