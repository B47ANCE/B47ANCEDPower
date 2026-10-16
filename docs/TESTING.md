# B47ANCE'd Power Testing

Project Version: 0.16.0

## 0.16.0 identity rename

Use `python scripts/check_versions.py --root .`, `python scripts/check_identity.py`,
and `python scripts/run_lua_tests.py` for version consistency, source/mirror and
namespace validation, and the 19 isolated host Lua regression files. The Lua
runner uses development-only Lupa Lua 5.1 and compiles all production Lua files;
it never launches the game. Source-art checks remain `python art/test_asset_coverage.py`
and `python art/check_asset_coverage.py`.

Current evidence is recorded in [IDENTITY_MIGRATION.md](IDENTITY_MIGRATION.md).
Earlier versioned sections below are historical descriptions. They do not prove
that the renamed build works in SP or dedicated multiplayer.

Runtime tests must use a fresh disposable save, the new Mod ID and sandbox
namespace, then cover item creation, battery servicing, save/reload, reconnect,
late join, simultaneous requests and server restart. Dependent mods need their
own identity updates before combined-stack testing. G7 NOT TESTED / BLOCKED;
stable-release G8 BLOCKED.

## 0.14.0 appliance demand profiles

Host tests prove exact sprite matching, absolute wattage, active/off demand,
two-square logical deduplication, unknown-object exclusion, malformed identity
failure, bounded enumeration, and rejection of profiles without a declared
demand. No production appliance wattage is claimed. Each future profile needs
measured provenance plus in-game identity, rotation, multi-square, activation,
streaming, save/reload, hosted and dedicated validation.

Version 0.15.1 adds both forward- and reverse-order conflict cases. When two
squares sharing one logical identity disagree about active demand, neither is
returned as billable and the bounded report records one failure.

## 0.8.0 energy transaction contract

Host tests reserve exact consumer energy, verify the pending recovery marker,
reject ordinary consumption while reserved, commit the expected charge, and
restore the exact pre-operation charge on rollback. Cross-domain waterWorks
coverage proves a rejected native fluid transfer rolls back earlier pump-energy
reservations and clears their recovery records. In game, repeat across save/
reload and hosted/dedicated authority before claiming multiplayer support.

## 0.7.0 multi-cell service

Host tests cover two-cell validation, distinct-item enforcement, battery-pack
single-unit behavior, proportional discharge reconciliation, atomic input
rollback, complete extraction, and absolute-energy migration from vanilla and
0.6.x installed state. In game, exercise 2×AA, 2×D, 1×AAA, taped packs, mixed
charge, replace, interruption, save/reload, mounted weapon lights, and hosted/
dedicated authority. Inspect schema-2 failures manually; multiplayer remains
unverified.

## 0.6.12 authoritative watch maintenance

Host coverage proves remote clients request rather than mutate watch charge,
the server resolves only owned item IDs through a bounded nested-inventory walk,
rejects non-watch/quarantined inputs, initializes once, drains once per server
minute, and synchronizes the item. In game, repeat with two clients carrying
root and nested watches; confirm no double drain, free initialization, or alarm
desynchronization across save/reload.

## 0.6.11 service recovery

Failed direct install/remove/replace mutations now persist a stable operation ID.
`inspectServiceRecovery` classifies unchanged rollback state, exact surviving
rollback outputs, committed removals, and ambiguous records. The authoritative
`resolveServiceRecovery` path removes only a verified rollback output and clears
only markers from the same operation. Host failure injection covers cleanup that
silently refuses removal, exact output discovery, reconciliation, and quarantine
release. Save/reload discovery, real item IDs, packet replication, and concurrent
hosted clients remain in-game gates; ambiguous state is deliberately not repaired.

## 0.6.10 consumer power-state contract

`getConsumerPowerState` reports a registered consumer as powered only from a
readable positive charge value. Empty cells report known/unpowered; malformed,
unknown-cell, unavailable-charge, and service-quarantined states fail closed as
unknown/unpowered. Legacy native charge remains readable until migration. Host
tests cover installed, empty and quarantined devices; mounted parts and native
drain-to-zero transitions remain in-game gates.

## 0.6.9 watch initialization and isolation

Host watch tests preserve malformed state without falsely setting initialized,
inject a throwing refresh and verify rollback/quarantine, reject energy mutation
on quarantine, and run the minute callback with a broken watch before a valid
one to verify continued processing. Existing depleted-alarm and mechanical-watch
tests still pass. Native alarm behavior, save/reload and multiplayer remain open.

