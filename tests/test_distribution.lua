Events=nil
ZombRand=function(total) return 0 end
dofile(arg[1])
local B47ANCEDPower=assert(B47ANCEDPower)
B47ANCEDPower.Config.LootWeightAAA=0; B47ANCEDPower.Config.LootWeightAA=1; B47ANCEDPower.Config.LootWeightC=0
B47ANCEDPower.Config.LootWeightD=0; B47ANCEDPower.Config.LootWeight9V=0; B47ANCEDPower.Config.LootWeightLithiumPack=0
assert(B47ANCEDPower.chooseConvertedBatteryType()=="B47ANCEDPower.BatteryAA")

local container
local function battery(fullType,delta)
    local data={}
    return {getFullType=function() return fullType end,getUsedDelta=function() return delta end,
        setUsedDelta=function(_,value) delta=value end,getModData=function() return data end,
        getContainer=function() return container end,getOutermostContainer=function() return container end}
end
local values={battery("Base.Battery",0.4)}
local items={size=function() return #values end,get=function(_,index) return values[index+1] end}
container={getItems=function() return items end}
instanceItem=function(fullType) return battery(fullType,1) end
function container:AddItem(result) values[#values+1]=result; return result end
function container:contains(target) for _,value in ipairs(values) do if value==target then return true end end return false end
function container:Remove(target) for i,value in ipairs(values) do if value==target then table.remove(values,i); return true end end return false end
assert(B47ANCEDPower.convertVanillaBatteryLoot(container)==1)
assert(#values==1 and values[1]:getFullType()=="B47ANCEDPower.BatteryAA")
assert(math.abs(B47ANCEDPower.getCharge(values[1])-1.0)<0.0001,"40% legacy charge must become 40% AA capacity")
local player={getInventory=function() return container end}
local loose=battery("Base.Battery",0.4)
values[#values+1]=loose
local ok,converted=B47ANCEDPower.convertLooseLegacyBattery(player,loose)
assert(ok and math.abs(B47ANCEDPower.getCharge(converted)-1.0)<0.0001,"loose conversion must divide absolute charge by source capacity")
local failed=battery("Base.Battery",0.2)
values[#values+1]=failed
local realRemove=container.Remove
container.Remove=function() end
local before=#values
assert(not B47ANCEDPower.convertLooseLegacyBattery(player,failed))
assert(#values==before+1 and failed:getModData().B47ANCEDPowerServiceRecovery.status=="inspection_required")
assert(values[#values]:getModData().B47ANCEDPowerServiceRecovery.status=="inspection_required")
assert(not B47ANCEDPower.convertLooseLegacyBattery(player,failed) and #values==before+1,"quarantine prevents repeated conversion outputs")
container.Remove=realRemove
local clientCell=battery("Base.Battery",0.4)
values[#values+1]=clientCell
isClient=function() return true end
assert(not B47ANCEDPower.convertLooseLegacyBattery(player,clientCell))
assert(container:contains(clientCell) and clientCell:getModData().B47ANCEDPowerServiceRecovery==nil)
isClient=function() return false end
print("B47ANCEDPower vanilla-loot conversion checks passed")
