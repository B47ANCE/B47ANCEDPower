"""Host-only source-art coverage and freshness checks; not a release gate."""
from pathlib import Path
import hashlib
import json
import re
import struct

ROOT = Path(__file__).resolve().parent
ITEMS = ROOT.parent / 'src/B47ANCEDPower/42/media/scripts/B47ANCEDPower_Batteries.txt'


def battery_items(text):
    return {name for name, body in re.findall(r'\bitem\s+(\w+)\s*\{([^{}]*)\}', text)
            if re.search(r'\bItemType\s*=\s*base:drainable\s*,', body)}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_icons(selection, expected, source_dir):
    if selection.get('status') != 'source-candidates-not-runtime-approved':
        raise ValueError('Unexpected source icon approval state')
    icons = selection.get('icons', {})
    if set(icons) != expected:
        raise ValueError('Icon selection differs from scripted battery items')
    for name, filename in icons.items():
        if not isinstance(filename, str) or Path(filename).name != filename or 'rejected' in filename.lower():
            raise ValueError(f'{name}: unsafe or rejected icon selection')
        path = source_dir / filename
        header = path.read_bytes()[:33]
        if len(header) != 33 or header[:8] != b'\x89PNG\r\n\x1a\n' or header[12:16] != b'IHDR':
            raise ValueError(f'{name}: invalid PNG header')
        width, height, depth, color = struct.unpack('>IIBB', header[16:26])
        if width == 0 or height == 0 or depth != 8 or color != 6:
            raise ValueError(f'{name}: expected nonempty 8-bit RGBA master')
    return len(icons)


def validate(report, expected, model_dir):
    rows = report['results']
    names = [row['model'] for row in rows]
    if len(names) != len(set(names)) or set(names) != expected:
        raise ValueError('Battery coverage differs from scripted drainable items')
    for row in rows:
        name = row['model']
        if row['status'] != 'PASS':
            raise ValueError(f'{name}: geometry validation did not pass')
        files = {name + suffix for suffix in ('-v1.blend', '-v1.fbx', '-albedo.png')}
        if set(row.get('sha256', {})) != files:
            raise ValueError(f'{name}: incomplete file fingerprints')
        for filename in files:
            path = model_dir / filename
            if not path.is_file() or digest(path) != row['sha256'][filename]:
                raise ValueError(f'{name}: missing or changed {filename}; rerun geometry validation')
    return len(rows)


if __name__ == '__main__':
    report = json.loads((ROOT / 'geometry-validation.json').read_text())
    count = validate(report, battery_items(ITEMS.read_text()), ROOT / 'models')
    print(f'PASS: {count} scripted battery items have fresh validated source exports; native rendering UNVERIFIED')
    selection = json.loads((ROOT / 'icon-candidates.json').read_text())
    icons = validate_icons(selection, battery_items(ITEMS.read_text()), ROOT / 'source')
    print(f'PASS: {icons} explicitly selected RGBA icon masters; small-size/native presentation UNVERIFIED')