## 0.6.8 embedded migration

Host API tests preserve malformed stored power state, reject initialization and
migration on quarantined devices, detect silent drain-setter failure, retain
legacy charge and prior power state, and reject repeated failed migration. Test
real saved-device reloads and recovery-marker persistence in game. Nested saved
field validation and background server migration remain outstanding.

## 0.6.7 legacy conversion

Host distribution tests exercise the real conversion API: 40% vanilla charge
becomes 40% AA charge in both loot and loose-item paths, failed source removal
quarantines both objects, retries create no further output, and client calls
leave the source unchanged. In-game checks must cover non-default capacity
settings, nested containers, conversion packets and saved quarantine records.
Multiplayer player-inventory migration still needs an authoritative adapter;
client-side loose conversion is deliberately rejected rather than locally mutating.

## 0.6.6 ownership boundary

Host tests reject foreign batteries, foreign consumers and dead actors through
the public API; reject extracting a foreign consumer without changing its cell;
and accept a battery in a nested carried bag. Timed actions delegate ownership
to the same helper. Rejections occur before recovery markers are created.
In-game nested/equipped/container-transfer and server ownership tests remain open.

## 0.6.5 input-cell claims

Host API tests attempt nested installation of the SAME cell into a different
device, verify the second device remains empty, and verify success clears the
input claim. A failed mutated installation leaves the cell quarantined and rejects
installation into another device. Explicit test fixture resets are not gameplay
repair. Test persistence and remote synchronization of both markers in game.
An additional host test forces extraction deactivation AND output cleanup to fail;
the surviving output is quarantined and cannot be installed in a second device.

## 0.6.4 service guard

Host tests reject direct client servicing and nested same-device calls, verify
success clears the record, and verify failed mutated operations retain a marker
and reject retries. Timed-action validity rejects quarantined devices. Fixture
resets in test_api.lua are explicit mock-only resets after state assertions;
there is no gameplay command that blindly clears recovery markers.

Still required in game: save/reload a quarantined test device, confirm the marker
survives and remote clients see it, then inspect inventory/device state manually.
This is not proof of automatic recovery or protection from every duplication path.

## 0.6.3 regression increment

Host API tests cover no-op AddItem/Remove, throwing-after-insertion wrappers,
final-charge publication, no-op charge/drain/deactivation setters, output cleanup
on known extraction failure, and improvised-cell provenance/resistance round-trip.
These checks do not prove rollback when membership queries themselves fail or
when cleanup fails. Output reconciliation, recovery tooling, background mutation
authority and mounted-part ownership remain outstanding.

In game: install a partially charged improvised AA, remove/reinstall it twice,
and verify retained charge and drain penalty. Remove from an activated light;
confirm it turns off and returns exactly one cell. Repeat after save/reload.

## In-game coverage

Use the guided stage harness in [IN_GAME_TESTING.md](IN_GAME_TESTING.md).
Mocked harness execution is not an in-game PASS.

1. Confirm B47ANCEDPower loads independently; confirm lightWorks refuses an incomplete installation and loads after required B47ANCEDPower without errors.
2. Insert and replace every accepted cell in its registered light; hide insertion while occupied and reject incorrect or empty cells.
3. Time replacement: tool-free devices use removal plus installation; tool-access devices use that sum minus the configured kept-open bonus (10% by default).
3. Confirm charge and drain survive extraction, nesting, attachment, save, and reload.
4. Confirm empty cells are returned, cannot power a light, and never create free energy.
5. Read the adapter magazine and craft AAA + paperclip into improvised AA.
6. Confirm improvised AA contains 82% of the AAA's remaining energy, drains less efficiently, and fits AA devices.
7. Repeat insertion and extraction in hosted and dedicated multiplayer before claiming compatibility.
8. Force a source-container removal failure and confirm the light's charge,
   native `UseDelta`, and B47ANCEDPower state all roll back without item loss.
9. Confirm lightWorks' installed-battery submenu resolves its label through
   B47ANCEDPower and never breaks the rest of the inventory context menu.
