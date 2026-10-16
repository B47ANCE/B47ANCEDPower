# B47ANCE'd Power Architecture

Current authority/storage contracts and additive timestamp/retention fields are
in [AUDIT_REMEDIATION.md](AUDIT_REMEDIATION.md). Shared mutations and background
watch maintenance are server/SP owned; clients submit intent and render results.
Native packet delivery and dedicated persistence remain runtime gates.

The `0.16.0` identity change renames all project-owned namespaces without changing
the authority model, energy calculations or schema numbers. Prior identity saves
and sandbox settings are not migrated. See [IDENTITY_MIGRATION.md](IDENTITY_MIGRATION.md)
for the exact compatibility boundary and outstanding runtime gates. Versioned
sections below describe historical behavior, not current SP/dedicated validation.

`B47ANCEDPower/API.lua` owns battery, consumer, and load registries plus charge state, compatibility, installation, extraction, replacement, consumption calculation, and adapter/pack energy conversion. `Definitions.lua` owns first-party battery and device profiles. lightWorks registers devices and resolves their installed bulb; Nightfall registers UV bulbs as power loads.

Charge is stored as absolute capacity units. Adapters and taped packs transfer the consumed cells' remaining energy multiplied by configured efficiency; they never grant the output form factor free energy. `AA_PACK` and `D_PACK` are explicit external connectors and are accepted only by matching lightWorks consumers.

Version 0.7.0 stores ordinary multi-cell compartments as schema-versioned sets
bounded to 16 cells. Each entry preserves type, installation-time capacity,
absolute charge, and allowlisted B47ANCEDPower provenance. Native device charge is
the aggregate energy fraction; observation-driven discharge is reconciled
proportionally across cells before extraction. Passive reconciliation can only
remove energy. Vanilla embedded charge and 0.6.x single-cell state migrate by
preserving absolute energy, so increasing physical cell count never duplicates
charge. Explicit battery packs are one physical item and use the established
single-cell transaction.

Set installation claims every distinct input before mutation and verifies each
removal. Partial removal restores the exact item to its original container.
Extraction creates and charges the complete output set before clearing the
device; unverifiable rollback remains quarantined. Schema-2 recovery records are
currently manual-inspection only, pending an operator reconciler and in-game MP
validation.

Battery servicing checks inventory membership and native state changes, with
rollback attempts on failures. Full transactional safety is not yet established:
uncertain container operations and failed rollback still need verified repair
and reconciliation of uncertain physical items. The 0.6.4 guard blocks same-device reentry and
quarantines failed mutations; this prevents retries, not the original failure.
Replacement duration composes the registered removal and installation durations. Devices marked as requiring an access tool receive the configured kept-open discount because replacement avoids closing and reopening the compartment.
Failed physical removal or unsupported consumer methods attempt to restore native
drain values and B47ANCEDPower state. `describeConsumer` provides a nil-safe
diagnostic snapshot for lightWorks and test tooling.

Version 0.6.3 verifies charge, drain and extraction deactivation by read-back;
successful method invocation alone is insufficient. Output cells are allocated
off-inventory and assigned charge before insertion, then published after the
consumer mutation succeeds. Exact container membership verifies insertion/removal.
Improvised-cell source, composition, flag and resistance survive installation and
extraction; unrelated third-party ModData is not copied. Older installed cells
retain their stored resistance even when detailed provenance is unavailable.

Version 0.6.4 wraps public install/remove/replace in a shared authority and
per-device service guard. Ordinary clients cannot invoke these mutations. The
serializable `B47ANCEDPowerServiceRecovery` record contains mode, prior power state,
charge/storage surface and input ID when available. A clean success removes the
record; validation rejection before mutation also removes it. Failure after
mutation begins or an exception retains `inspection_required`, even if a rollback
appears to have succeeded. Replacement uses private operations inside one guard.
Timed actions reject any existing record; describeConsumer exposes a copied
diagnostic record. ModData sync is requested for success AND failure.

Version 0.6.11 adds conservative inspection and recovery endpoints; ambiguous
states deliberately remain quarantined. Do not delete a marker without
reconciling actual device state and physical cells. Native inventory packet
delivery and mounted-part ownership remain audit work.

Version 0.6.12 makes digital-watch background mutation canonical on
SP/host/server. Remote clients send only a watch item ID. The server performs a
bounded nested-inventory lookup, verifies ownership and the first-party watch
profile, rate-limits each watch to once per server minute, initializes its coin
cell, drains energy, disables empty alarms, and synchronizes item ModData.
`consumeEnergy` rejects direct remote-client and non-finite mutations.

