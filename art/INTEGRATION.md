# Battery asset integration evidence

Installed runtime inspected: Build 42.20.3, 2026-09-24.

`media/scripts/generated/items/drainable.txt`, Base.Battery, explicitly sets
`WorldStaticModel = Battery`. The corresponding definition in
`media/scripts/generated/models_items.txt` resolves `WorldItems/Battery` for
both mesh and texture, with scale 0.5. The mesh exists at
`media/models_X/WorldItems/Battery.fbx`. These are reference observations only;
no vanilla mesh or texture has been copied into B47ANCEDPower.

The ten B47ANCEDPower battery definitions have no WorldStaticModel declaration.
Their new models must therefore be explicitly registered and assigned per item;
adding PNG icons alone cannot complete dropped-item presentation. Use original
geometry and texture files under B47ANCEDPower-owned names. Determine scale from
actual exported bounds and native comparison, not by applying vanilla's 0.5
blindly to differently scaled geometry.

The installed inventory pane delegates icon drawing to
`ISInventoryItem.renderItemIcon` (grid and list paths), so validate the resulting
icons in both views and at their actual display size. A high-resolution master
is not proof of small-icon legibility.

The existing bootstrap helper was located relative to the character-research
project at `docs/research/B47ANCE_character_prototype/tools/Bootstrap-Blender.ps1`.
Its installed isolated interpreter is
`%LOCALAPPDATA%/B47ANCE-tools/python311/python.exe`, with Blender 4.5.3 LTS and
a working FBX exporter. No new installation was necessary.

`build_battery_geometry.py` produces ten original battery model masters under
`models/`. `verify_battery_geometry.py` imports their FBX exports and confirms
one mesh, preserved vertex/face counts, dimensions within one micrometre,
finite normalized UV coordinates, and no armature. All ten passed in the latest run;
see `geometry-validation.json`. Each export has a connected 256-square color
atlas whose file reference survives reimport. These remain basic source candidates,
not runtime-integrated or native-tested assets. All ten scripted battery types
now have source geometry; finished artwork and runtime assignment remain outstanding.
The dimension comparison verifies export consistency, not PZ placement scale.

Source-art validation commands (use the isolated Python above):

1. `B47ANCEDPower/art/test_asset_coverage.py` — eight isolated positive/negative tests.
2. `B47ANCEDPower/art/verify_battery_geometry.py` — derives battery coverage from
   the scripted drainable items, reimports every export, and records SHA-256 for
   each Blender master, FBX and albedo.
3. `B47ANCEDPower/art/check_asset_coverage.py` — rejects missing/duplicate item
   coverage, failed geometry, missing fingerprints, and changed/missing files.
   Also checks `icon-candidates.json` against all scripted battery items and
   checks each selected file's 8-bit RGBA PNG header. Rejected draft names and
   directory escapes are rejected. This is a header/selection check, not full
   image decoding, alpha-content validation or visual approval.

Latest results: 11/11 coverage tests; 10/10 model round trips; coverage/freshness
PASS; 10/10 explicitly selected icon-master headers PASS.
The fingerprint check prevents reusing an old report after an asset changes;
it does not prove artistic quality, native scale or runtime integration.

Read-only native comparison via `inspect_native_scale.py --game-root <install>`:
vanilla Battery imports into Blender with approximately 0.04195 x 0.04195 x
0.14469 bounds and a 0.0254 object scale, versus original AA bounds 0.014 x
0.014 x 0.0503. The vanilla script separately specifies scale 0.5. These
different authoring transforms are not sufficient evidence to choose a PZ scale
by a simple ratio. Native-game scale remains unverified.

The comparison also exposed nonzero object translations in original exports.
The builder now floor-anchors each mesh and bakes translation, including the
improvised cell's spacer. All ten regenerated exports pass zero-location and
floor-anchor checks within one micrometre, alongside the prior round-trip checks.
No vanilla geometry or textures were exported, copied, or modified.
