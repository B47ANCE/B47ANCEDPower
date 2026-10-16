"""Regression coverage for the twelve defects audited in 0.16.0; host Lua only."""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from lupa.lua51 import LuaRuntime

import argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
ROOT=parser.parse_args().root.resolve()
os.chdir(ROOT)
SHARED = 'src/B47ANCEDPower/42/media/lua/shared/'
CASES = {}
FAILURES = []


def run(name, code):
    vm = LuaRuntime(unpack_returned_tuples=True)
    vm.globals().print = lambda *args: None
    vm.execute('package.path = ... .. ";" .. package.path', ';'.join(
        'src/B47ANCEDPower/42/media/lua/' + side + '/?.lua' for side in ('shared', 'client', 'server')))
    vm.execute('api=require "B47ANCEDPower/Definitions"')
    try:
        value = vm.execute(code)
        CASES[name] = str(value)
        print('PASS: ' + name, flush=True)
    except Exception as exc:
        FAILURES.append(name + ': ' + str(exc))
        print('FAIL: ' + name + ': ' + str(exc), flush=True)


run('A1_server_owned_item_lookup_always_fails', '''
local root={};local item={getID=function()return 77 end,getOutermostContainer=function()return root end}
root.getItems=function()return{size=function()return 1 end,get=function()return item end}end
local player={getInventory=function()return root end}
local found,reason=api.findOwnedItemById(player,77,512)
assert(found==item,"owned-item lookup must find the actual item")
return "owned item found"
''')

run('A2_remote_context_menu_initializes_authoritative_watch_state', '''
isClient=function()return true end;isServer=function()return false end
local contextCallback
Events={OnFillInventoryObjectContextMenu={Add=function(fn)contextCallback=fn end}}
package.loaded["B47ANCEDPower/B47ANCEDPower_BatteryAction"]=true
require "B47ANCEDPower/B47ANCEDPower_Watches"
local data={}
local watch={getFullType=function()return "Base.WristWatch_Right_DigitalBlack" end,
getModData=function()return data end,getDisplayName=function()return "watch" end}
local player={getInventory=function()return{getItems=function()return{size=function()return 0 end}end}end}
getSpecificPlayer=function()return player end
local menu={addOption=function()end}
local context={getOptionFromName=function()return{subOption=1}end,getSubMenu=function()return menu end}
contextCallback(0,context,{watch})
assert(data.B47ANCEDPower==nil and data.B47ANCEDPowerWatchInitialized==nil,"remote menu cannot initialize state")
return "remote menu leaves shared charge untouched"
''')

run('A3_native_current_uses_battery_is_read_as_full', '''
local cell={getFullType=function()return "B47ANCEDPower.BatteryAA" end,
getModData=function()return{}end,getCurrentUsesFloat=function()return .2 end}
local energy=api.getCharge(cell)
assert(math.abs(energy-.5)<.000001,"native-style depleted cells must not become full")
return "20% AA returned "..energy.." energy; expected 0.5"
''')

run('A4_moddata_multicell_install_is_unreachable', '''
local root={};local data={}
local player={getInventory=function()return root end,isDead=function()return false end}
local device={getFullType=function()return "Audit.TwoCell" end,getModData=function()return data end,
getContainer=function()return root end,getOutermostContainer=function()return root end}
local a,b={},{}
for _,cell in ipairs({a,b})do
cell.getFullType=function()return "B47ANCEDPower.BatteryAA" end
cell.getModData=function()return{}end;cell.getUsedDelta=function()return 1 end
cell.getContainer=function()return root end;cell.getOutermostContainer=function()return root end
end
root.contains=function(_,item)return item==device or item==a or item==b end
api.registerConsumer{item="Audit.TwoCell",sizes={"AA"},nominalCellCount=2,storageMode="modData",baseUseDelta=.01}
local ok,reason=api.installBatterySet(player,device,{a,b})
assert(ok~=false or reason~="native battery already installed","ModData storage must not select native fraction")
return "ModData storage selected without native getter"
''')