Version 0.6.5 also claims the physical input cell in its ModData before calling
charge/ID adapters. A second device cannot service that same cell while claimed.
Success or pre-mutation validation failure releases both claims. An uncertain
failure preserves the diagnostic record on the device and input cell, preventing
reuse through a different device. No Java item references enter that record.
Input-cell ModData synchronization is requested when quarantine remains; actual
save/load and remote delivery still require in-game tests.

Extraction outputs join the same claim before inventory insertion. Runtime item
references are discarded when the synchronous service exits; IDs are recorded
when available. Success clears output markers and requests ModData sync for
outputs still present. Failed output cleanup retains the marker on any surviving
cell, preventing another public service from installing it. This blocks reuse;
it does not reconcile duplicated physical state or validate other crafting and
background mutation paths.

Version 0.6.6 centralizes carried-item ownership in `ownsServiceItem(player,item)`.
Both timed actions and public install/remove/replace require the actor's inventory
as the outermost container and verified membership in the immediate container.
Direct servicing also requires a living actor. Nested carried bags are supported;
foreign/world containers, absent items and unknown ownership fail before mutation
or quarantine.

Version 0.9.0 supplies the mounted-part boundary. A containerless consumer is
owned only when found exactly once on a weapon whose immediate and outermost
inventory ownership are verified. Timed actions serialize the parent weapon and
finite integer part ID, then re-resolve the exact part at validation and
completion. Synchronization uses `syncHandWeaponFields` because the native
packet carries the weapon's complete attachment items and their ModData; item
packets are not sent for the containerless part.

Version 0.9.1 adds an optional protected `consumptionResolver` to consumer
profiles. Its finite non-negative result composes with device, load, global,
and UV multipliers. Missing, throwing, or non-finite resolvers safely retain
baseline demand. lightWorks uses this for average pattern duty cycles while
B47ANCEDPower remains the sole owner of charge and drain application.

Version 0.6.7 centralizes loose and generated-loot conversion in
`convertLegacyBatteryInContainer(container,battery)`. Conversion preserves the
source percentage (`absolute charge / registered source capacity`), not the
absolute energy of different cell sizes. The player-facing wrapper additionally
requires ownership; conversion stays in the source container. Both paths reject
ordinary clients and existing recovery markers. Outputs receive charge before
insertion, and exact membership verifies insertion/removal. Uncertain failures
after insertion is attempted quarantine source/output without speculative deletion
or retry. Successful conversion publishes removal/addition only after verification.

Existing client-only inventory migration will no longer convert loose batteries
on multiplayer clients. An authoritative player migration/sync adapter is still
needed; server loot conversion uses the same canonical routine. Embedded-device
migration remains a separate authority audit item. No multiplayer support claim.

Version 0.6.8 preserves malformed non-table power state instead of replacing it
with an empty compartment. Queries return unavailable state rather than indexing
an invalid value. Embedded initialization and legacy migration reject existing
service recovery markers. Legacy migration records its prior state, checks drain
application, and on failure restores the prior table, attempts native drain
restoration and retains an inspection marker. Charge is not changed by this
migration. This does not finish embedded-initialization transactions, validate
every nested saved field, or resolve background multiplayer authority.

Version 0.6.9 checks embedded initialization's refresh result, restores the prior
power table on failure and retains an inspection record. Watches set their
initialized flag only after successful initialization. Maintenance preserves
malformed state and skips quarantined devices; consumeEnergy also rejects a
recovery marker. Per-item maintenance callbacks are isolated so a broken item
does not prevent later watches from updating. This is not server-side watch
authority or automatic repair; native side effects after failed initialization
still require inspection, and nested watch enumeration remains future work.

The required transaction methods were checked against the installed 42.20.3
`projectzomboid.jar`: `InventoryItem` exposes `getUseDelta`, `setUseDelta`,
`setUsedDelta`, `setActivated`, and `isActivated`; the registered vanilla
portable lights declare `UseDelta` and `ActivatedItem` in generated scripts.
Gun Light is a `base:weaponpart` but likewise declares both properties. Runtime
testing must still verify each concrete item instance before multiplayer claims.

Alarm-clock clothing is not drainable. Digital-watch charge therefore uses the
same persistent B47ANCEDPower state through the consumer's declared `modData`
storage adapter. Coin-cell depletion disables and synchronizes the alarm.
Classic watches are deliberately unregistered; the solar military watch uses
vanilla alarm-clock clothing and the digital information tag without a battery.

