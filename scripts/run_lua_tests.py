"""Run each host Lua test in an isolated Lua 5.1 VM; never launch PZ."""
import argparse
import json
from pathlib import Path
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mod-id', default='B47ANCEDPower')
    args = parser.parse_args()
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError:
        print('BLOCKED: host tests require the development-only lupa Lua 5.1 runtime.')
        return 2
    root = Path.cwd()
    mod = root / 'src' / args.mod_id / '42' / 'media' / 'lua'
    shared = mod / 'shared' / args.mod_id
    paths = {
        'api': shared / 'API.lua',
        'registry': shared / 'InfrastructureRegistry.lua',
        'events': shared / 'InfrastructureEvents.lua',
    }
    arguments = {
        'test_api.lua': [paths['api']],
        'test_appliance_profiles.lua': [paths['registry'], shared / 'ApplianceProfiles.lua'],
        'test_distribution.lua': [mod / 'server' / args.mod_id / 'Distribution.lua'],
        'test_energy_transaction.lua': [paths['api']],
        'test_infrastructure_diagnostics.lua': [paths['registry'], paths['events'], shared / 'InfrastructureDiagnostics.lua'],
        'test_infrastructure_events.lua': [paths['registry'], paths['events']],
        'test_infrastructure_registry.lua': [paths['registry']],
        'test_multicell_service.lua': [paths['api']],
        'test_translation_formatting.lua': [mod / 'shared' / 'Translate' / 'EN' / 'Sandbox.json'],
        'test_vanilla_generator_provider.lua': [paths['registry'], shared / 'VanillaGeneratorProvider.lua'],
        'test_watches_and_packs.lua': [paths['api'], shared / 'Definitions.lua', mod / 'client' / args.mod_id / (args.mod_id + '_Watches.lua')],
        'test_watch_server.lua': [mod / 'server' / args.mod_id / 'WatchServer.lua'],
    }
    failures = []
    syntax = 0
    for tree in ('src', 'Contents'):
        for path in sorted((root / tree).rglob('*.lua')):
            vm = LuaRuntime(unpack_returned_tuples=True)
            try:
                vm.execute('assert(loadfile(...))', path.as_posix())
                syntax += 1
            except Exception as exc:
                failures.append((str(path.relative_to(root)), str(exc)))
    tests = sorted((root / 'tests').glob('test_*.lua'))
    for test in tests:
        vm = LuaRuntime(unpack_returned_tuples=True)
        messages = []
        vm.globals().print = lambda *values: messages.append(' '.join(map(str, values)))
        vm.execute('package.path = ... .. ";" .. package.path', ';'.join((mod / side / '?.lua').as_posix() for side in ('shared', 'client', 'server')))
        vm.globals().arg = vm.table_from([str(p) for p in arguments.get(test.name, [])])
        try:
            vm.execute('dofile(...)', test.as_posix())
            print('PASS:', test.name, flush=True)
        except Exception as exc:
            failures.append((test.name, str(exc)))
            print('FAIL:', test.name, str(exc), flush=True)
            print('\n'.join(messages[-10:]), flush=True)
    print(json.dumps({'environment': 'Host Lua 5.1 via Lupa; no Project Zomboid runtime', 'syntax_files': syntax,
                      'test_files': len(tests), 'failures': failures}, indent=2))
    return int(bool(failures))


if __name__ == '__main__':
    sys.exit(main())