COMMON = '''
local inventory={items={}}
function inventory:AddItem(item)self.items[#self.items+1]=item;item.container=self;return item end
function inventory:Remove(item)for i,v in ipairs(self.items)do if v==item then table.remove(self.items,i);item.container=nil;return end end end
function inventory:contains(item)for _,v in ipairs(self.items)do if v==item then return true end end return false end
local function item(kind,fraction)
local data={};local object={container=inventory}
function object:getFullType()return kind end;function object:getModData()return data end
function object:getUsedDelta()return fraction end;function object:setUsedDelta(v)fraction=v end
function object:getContainer()return self.container end;function object:getOutermostContainer()return inventory end
return object
end
local function consumer(kind)
local device=item(kind,0);local use=.01;local active=false
function device:getUseDelta()return use end;function device:setUseDelta(v)use=v end
function device:isActivated()return active end;function device:setActivated(v)active=v end
inventory:AddItem(device);return device
end
local player={getInventory=function()return inventory end,isDead=function()return false end,removeFromHands=function()end}
instanceItem=function(kind)return item(kind,1)end
'''

run('A5_multi_cell_install_omits_remove_replication', COMMON + '''
api.registerConsumer{item="Audit.Light",sizes={"AA"},nominalCellCount=2}
local device=consumer("Audit.Light");local a=item("B47ANCEDPower.BatteryAA",1);local b=item("B47ANCEDPower.BatteryAA",1)
inventory:AddItem(a);inventory:AddItem(b)
local packets=0;sendRemoveItemFromContainer=function()packets=packets+1 end
assert(api.installBatterySet(player,device,{a,b}))
assert(not inventory:contains(a)and not inventory:contains(b)and packets==2)
return "two committed input removals publish two removal requests"
''')

run('A6_service_can_mutate_pending_energy_reservation', COMMON + '''
api.registerConsumer{item="Audit.OneCell",sizes={"AA"},nominalCellCount=1}
local device=consumer("Audit.OneCell");local a=item("B47ANCEDPower.BatteryAA",1);inventory:AddItem(a)
assert(api.installBattery(player,device,a))
assert(api.beginEnergyTransaction(device,.5,"audit-reservation"))
local extracted,cell=api.extractBattery(player,device)
assert(not extracted and api.inspectEnergyRecovery(device)~=nil,"servicing must reject pending energy reservation")
assert(api.rollbackEnergyTransaction(device,"audit-reservation"))
assert(device:getUsedDelta()==1 and api.getInstalledBatteryType(device)~=nil)
return "energy reservation excludes servicing and rolls back without creating energy"
''')

run('A7_event_store_auxiliary_maps_are_unbounded', '''
local events=api.InfrastructureEvents;local store={};assert(events.attachStore(store))
for i=1,400 do
assert(events.ingest{schemaVersion=1,id="audit-event-"..i,occurrenceId="audit-occurrence-"..i,
source="audit",type="high_wind",phase="started",severity=.5,worldAgeHours=i,
region={key="region-"..i},evidence={windPower=.5}})
end
local processed,streams=0,0;for _ in pairs(store.processed)do processed=processed+1 end
for _ in pairs(store.latestByStream)do streams=streams+1 end
assert(#store.history==256 and processed<=256 and streams<=256,"persistent replay maps must be bounded")
return "history=256, processed="..processed..", latestByStream="..streams.." after 400 distinct regions"
''')

run('A8_multi_cell_migration_runs_on_remote_client', COMMON + '''
api.registerConsumer{item="Audit.LegacyTwoCell",sizes={"AA"},nominalCellCount=2,referenceCapacity=2.5}
local device=consumer("Audit.LegacyTwoCell");device:setUsedDelta(.5)
isClient=function()return true end;isServer=function()return false end
assert(not api.migrateInstalledLegacyBattery(device),"remote migration must reject")
assert(api.getInstalledCellSet(device)==nil and device:getUsedDelta()==.5)
return "remote migration rejects without mutation"
''')

