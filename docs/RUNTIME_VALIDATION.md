# Runtime validation procedure

This is a checklist, not test evidence. Use a fresh disposable save and exactly
the recorded source commit/version. Begin with `B47ANCEDPower` alone; other mods
must update their dependency/import namespaces before combined-stack testing.
The current build and unresolved gates are in `AUDIT_REMEDIATION.md`.

## Single-player

1. Record the actual game patch version, mod version, source commit, enabled IDs
   and environment. Preserve any existing saves; create a separate disposable world.
2. In a debug session, run `B47ANCEDPowerTestStart(true)` and
   `B47ANCEDPowerTestKit()`. Confirm the server/SP scheduler initializes carried
   digital watches, including a watch inside a bag. Classic/solar watches must not
   receive coin-cell service actions.
3. Insert/extract partly depleted cells and compare charge, exact physical item
   counts, interrupted actions, incompatible/empty cells and mounted consumers.
   Repeat two-cell operations after its owning device integration is updated.
4. Confirm watch consumption only reduces charge, nested watches drain, duplicate
   menu requests do not accelerate drain, and empty watches stop alarms.
5. Test adapter and taped-pack crafting from partly charged cells. Compare total
   input/output energy and the configured efficiency; never use fresh full-cell
   tests alone to infer conservation.
6. Record installed charge and physical cell counts before saving. Quit/reload;
   run `B47ANCEDPowerTestReload()`, compare the actual values, and record explicit
   observations when confirming the persistence step. A session reload alone is
   not PASS. Account for the documented elapsed-world-time watch consumption.
7. Verify sandbox defaults/bounds, disabled extra loot and magazine rolls, labels,
   tooltips and thumbnail. Retest existing-save fixtures separately with backups.

## Dedicated server with two clients

1. Use a separately identified disposable server profile and save. Record exact
   server/client builds, source commit, configuration and enabled Mod IDs. Server
   startup, profile edits and distribution need their own selected test environment.
2. Join both clients. Compare cell counts and charge on actor, observer and server
   after single/multi-cell install, removal, replacement and interrupted operations.
3. Attempt foreign-item, stale ID, malformed ID, duplicate intent and concurrent
   requests. Only the server may commit changes; no rejected request may lose or
   duplicate cells or create energy.
4. Keep watches in root and nested inventories without requesting maintenance.
   Confirm server-time drain. Open menus repeatedly; confirm no extra drain or
   locally initialized charge. Transfer ownership, reconnect and late-join.
5. Exercise pending energy reservation versus service/migration/drain; operations
   must reject or defer. Commit and rollback must conserve energy and preserve
   unresolved recovery records across reloads.
6. Restart the dedicated server. Check persistent cell state, item-owned watch
   clocks and replay rejection across event-retention eviction. Do not clear an
   uncertain marker manually to obtain a passing result.
7. Record client/server exceptions and the exact scenario, then report PASS/FAIL/
   BLOCKED per case. Current G7 and stable G8 remain BLOCKED until this evidence
   exists. Offline fixtures and SP results do not prove dedicated behavior.
