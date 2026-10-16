"""Isolated negative tests: never modify the real model assets."""
import copy
import tempfile
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_asset_coverage import battery_items, digest, validate, validate_icons


class CoverageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        hashes = {}
        for suffix in ('-v1.blend', '-v1.fbx', '-albedo.png'):
            path = self.root / ('BatteryAA'+suffix)
            path.write_bytes(b'fixture')
            hashes[path.name] = digest(path)
        self.report = {'results': [{'model': 'BatteryAA', 'status': 'PASS', 'sha256': hashes}]}

    def test_valid(self):
        self.assertEqual(validate(self.report, {'BatteryAA'}, self.root), 1)

    def test_missing_item(self):
        with self.assertRaises(ValueError):
            validate(self.report, {'BatteryAA', 'BatteryD'}, self.root)

    def test_duplicate(self):
        self.report['results'].append(copy.deepcopy(self.report['results'][0]))
        with self.assertRaises(ValueError):
            validate(self.report, {'BatteryAA'}, self.root)

    def test_changed_export(self):
        (self.root / 'BatteryAA-v1.fbx').write_bytes(b'changed')
        with self.assertRaises(ValueError):
            validate(self.report, {'BatteryAA'}, self.root)

    def test_missing_texture(self):
        (self.root / 'BatteryAA-albedo.png').unlink()
        with self.assertRaises(ValueError):
            validate(self.report, {'BatteryAA'}, self.root)

    def test_failed_geometry(self):
        self.report['results'][0]['status'] = 'FAIL'
        with self.assertRaises(ValueError):
            validate(self.report, {'BatteryAA'}, self.root)

    def test_incomplete_hashes(self):
        self.report['results'][0]['sha256'].clear()
        with self.assertRaises(ValueError):
            validate(self.report, {'BatteryAA'}, self.root)

    def test_script_selection(self):
        self.assertEqual(battery_items('item BatteryAA { ItemType = base:drainable, } '
                                      'item Magazine { ItemType = base:literature, }'), {'BatteryAA'})

    def test_rejected_icon(self):
        with self.assertRaises(ValueError):
            validate_icons({'status':'source-candidates-not-runtime-approved',
                            'icons':{'BatteryAA':'BatteryAA-rejected.png'}}, {'BatteryAA'}, self.root)

    def test_icon_coverage(self):
        with self.assertRaises(ValueError):
            validate_icons({'status':'source-candidates-not-runtime-approved','icons':{}}, {'BatteryAA'}, self.root)

    def test_icon_path_escape(self):
        with self.assertRaises(ValueError):
            validate_icons({'status':'source-candidates-not-runtime-approved',
                            'icons':{'BatteryAA':'../icon.png'}}, {'BatteryAA'}, self.root)


if __name__ == '__main__':
    unittest.main()
