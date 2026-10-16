require "TimedActions/ISBaseTimedAction"
local B47ANCEDPower=require "B47ANCEDPower/Definitions"
local Access=B47ANCEDPower.ItemAccess or require "B47ANCEDPower/ItemAccess"

B47ANCEDPower.BatteryAction=ISBaseTimedAction:derive("B47ANCEDPower_BatteryAction")
-- Build 42 reconstructs timed actions by their global Type name.
B47ANCEDPower_BatteryAction=B47ANCEDPower.BatteryAction
local function call(object,method,...)
    local args={...}
    local ok,value=pcall(function() return object[method](object,unpack(args)) end)
    if ok then return value end
end
local function owned(character,item)
    return B47ANCEDPower.ownsServiceItem(character,item)
end
local function ownedInput(character,input)
    if type(input)=="table" and input[1] then
        for _,item in ipairs(input) do if not owned(character,item) then return false end end
        return true
    end
    return input and owned(character,input)
end
local function authoritative()
    return not (type(isClient)=="function" and isClient())
        or (type(isServer)=="function" and isServer()==true)
end
function B47ANCEDPower.BatteryAction:resolveConsumer()
    if self.parentWeapon then return Access.resolveWeaponPart(self.character,self.parentWeapon,self.partId)end
    return self.consumer
end

function B47ANCEDPower.BatteryAction:isValid()
    if not self.character then return false end
    local consumer=self:resolveConsumer();if not consumer then return false end
    local data=call(consumer,"getModData")
    if type(data)=="table" and (data.B47ANCEDPowerServiceRecovery~=nil or data.B47ANCEDPowerEnergyRecovery~=nil) then return false end
    if call(self.character,"isDead")~=false or not owned(self.character,consumer) then return false end
    if self.mode=="install" or self.mode=="replace" then
        if self.battery==consumer or not ownedInput(self.character,self.battery) then return false end
    end
    if self.mode=="install" then
        if type(self.battery)=="table" and self.battery[1] and B47ANCEDPower.validateBatterySet then
            return not B47ANCEDPower.getInstalledBatteryType(consumer)
                and B47ANCEDPower.validateBatterySet(consumer,self.battery)==true
        end
        return self.battery and B47ANCEDPower.accepts(consumer,self.battery)
            and not B47ANCEDPower.getInstalledBatteryType(consumer) and (B47ANCEDPower.getCharge(self.battery) or 0)>0
    end
    if self.mode=="replace" then
        if type(self.battery)=="table" and self.battery[1] and B47ANCEDPower.validateBatterySet then
            return B47ANCEDPower.getInstalledBatteryType(consumer)~=nil
                and B47ANCEDPower.validateBatterySet(consumer,self.battery)==true
        end
        return self.battery and B47ANCEDPower.getInstalledBatteryType(consumer)~=nil
            and B47ANCEDPower.accepts(consumer,self.battery) and (B47ANCEDPower.getCharge(self.battery) or 0)>0
    end
    return self.mode=="remove" and B47ANCEDPower.getInstalledBatteryType(consumer)~=nil
end
function B47ANCEDPower.BatteryAction:update() call(self:resolveConsumer(),"setJobDelta",self:getJobDelta()) end
function B47ANCEDPower.BatteryAction:start()
    local key=self.mode=="remove" and "ContextMenu_B47ANCEDPower_RemovingBattery" or "ContextMenu_B47ANCEDPower_InstallingBattery"
    local label=type(getText)=="function" and getText(key) or key
    local consumer=self:resolveConsumer();call(consumer,"setJobType",label);call(consumer,"setJobDelta",0)
end
function B47ANCEDPower.BatteryAction:stop()
    call(self:resolveConsumer(),"setJobDelta",0)
    ISBaseTimedAction.stop(self)
end
function B47ANCEDPower.BatteryAction:perform()
    call(self:resolveConsumer(),"setJobDelta",0)
    ISBaseTimedAction.perform(self)
end
function B47ANCEDPower.BatteryAction:complete()
    if not authoritative() or self._attempted then return false end
    local checked,valid=pcall(self.isValid,self)
    if not checked or not valid then return false end
    self._attempted=true -- never retry a possibly partially mutated transaction
    local setInput=type(self.battery)=="table" and self.battery[1]
    local operation=self.mode=="install" and (setInput and B47ANCEDPower.installBatterySet or B47ANCEDPower.installBattery)
        or self.mode=="replace" and (setInput and B47ANCEDPower.replaceBatterySet or B47ANCEDPower.replaceBattery)
        or B47ANCEDPower.extractBattery
    local consumer=self:resolveConsumer();if not consumer then return false end
    local called,ok,reason=pcall(operation,self.character,consumer,self.battery)
    if not called or ok~=true then
        Access.syncConsumer(self.character,consumer,self.parentWeapon)
        local inputs=setInput and self.battery or {self.battery}
        for _,item in ipairs(inputs) do if type(syncItemModData)=="function" then pcall(syncItemModData,self.character,item) end end
        pcall(print,"[B47ANCE'd Power] Battery completion failed; inspect state before retry: "..tostring(called and reason or ok))
        return false
    end
    Access.syncConsumer(self.character,consumer,self.parentWeapon)
    return true
end
function B47ANCEDPower.BatteryAction:new(character,consumer,mode,battery,parentWeapon,partId)
    local o=ISBaseTimedAction.new(self,character)
    if not parentWeapon and consumer then parentWeapon,partId=Access.findWeaponForPart(character,consumer)end
    o.character=character;o.consumer=consumer;o.parentWeapon=parentWeapon;o.partId=partId;o.mode=mode;o.battery=battery
    if parentWeapon then o.consumer=nil end
    local resolved=o:resolveConsumer()
    o.stopOnWalk=true; o.stopOnRun=true
    if mode=="remove" then o.maxTime=B47ANCEDPower.getBatteryRemoveTime(resolved)
    elseif mode=="replace" then o.maxTime=B47ANCEDPower.getBatteryReplaceTime(resolved)
    else o.maxTime=B47ANCEDPower.getBatteryInstallTime(resolved) end
    if call(character,"isTimedActionInstant")==true then o.maxTime=1 end
    return o
end
function B47ANCEDPower.queueInstallBattery(character,consumer,battery)
    require "TimedActions/ISTimedActionQueue"
    ISTimedActionQueue.add(B47ANCEDPower.BatteryAction:new(character,consumer,"install",battery)); return true
end
function B47ANCEDPower.queueExtractBattery(character,consumer)
    require "TimedActions/ISTimedActionQueue"
    ISTimedActionQueue.add(B47ANCEDPower.BatteryAction:new(character,consumer,"remove",nil)); return true
end
function B47ANCEDPower.queueReplaceBattery(character,consumer,battery)
    require "TimedActions/ISTimedActionQueue"
    ISTimedActionQueue.add(B47ANCEDPower.BatteryAction:new(character,consumer,"replace",battery)); return true
end
return B47ANCEDPower.BatteryAction
