package.loaded["B47ANCEDPower/TestHarness"]=nil
local output={};getFileWriter=function(name,create,append)assert(name=="theWorks Test Results - B47ANCEDPower.txt"and create and not append);output={};return{writeln=function(_,line)output[#output+1]=line end,close=function()end}end
getCore=function()return{getVersionNumber=function()return"42.20.3-test"end}end
local function newItem(kind)local item={kind=kind};function item:getFullType()return self.kind end;return item end
local inventory={items={}};function inventory:getItems()return self.items end;function inventory:AddItem(value)local item=type(value)=="string"and newItem(value)or value;self.items[#self.items+1]=item;return item end
local player={modData={}};function player:getModData()return self.modData end;function player:getInventory()return inventory end;getSpecificPlayer=function()return player end
SandboxVars={B47ANCEDPower={EnableImprovisedAdapters=true}}
local API={VERSION="0.17.0-dev.2",installBattery=function()end,getConsumerPowerState=function()end,beginEnergyTransaction=function()end,isAuthority=function()return true end}
function API.getBatteryProfile(value)return value=="B47ANCEDPower.BatteryCoin"and{}or nil end
function API.getConsumerProfile(value)return value=="Base.WristWatch_Right_DigitalBlack"and{}or nil end
package.loaded["B47ANCEDPower/Definitions"]=API;_G.B47ANCEDPower=API
local Harness=require"B47ANCEDPower/TestHarness";assert(Harness.start(true)==true);local session=player.modData["B47ANCEDPower.TestSession.V1"];assert(session.results.startup.status=="PASS")
assert(Harness.kit()==true and #inventory.items==3);assert(Harness.kit()==true and #inventory.items==3,"kit must not duplicate items")
assert(Harness.sandbox()==false and session.results.sandbox==nil);SandboxVars.B47ANCEDPower.EnableImprovisedAdapters=false;assert(Harness.sandbox()==true and session.results.sandbox.status=="PASS")
assert(Harness.reloadStatus()==false and session.results.persistence==nil);package.loaded["B47ANCEDPower/TestHarness"]=nil;Harness=require"B47ANCEDPower/TestHarness";assert(Harness.reloadStatus()==false and session.reloadObserved and session.results.persistence==nil,"reload alone cannot certify energy or inventory persistence")
for _=1,140 do Harness.auto()end;assert(#session.commands==128);assert(Harness.report()==true);local joined=table.concat(output,"\n");assert(joined:find("Mod ID: B47ANCEDPower",1,true));print("B47ANCEDPower in-game test harness checks passed")
