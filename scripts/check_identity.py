"""Offline identity, Lua require case, localization and source/mirror checks."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
MOD_ID = 'B47ANCEDPower'
TITLE = "B47ANCE'd Power"


def check():
    source = ROOT / 'src' / MOD_ID
    mirror = ROOT / 'Contents/mods' / MOD_ID
    errors = []

    def expect(condition, message):
        if not condition:
            errors.append(message)

    def inventory(folder):
        return {p.relative_to(folder).as_posix(): p for p in folder.rglob('*') if p.is_file()}

    sources, copies = inventory(source), inventory(mirror)
    expect(bool(sources), 'Authoritative source is missing')
    expect(sources.keys() == copies.keys(), 'Source/mirror file inventory differs')
    for name in sources.keys() & copies.keys():
        expect(sources[name].read_bytes() == copies[name].read_bytes(), 'Source/mirror bytes differ: ' + name)
    case_seen = {}
    lua_paths = {side: {p.relative_to(source / '42/media/lua' / side).as_posix()
                        for p in (source / '42/media/lua' / side).rglob('*.lua')}
                 for side in ('shared', 'client', 'server')}
    require_count = 0
    for name, path in sources.items():
        expect(name.casefold() not in case_seen, 'Case-colliding source path: ' + name)
        case_seen[name.casefold()] = name
        expect(not re.search('powerworks|powersystems', name, re.I), 'Stale source filename: ' + name)
        expect(path.suffix.lower() not in ('.java', '.jar', '.class', '.dll'), 'Non-Lua runtime binary: ' + name)
        if path.suffix.lower() not in ('.lua', '.txt', '.json', '.info'):
            continue
        text = path.read_text(encoding='utf-8-sig')
        expect(not re.search('powerworks|B47ANCEDPowerSystems|B47ANCE.D Power Systems', text, re.I), 'Stale active identity: ' + name)
        if path.suffix == '.lua':
            side = name.split('/')[3]
            for imported in re.findall(r'\brequire\s*\(?\s*["\']([^"\']+)["\']', text):
                if not imported.startswith(MOD_ID + '/'):
                    continue  # Vanilla/optional external imports are separate runtime gates.
                require_count += 1
                available = ('shared',) if side == 'shared' else ('shared', side)
                expect(any(imported + '.lua' in lua_paths[scope] for scope in available),
                       'Missing or case-wrong Lua require for ' + side + ': ' + imported)
    for tree in (source, mirror):
        metadata = dict(line.split('=', 1) for line in (tree / '42/mod.info').read_text().splitlines() if '=' in line)
        expect(metadata.get('name') == TITLE, 'Wrong public mod title: ' + str(tree))
        expect(metadata.get('id') == MOD_ID, 'Wrong technical Mod ID: ' + str(tree))
    translation_root = source / '42/media/lua/shared/Translate'
    english = {p.name: json.loads(p.read_text(encoding='utf-8-sig')) for p in (translation_root / 'EN').glob('*.json')}
    languages = sorted(p for p in translation_root.iterdir() if p.is_dir())
    for language in languages:
        for filename, fallback in english.items():
            path = language / filename
            expect(path.is_file(), 'Missing translation file: ' + str(path))
            if not path.is_file():
                continue
            # Reject duplicate JSON keys as well as incomplete fallback coverage.
            pairs = json.loads(path.read_text(encoding='utf-8-sig'), object_pairs_hook=list)
            values = dict(pairs)
            expect(len(pairs) == len(values), 'Duplicate translation keys: ' + str(path))
            expect(set(values) == set(fallback), 'Translation/fallback keys differ: ' + str(path))
            if filename == 'Sandbox.json':
                expect(values.get('Sandbox_' + MOD_ID) == TITLE, 'Wrong sandbox page title: ' + str(path))
    sandbox = (source / '42/media/sandbox-options.txt').read_text()
    for option in re.findall(r'\btranslation\s*=\s*([\w.]+)', sandbox):
        expect('Sandbox_' + option in english['Sandbox.json'], 'Missing sandbox label: ' + option)
    item_text = (source / '42/media/scripts/B47ANCEDPower_Batteries.txt').read_text()
    for item in re.findall(r'\bitem\s+(\w+)\s*\{', item_text):
        # Installed Build 42 JSON item translations use the full item type directly.
        expect(MOD_ID + '.' + item in english['ItemName.json'], 'Missing item label: ' + item)
    expect((ROOT / 'WORKSHOP_ID.txt').read_text().strip() == '3788592598', 'Existing Workshop ID changed')
    workshop = (ROOT / 'workshop.txt').read_text().splitlines()
    expect('title=' + TITLE in workshop, 'Wrong Workshop title')
    expect('visibility=public' in workshop, 'Existing Workshop visibility changed')
    print(json.dumps({'environment': 'offline source inspection; no PZ runtime',
                      'source_files': len(sources), 'mirror_files': len(copies),
                      'local_require_references': require_count,
                      'translation_languages': len(languages), 'errors': errors}, indent=2))
    return int(bool(errors))


if __name__ == '__main__':
    raise SystemExit(check())
