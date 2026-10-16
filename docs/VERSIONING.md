# Project version inventory

`VERSION` is the sole canonical project version. The user approved establishing
0.16.0 for this breaking 0.x identity migration from the observed source 0.15.3.
See [VERSION_POLICY.md](VERSION_POLICY.md) and [IDENTITY_MIGRATION.md](IDENTITY_MIGRATION.md).

`version-inventory.json` enumerates source/mirror `mod.info`, `info.txt`, Lua
VERSION, README, roadmap, current handoff/testing/validation headers and Workshop
version text. `CHANGELOG.md` is the current changelog. Current Workshop notes are
prepended; older entries retain their original versions.

Minimum PZ 42.20.3, registry API/schema numbers and Blender/artwork versions are
independent of the project version. Historical packages, upload/checksum records,
asset-generation prompts, and versioned behavior/test descriptions are not
current version mirrors and must not be relabeled as new validation.

Run `python scripts/check_versions.py --root .` before and after future changes.
It checks only the declared version inventory; namespace/case/source parity and
host regressions have separate checks. Run with `--release` only against actual
authorized current artifacts in `dist/current/`. No current archive was built
for this rename, so the development check defers packaging and the release
check must fail until a current package exists. Version PASS alone cannot pass
G7 or stable-release G8.