`IsoGenerator` exposes activation, fuel, total load, powered-item reporting, and
surrounding-electricity synchronization. It does not expose a native external
energy input. Generator-connected car batteries therefore remain behind a
future server-authoritative storage adapter; gasoline state will never be used
as disguised battery charge.

## Energy transactions

Version 0.8.0 adds a semantic reserve/commit/rollback boundary for operations
that must coordinate power with another authoritative domain. A reservation is
server-owned, identified by a bounded operation ID, stores exact before/after
energy fractions in serializable ModData, and verifies every native write by
read-back. While a reservation exists, ordinary energy consumption and power
state claims fail closed. Commit clears only a verified expected state;
rollback restores the exact prior fraction and verifies it. Any unprovable
result remains marked for inspection rather than guessing or retrying.

This contract lets waterWorks reserve pump energy before its own measured fluid
transaction and commit only after fluid succeeds. B47ANCEDPower never mutates
fluid state, and waterWorks never edits battery charge directly.

## World-present consumer demand

Version 0.10.0 adds `getConsumerEnergyRatePerHour()`. It converts the same
native ten-minute drain basis used by equipped devices into absolute stored
energy per in-game hour after device, installed-load, global, UV, pattern and
resistance multipliers. Consumer frameworks can pair that read-only rate with
B47ANCEDPower' authoritative energy mutation for loaded world-present devices.

Version 0.15.1 makes multi-square appliance aggregation fail closed when two
descriptors sharing a logical identity disagree on provider or demand. The
identity is omitted from the result and counted once as a conflict, independent
of enumeration order. Identical descriptors still deduplicate to one load.

The same patch hardens the optional aggregate-status transport: request IDs are
exact bounded integers, and client transport/validation failures explicitly
release pending state with a bounded error. A malformed response cannot lock the
uiWorks provider in a permanent loading state.

## Infrastructure provider registry

Version 0.11.0 adds bounded, provider-owned registries for electrical sources,
storage, loads, and networks. Registration requires stable provider and owner
IDs plus protected match/describe callbacks. Duplicate registration is
idempotent only for the same callbacks and owner; another provider cannot take
over an existing ID.

Descriptions normalize into read-only snapshots using watts, watt-hours, and
optional nominal voltage. Storage rejects energy above capacity; all numeric
fields reject negative, NaN, and infinite values. Provider callbacks are
isolated, ordered deterministically by priority and ID, and never exposed by
the metadata query.

Region discovery requires an explicit stable region key, passes a bounded limit
to each provider, and enforces both per-provider and combined result caps. It is
an observation boundary, not a global object scan, persistent grid simulation,
or permission to mutate provider-owned equipment. Vanilla generator adaptation,
network state, storage transactions, unloaded simulation, and electrical
consequences remain separate later layers.

The first-party vanilla generator adapter uses the loaded object's exact square
coordinates and object index as its stable observation key. It reads only
`getFuel`, `getMaxFuel`, `getCondition`, `isActivated`, `isConnected`,
`getTotalPowerUsing`, and `getGeneratorItemType`. The installed engine exposes
current native fuel/load consumption but no rated electrical output or surplus,
so these snapshots deliberately set `powerKnown=false` and publish no wattage.
They cannot authorize charging or network mutation.

## Environmental infrastructure ingress

Version 0.12.0 adds `InfrastructureEvents.lua`, an optional boundary consumed by
weatherWorks when both mods are loaded. It accepts a fixed versioned event
schema, allowlisted evidence, finite severity and world time, and an explicit
bounded region. It derives a provider-neutral consequence proposal but never
simulates weather and never mutates electrical equipment by itself.

Accepted events and stable replay IDs persist in global ModData. Exact replay
does not dispatch twice; stale stream phases fail closed. Active weatherWorks
events are caught up after the B47ANCEDPower store becomes available. Interrupted
dispatch is changed to `inspection_required` on reload rather than retried.

Each event queries the existing source, storage, load, and network registries
with hard per-kind caps. A failed provider query prevents all consequence
handlers from running for that event. Registered handlers are protected,
deterministically ordered, and receive copies of the event, proposal, and
normalized regional targets. A rejected or throwing handler marks the persisted
record for inspection. Concrete outages, equipment damage, charging changes,
and restoration remain owned by later provider-specific handlers with their own
transaction and synchronization contracts.