run('A9_status_timeout_and_reconnect', r'''
local clock=100;getTimestampMs=function()return clock end
local connected,disconnected
Events={OnServerCommand={Add=function()end},OnConnected={Add=function(fn)connected=fn end},OnDisconnect={Add=function(fn)disconnected=fn end}}
sendClientCommand=function()end
local status=require "B47ANCEDPower/StatusClient"
assert(status.requestStatusSummary({}))
clock=clock+6000
assert(not select(3,status.getClientStatusSummary()),"lost response must time out")
assert(status.requestStatusSummary({}));assert(type(disconnected)=="function");disconnected()
assert(not select(3,status.getClientStatusSummary()));assert(status.requestStatusSummary({}))
assert(type(connected)=="function");connected()
assert(not select(3,status.getClientStatusSummary()))
return "timeout and lifecycle recovery"
''')

run('A10_watch_server_scheduler_root_nested_and_no_requests', COMMON + r'''
isClient=function()return false end;isServer=function()return true end
local minute=600;getGameTime=function()return{getWorldAgeHours=function()return minute/60 end}end
local callback;Events={EveryOneMinute={Add=function(fn)callback=fn end},OnClientCommand={Add=function()end}}
function inventory:getItems()return{size=function()return #self.items end,get=function(_,i)return self.items[i+1]end}end
getOnlinePlayers=function()return{size=function()return 1 end,get=function()return player end}end
local watch=item("Base.WristWatch_Right_DigitalBlack",1);watch.getID=function()return 77 end;inventory:AddItem(watch)
require "B47ANCEDPower/WatchServer"
callback();local before=watch:getModData().B47ANCEDPower
assert(before and before.batteryType,"server must discover and initialize watches without client requests")
local energy=before.chargeFraction*.25
minute=minute+2;callback()
assert(math.abs(before.chargeFraction*.25-(energy-2*api.Config.DigitalWatchDrainPerMinute))<.000000001,"elapsed server minutes must drain exactly once")
local after=before.chargeFraction;callback();assert(before.chargeFraction==after,"duplicate callbacks must not double-drain")
return "server schedules canonical consumption"
''')

with tempfile.TemporaryDirectory(prefix='b47power-fixed-runner-') as folder:
    result = subprocess.run([sys.executable, str(ROOT / 'scripts/run_lua_tests.py')], cwd=folder, capture_output=True, text=True)
    try:
        start=result.stdout.rfind('\n{')
        summary=json.loads(result.stdout[start+1:] if start>=0 else result.stdout)
        assert result.returncode==0 and summary['test_files']>=19 and summary['syntax_files']>=42, (result.returncode,summary)
        CASES['A11_runner_root']='runner finds actual project from another working directory'
        print('PASS: A11_runner_root')
    except Exception as exc:
        FAILURES.append('A11_runner_root: '+str(exc));print('FAIL: A11_runner_root: '+str(exc))

run('A12_moddata_consumer_reads_inherited_native_fraction', '''
local data={};local watch={getFullType=function()return "Base.WristWatch_Right_DigitalBlack" end,
getModData=function()return data end,getCurrentUsesFloat=function()return 1 end}
assert(api.initializeEmbeddedBattery(watch,"B47ANCEDPower.BatteryCoin",.2))
assert(data.B47ANCEDPower.chargeFraction==.2)
local power=api.getConsumerPowerState(watch)
assert(power.chargeFraction==.2,"declared ModData mode must beat inherited generic getters")
assert(api.consumeEnergy(watch,.01))
assert(math.abs(data.B47ANCEDPower.chargeFraction-.16)<.000001,"consumption must decrease energy")
return "20% modData watch reads 100% native fraction; consuming 0.01 raises stored fraction to 96%"
''')

print(json.dumps({'passed':len(CASES),'failed':FAILURES},indent=2))
raise SystemExit(int(bool(FAILURES)))
