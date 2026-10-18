# B47ANCE'd Power

B47ANCE'd Power is a standalone portable-power framework for Project Zomboid.

- Version: `0.17.0-dev.2`
- Mod ID: `B47ANCEDPower`
- Author: B47ANCE
- Minimum game version: `42.20.3`
- Dependencies: none

Project thumbnail: user-supplied B47ANCE'd Power artwork selected 2026-10-16.
The authoritative image is `src/B47ANCEDPower/thumbnail.png`; `preview.png` and
`Contents/mods/B47ANCEDPower/thumbnail.png` contain the same original PNG bytes.
The existing `poster=thumbnail.png` reference is retained. The separate mod-list
icon is the approved transparent battery cutout; its original RGBA master is
`art/source/ModIcon-v1.png`. No thumbnail bytes were changed.

The earlier `0.16.0` identity change was a breaking development rename. Enable `B47ANCEDPower`, use a
fresh disposable save, and reconfigure its sandbox options. Dependent mods must
update their dependency declarations, Lua imports, globals, item references and
protocol calls before integration testing. There are no legacy aliases or save
migration for the previous identity. See [the rename and compatibility record](docs/IDENTITY_MIGRATION.md).

`VERSION` is the canonical project version. Current mirrors are declared in
`version-inventory.json`; the policy is [docs/VERSION_POLICY.md](docs/VERSION_POLICY.md).
G7 dedicated multiplayer is **NOT TESTED / BLOCKED**; stable-release G8 is **BLOCKED**.

## Current audit repairs

This development iteration repairs charge storage, transaction exclusion,
server-owned watch scheduling, inventory synchronization, bounded event retention
and status recovery. See [the remediation record](docs/AUDIT_REMEDIATION.md) for
contracts and offline evidence, and [runtime validation](docs/RUNTIME_VALIDATION.md)
for the outstanding SP/dedicated checks. The suite includes 25 Lua regression
files plus 12 targeted audit scenarios; passing mocks is not native runtime proof.

Public source: [B47ANCE/B47ANCEDPower](https://github.com/B47ANCE/B47ANCEDPower).
The audit fixes were merged through PR #1. The initial main commit
preserves the historical 0.16.0 development baseline with its known audit defects.

## Features

- Public battery and powered-device registration APIs.
- Public load profiles; device and installed-load multipliers compose into one authoritative consumption rate.
- Public absolute hourly-demand queries for authoritative world-present devices.
- Opt-in appliance profiles with exact item/sprite allowlists, absolute declared
  watts, owner-supplied logical identity, active-state evaluation, and bounded
  multi-square deduplication; footprint never determines load.
- Bounded public source, storage, load, and network provider registries with
  normalized SI-unit snapshots and region-scoped discovery.
- A replay-safe, per-player rate-limited status channel publishes only bounded
  aggregate infrastructure and failure counts for optional uiWorks presentation.
- A read-only vanilla generator adapter reports verified loaded-object fuel,
  condition, connection, activation, and native consumption while explicitly
  leaving electrical output capacity unknown.
- Optional, server-authoritative environmental-event ingress validates and
  persists weatherWorks events, derives provider-neutral consequence proposals,
  discovers only bounded regional infrastructure, deduplicates replay, and
  isolates failed provider and consequence callbacks. It does not simulate
  weather or mutate equipment without a separately registered owner handler.
- AAA, AA, C, D, 9V, rechargeable pack, and vanilla compatibility profiles.
- Coin cells, charge-preserving taped AA/D packs, and solar military watches.
- Persistent absolute charge rather than interchangeable percentages.
- Capacity-aware device drain and safe insertion/extraction transactions.
- Learned AAA + paperclip to improvised-AA adapter recipe.
- Improvised cells preserve source energy while losing efficiency and increasing resistance.
- Digital watches use replaceable coin cells; classic watches remain mechanical.
- Battery insertion, removal, and replacement use timed transactional actions. Replacement takes the combined removal and installation time; tool-access devices receive a configurable 10% kept-open bonus.
- Failed battery-service mutations receive stable operation IDs and can be inspected through the public recovery API. Verified rollbacks remove only outputs belonging to that operation; ambiguous state remains quarantined for manual review.
- Consumer profiles enforce nominal cell counts through versioned installed-cell
  sets. Ordinary cells retain independent type, charge, capacity, and selected
  provenance; explicit taped packs remain one inventory item.
- Atomic set installation/extraction, complete-set replacement, exact-energy
  migration from vanilla charge and 0.6.x states, and bounded best-set selection.
- Server-authoritative energy reservations with explicit commit/rollback,
  read-back verification, and persistent recovery records for cross-domain work.
- Mounted weapon-part consumers use parent-weapon ownership, stable numeric part
  identity, completion-time reconstruction, and full attachment-field sync;
  stale, replaced, duplicate, foreign, and detached parts fail closed.

B47ANCE'd Power owns batteries, power state, and consumption calculation.
lightWorks and Nightfall integrate with its public API; their separate projects
still need the dependency and namespace changes described in the compatibility
record. They have not been changed or tested as part of this local rename.

Generator-connected storage is not yet a shipped gameplay feature. Build 42's
generator API exposes fuel and current load but no native external-storage input;
B47ANCE'd Power will add that through a server-authoritative storage/network adapter
after the connection, charging, discharge, and synchronization spikes pass.

The authoritative mod root is `src/B47ANCEDPower/` (runtime files under `42/`).
`Contents/mods/B47ANCEDPower/` is an exact project-local mirror refreshed during
this rename. Historical packages and staging backups in `dist/` retain their
original names, content and hashes. Current test-distribution artifacts are generated under ignored `dist/current/`
and `dist/workshop-<version>/` by `python scripts/prepare_workshop.py`;
`--verify` checks exact source/stage/ZIP hashes and provenance. The uploader uses
the staged `Contents/` directory and preserves the existing Workshop preview.
See [the icon and distribution record](docs/ICON_RELEASE.md).

Run `python tests/test_audit_regressions.py`,
`python scripts/check_versions.py --root .`,
`python scripts/check_identity.py`, and `python scripts/run_lua_tests.py`
(the latter requires the development-only `lupa.lua51` host runtime).
Run `python art/test_asset_coverage.py` and `python art/check_asset_coverage.py`
for the existing source-art checks. These commands do not launch Project Zomboid.
