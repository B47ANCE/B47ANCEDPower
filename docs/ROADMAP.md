# B47ANCE'd Power Roadmap

> Consolidated status: [MASTER_ROADMAP.md](MASTER_ROADMAP.md).

## Release validation

Version 0.8.0 adds verified energy reserve/commit/rollback transactions for
cross-domain consumers. Version 0.7.0 added versioned multi-cell state, exact-energy legacy migration,
atomic set install/extract, rollback, replacement, and physical count enforcement.
It retains the 0.6.11 public inspection and conservative resolution for quarantined
battery-service transactions. Persistent operation IDs link a failed device,
input cell, and created output without saving userdata. Recovery automatically
accepts only a verified unchanged rollback, an exact rollback output, or a
committed removal; ambiguous records remain quarantined for manual inspection.

- Validate timed insert/remove/replace flows for every lightWorks consumer.
- Validate legacy-loot conversion, both installed-cell migrations, multi-cell
  insert/remove/replace, coin-cell watches,
  solar military-watch distribution, and charge-preserving taped packs.
- Validate save/reload, hosted authority, and dedicated-server synchronization
before making multiplayer claims.

Version 0.9.0 adds mounted weapon-part ownership and timed-action transport via
the carried parent weapon and exact part ID, including stale/ambiguous rejection
and native full-attachment synchronization.

Version 0.9.1 adds dynamic consumer-demand composition for lightWorks patterns
and future cross-domain loads. Runtime drain/read-back remains an in-game gate.

## Next implementation

Version 0.10.0 exposes absolute hourly demand for world-present consumers.
lightWorks uses it for bounded dropped/placed-light drain and elapsed revisit
catch-up while preserving identical bulb and pattern costs. Dedicated-server
synchronization and long-duration runtime balance remain live validation gates.

Before expanding grid features: runtime-validate recovery and mounted-part
replication. Digital-watch background mutation is now
server-authoritative and rate-limited in 0.6.12. Version 0.6.4 adds per-device service
locking, persistent failure markers and authority for direct install/remove/replace.
Version 0.6.5 extends the claim to input/output cells, including cross-device reentry
and surviving outputs when extraction cleanup fails.
Confirm inventory/client replication in game.

1. Stable source, storage, load, and network provider registries are implemented
   in 0.11.0 with bounded region queries and normalized read-only snapshots.
2. The read-only vanilla generator source/network adapter now reports verified
   fuel, condition, activation, connection and native consumption without
   duplicating state. Output capacity and surplus remain unknown; mutation and
   charging adapters wait for a verified boundary.
3. Add car-battery harnesses, stationary storage, charge limits, and health.
4. Charge connected storage only from measured generator surplus.
5. Add inverter-backed discharge through a verified building-power adapter.
6. A bounded, authority-only, read-only infrastructure diagnostic API now
   reports provider registration, regional snapshots, event history and failure
   state without exposing callbacks or mutating provider-owned equipment.
   Coarse unloaded-chunk simulation and server commands remain blocked until
   concrete grid mutation and administration policies exist.

## Optional weatherWorks integration

Version 0.12.0 exposes a generic, versioned infrastructure-event ingress API.
weatherWorks uses it when both mods are installed, but B47ANCEDPower does not
require weatherWorks and contains no weather or disaster simulation.

B47ANCEDPower now validates and translates accepted events into non-mutating
electrical-consequence proposals: physical damage, trips and surges, shorts,
outage risk, maintenance burden, solar-generation derating, and restoration
signals. Registered power providers remain authoritative for equipment and
regions they represent. Concrete mutation handlers remain future work and must
be added only with provider-owned recovery and synchronization contracts.

The ingress is server-authoritative, bounded, persistent, idempotent, and safe
under save/reload or network replay. Stable event IDs deduplicate dispatch;
region/provider queries replace global infrastructure scans. Malformed input,
partial provider discovery, interrupted dispatch, and broken handlers fail into
inspection state without interrupting ordinary portable-power processing.

Battery energy will never be represented by mutating generator gasoline.

## Approved external-research additions

- **EXT-06 — Appliance demand profiles:** version 0.14.0 host-implements opt-in
  exact item/sprite profiles, absolute demand, owner-supplied logical identity,
  active-state evaluation, and bounded multi-square deduplication. Production
  appliance profiles still require first-party measured values and native
  identity/activity fixtures; footprint never determines load.
- **EXT-07 — Appliance actions:** expose existing energy reservation/commit/
  rollback to foodWorks-owned appliance processes and preserve recoverable
  cross-domain completion.
- **EXT-14 feasibility:** validate generator/grid behavior for any accepted
  basement topology without making B47ANCEDPower the basement owner.
- **EXT-35 support:** assist lightWorks' one-way Bulbworks migration only where
  legacy bulb/device energy state maps to a verified B47ANCEDPower profile.
- **EXT-23 support — Power status:** version 0.15.0 host-implements a replay-safe,
  per-player rate-limited aggregate status channel. It exposes provider, event,
  and failure counts only; dedicated multiplayer transport remains unverified.

These additions remain behind current runtime drain, recovery, and multiplayer
validation gates.
