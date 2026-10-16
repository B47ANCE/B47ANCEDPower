# B47ANCE'd Power Master Roadmap

Canonical version: 0.16.0.

This development version implements the full B47ANCE'd Power identity rename.
See [IDENTITY_MIGRATION.md](IDENTITY_MIGRATION.md) for breaking namespace changes,
dependent-mod work, offline validation and runtime gates. Earlier feature and
validation entries below retain their original scope.

## Implemented

- Portable battery/cell definitions, persistent charge, legacy migration,
  physical multi-cell counts, atomic install/extract/replace, service locks,
  failure markers, inspection, and recovery.
- Exact energy reserve/commit/rollback transactions and mounted weapon-part
  ownership/transport.
- Dynamic and absolute consumer demand used by lightWorks world emitters.
- Source/storage/load/network registries, bounded queries, vanilla generator
  observation, and read-only infrastructure diagnostics.
- Versioned weatherWorks event ingress with persistence, deduplication, semantic
  non-mutating electrical proposals, and late-load handling.
- Appliance profiles with exact identities, measured absolute demand,
  owner-supplied logical identity, active state, multi-square deduplication, and
  order-independent quarantine of conflicting logical-load facts.
- Bounded aggregate infrastructure status snapshots for optional uiWorks panels.

## Still to add

- Measured first-party appliance profiles/native activity fixtures and foodWorks
  process consumption.
- Car-battery harnesses, stationary storage, charge limits, and health.
- Measured generator-surplus charging and verified inverter/building discharge.
- Provider-owned weather-event equipment mutation, recovery, and synchronization.
- Basement power consumer only after groundWorks topology proof.
- Verified Bulbworks energy migration support where mappings are exact.

## Validation and release gates

- Native servicing, legacy conversion, watches/packs, runtime drain/read-back,
  mounted parts, transaction recovery, inventory replication, long-duration
  balance, save/load, hosted, and dedicated servers.