10. Craft taped AA and D packs from partially charged cells and confirm the output retains exactly the configured fraction of consumed energy.
11. Confirm AA packs fit normal/angle/weapon lights, D packs fit Heavy-Duty lights, and cross-connector installation is rejected.
12. Confirm digital watches initialize with a partially charged coin cell, expose timed remove/replace actions, disable their alarm at zero charge, and survive save/reload.
13. Confirm classic watches never expose battery actions. Confirm the rare solar military watch needs no battery and exposes the complete digital watch information set.
# Battery timed-action migration (0.6.1)

0.6.2 adds the explicit native syncItemModData and syncItemActivated calls alongside
syncItemFields after battery completion. InventoryItem transmitModData was not a
verified native synchronization path. The host lifecycle test checks all three
requests; remote-client delivery and underlying transaction rollback remain open.

The action is now shared/server-loadable and globally discoverable under its
network Type. Require paths and queue APIs are unchanged. Constructor fields
match serialized parameter names. Client perform only cleans up; complete
revalidates a living actor, root/nested inventory ownership, compatibility,
charge and installed state before an authority-gated mutation. Each action
instance attempts mutation at most once, including after an exception.

Host case `test_battery_action.lua` covers those lifecycle boundaries and missing
network-resolved objects. It mocks transaction APIs; it does NOT prove their
rollback behavior or cross-instance replay protection. Public direct mutation
APIs still need their own authority/replication audit.

Host case `test_weapon_part_transport.lua` covers parent-weapon discovery,
constructor reconstruction, exact part-ID resolution, full-weapon sync, stale
replacement, duplicate identity, lost container ownership, and removed weapons.
Native timed-action serialization and attachment replication remain in-game gates.

In game, test install/remove/replace in root inventory, nested bags and equipped
devices; move either item away while queued, cancel, and repeat on a remote client.
Confirm exactly one mutation and matching server/client charge and inventory.
Detached weapon-part consumers without a verified carried parent weapon remain
rejected. Test installed gun lights while equipped and in nested carried bags,
then remove or replace the part while an action is queued and confirm no mutation.

## World-present consumers (0.10.0)

Drop an active lightWorks light with a partially charged B47ANCEDPower cell. Let at
least thirty in-game minutes pass, then leave and revisit its chunk. Charge must
fall at the same device/load/pattern rate as the carried equivalent. At zero
charge, visible and UV emission must both stop. Repeat on a dedicated server and
confirm nearby clients receive the updated charge and off state.

## Infrastructure providers (0.11.0)

Host regression `test_infrastructure_registry.lua` covers all four provider
kinds, deterministic ordering, idempotent same-owner registration, ID takeover
rejection, broken-callback isolation, normalized finite SI-unit snapshots,
storage-capacity validation, protected metadata, explicit region keys and hard
query caps. It does not claim a vanilla generator adapter or a working grid.

Before a provider is used for gameplay, validate its object matcher and region
query against loaded/unloaded transitions and dedicated-server authority. No
consumer may infer energy transfer permission from a read-only descriptor.

Host regression `test_vanilla_generator_provider.lua` verifies stable loaded
identity, online/offline/disconnected/empty/failed states, fuel and condition
fractions, native consumption observation, explicit unknown output power, and
rejection of unloaded or unrelated objects. In-game testing must confirm Lua
exposure and synchronization of every inspected method on SP, host and server.

## Environmental infrastructure ingress (0.12.0)

Host regression `test_infrastructure_events.lua` covers schema and evidence
validation, finite bounded regions, normalized risk proposals, bounded regional
target discovery, deterministic protected handlers, replay deduplication, stale
phase rejection, history paging, active-event catch-up, persistent reload,
interrupted-dispatch recovery, partial-provider fail-closed behavior, and client
authority rejection.

In game, enable B47ANCEDPower alone and confirm the ingress remains inert. Then
enable weatherWorks, force a high-wind or severe-storm lifecycle, save/reload,
and confirm one persisted event per stable ID with no duplicate handler call.
Provider-specific electrical damage is not part of 0.12.0; the current output is
a validated consequence proposal and inspection record only.

`test_infrastructure_diagnostics.lua` covers the authority-only diagnostic
summary, all four provider kinds, bounded regional inspection, sanitized paged
event records, handler/query failure visibility, callback privacy, and remote
client rejection. It does not claim an administration command or mutate grid
state.

Version 0.15.1 status-channel regressions reject malformed request IDs and prove
that a transport exception or matching malformed response releases the client's
pending flag with a bounded diagnostic, allowing a later request instead of
wedging presentation for the session.
