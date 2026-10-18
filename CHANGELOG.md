# Changelog

## [0.17.0-dev.2]

- Replace the mod-list icon with the approved transparent battery artwork; preserve thumbnail bytes.
- Add reproducible existing-item Workshop staging, integrity and provenance checks.
- Prepare an explicitly authorized MP testing upload; native SP/dedicated remain NOT TESTED.
- Compatible artwork/packaging checkpoint; no gameplay, API, sandbox or save-schema changes.

## [0.17.0-dev.1]

- Development audit remediation: charge storage, authority, reservations, replication,
  watch scheduling, bounded event retention, status recovery and validation tooling.
- Add server sandbox loot controls while preserving existing defaults.
- Dedicated multiplayer NOT TESTED; stable-release G8 BLOCKED.

## [0.16.0]

- Use the user-supplied B47ANCE'd Power thumbnail for the project preview and mod
  poster, preserving the original 1254 x 1254 PNG bytes and backing up prior images.
- Rename the project to B47ANCE'd Power and its technical identity to `B47ANCEDPower`.
- Rename the Mod ID, source/package folders, Lua API and require paths, timed-action
  type, script/item/recipe namespace, sandbox keys, translation keys, state/recovery
  keys, event store, protocol channels, debug commands, and current documentation.
- Establish root `VERSION` and an explicit version inventory/checker.
- Refresh the project-local `Contents` mirror from authoritative `src` after
  preserving its previous 0.15.1 contents in a local backup.
- Breaking development change: use a fresh disposable save, reconfigure sandbox
  options, and update dependent mods. No legacy namespace or save migration is
  claimed. Gameplay calculations, authority checks and schema numbers are unchanged.
- Prior archives, checksums, artwork and historical evidence are preserved.
- Host validation does not prove SP or dedicated MP. G7 NOT TESTED / BLOCKED;
  stable-release G8 BLOCKED. No deployment or Workshop upload is part of this change.

Earlier release notes are preserved under their recorded versions in
`WORKSHOP_CHANGE_NOTE.txt`; historical packages remain in `dist`.
