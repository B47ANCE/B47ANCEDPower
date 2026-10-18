# Audit remediation

Project Version: 0.17.0-dev.2

## Scope and version decision

The user authorized repair of the 0.16.0 audit findings and a public GitHub backup
at `B47ANCE/B47ANCEDPower`. This is a MINOR development iteration because it adds
compatible server sandbox controls alongside the bug fixes. The Mod ID remains
`B47ANCEDPower`. The user-supplied thumbnail remains byte-identical (SHA-256
`f9fc7a4c1a4c16b34a37260e87052715f631b4e2692453dc8baa669999e2bc4b`).

Authoritative source is `src/B47ANCEDPower/`; `Contents/mods/B47ANCEDPower/` is
the project-local mirror. The local Git baseline records the actual 0.16.0 source
with its known audit defects. Fixes are on `fix/audit-remediation`, for review by
PR before any merge. No stable tag, deployment, Workshop upload or historical
archive rewrite is part of this iteration.

## Repaired contracts

| Audit | Change | Regression evidence |
| --- | --- | --- |
| A1 lookup | Preserve multiple returns, bound slots/containers to 512, avoid cycles and reject foreign ownership/non-finite IDs | real root/nested lookup, foreign/cyclic/over-budget fixtures |
| A2 client menu | Menu can submit intent but cannot create charge; initializer rejects remote clients | actual remote menu callback leaves ModData untouched |
| A3 loose charge | Prefer verified native current-uses fraction, reject unreadable/non-finite values and verify writes; stale cached absolute charge cannot override native discharge | native-shaped depleted cells, stale cache, no-op setter and malformed input fixtures |
| A4 cell storage | Single and multi-cell service share explicit ModData/native mode selection | complete two-cell ModData install/extract with inherited generic native getters |
| A5 replication | Publish one vanilla removal request per committed cell, preserve exact input objects on rollback and synchronize retained recovery state | remove/add request counts and partial-removal rollback fixtures |
| A6 reservation exclusion | Service, initialization, migration and drain reject pending energy records; rollback checks unchanged reserved charge | cross-path reservation/extraction and cell-set lock fixtures |
| A7 event retention | Bound history, processed IDs and streams together; persist an eviction time floor | 600 streams, reattach/restart and exact evicted replay rejection |
| A8 migration authority | Shared migration entry points and client legacy callback reject remote mutation; server processes registered carried consumers | remote migration remains unchanged |
| A9 UI request recovery | Technical timeout, disconnect/reconnect reset, monotonically increasing IDs and stale reply rejection | missing response, late response, missing clock and lifecycle fixtures |
| A10 watch scheduling | Server/SP scans bounded owned root/nested inventories; item-owned world-minute timestamps govern drain | no-client-request scheduling, duplicate request, elapsed time, restart, quarantine and alarm fixtures |
| A11 runner | Resolve/validate a project root; reject empty discovery | runner invoked from a different working directory executes real tests |
| A12 watch fraction | Declared/installed ModData storage precedes generic native fields | consumption reduces a 20% watch to 16%, rather than increasing it |

All twelve new targeted checks failed against the original 0.16.0 implementation
before the production fixes. They pass against the repaired source. The existing
watch tests now exercise the actual API/server module instead of replacing the
broken lookup with a stub. Native-shaped fixtures expose inherited getter conflicts.

## Authority, configuration and persistence

Clients submit an owned watch ID; they do not choose charge, elapsed time or drain.
The server/SP path validates authority, living actor, ownership, registered watch
profile, rate limit, recovery state and world time. Shared charge mutations reject
remote clients. Scheduling uses installed vanilla `getOnlinePlayers`, local active
player enumeration, `getGameTime():getWorldAgeHours()` and vanilla item sync calls.
Observed call forms and source fingerprints are in `API_EVIDENCE.json`; Steam
build is 25485521, full installed engine version remains UNKNOWN. Source evidence
is not native invocation or dedicated multiplayer proof.

Watch state adds `B47ANCEDPowerWatchLastMinute`, an item-owned integer timestamp.
A watch without that field receives a baseline at first authoritative observation,
with no retroactive grant or loss; an existing installed cell is not reinitialized.
Later observations subtract charge for elapsed world minutes, including gaps while
the item is not observed. Duplicate requests do not cause another deduction.
Future/malformed timestamps fail closed for inspection. Recovery markers defer
maintenance and preserve the elapsed interval. Save/reload, owner transfer,
disconnect/reconnect and dedicated restart still require native validation.

The server visits at most 64 players per minute using a rotating cursor and at
most 512 inventory slots per player. These are technical safety limits, not
sandbox micro-settings. Over-budget inventories may be deferred/rejected; no
unbounded world or inventory scan is introduced. Containerless weapon-part
migration still requires its owning integration to invoke the authoritative API.

Sandbox values have stable IDs, type/finite checks, bounds, defaults and integer
normalization. Two additional settings preserve the previous default behavior:

- `ExtraBatteryLootMultiplier`: 0–10, default 1. Scales ordinary sized-battery extra
  rolls; 0 disables them. Conversion weights and the separate coin-cell chance
  retain their own meaning. Fixed relative rarity is authored content; exposing
  a second set of per-cell chance sliders would duplicate the existing weight UI.
- `AdapterMagazineLootChance`: 0–1, default 0.012. Controls the independent recipe
  magazine addition. Existing saves missing these fields use their documented defaults.

New labels/tooltips and remaining action/status labels have explicit English
fallback entries in all 29 existing language folders. Key coverage is verified;
human translation quality and native text formatting are not claimed.

Event store schema remains 1 with additive `expiredThrough`. Retention bounds all
three collections to 256. Events at/below the persisted eviction floor are rejected
unless still represented as a known duplicate; this deliberately rejects delayed
old events rather than allowing their effects to replay after eviction. Malformed
or oversized legacy records are preserved and rejected for manual inspection.
Downgrading to code unaware of the eviction floor is not supported. No real save
was modified; disposable native old-save/restart evidence remains outstanding.

The in-game harness no longer calls an absent reserve API or marks persistence
PASS just because its session survived reload. It records a reload observation,
then requires the tester's item/energy comparison notes for a manual persistence
PASS. Test-kit spawning is blocked on remote clients. Manual reports are human
evidence, not automated engine assertions.

## Offline validation

Run from the repository root with Python and development-only `lupa.lua51`:

```powershell
python scripts/check_versions.py --root . --json
python scripts/check_identity.py
python scripts/run_lua_tests.py
python tests/test_audit_regressions.py
python art/test_asset_coverage.py
python art/check_asset_coverage.py
git diff --check
```

The local bundled interpreter used is
`C:/Users/willi/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.
Recorded offline results are in `VALIDATION.json`: 25 Lua test files, all 12 audit
regressions, 44 production/mirror syntax checks and 11 art unit tests PASS; the
115 source and 115 mirror files match. The original thumbnail and historical
assets retain their hashes.

These checks do not start PZ or a server. They verify source contracts, not native
packet delivery, engine serialization, alarm behavior or multiplayer correctness.
No current ZIP is created, so release artifact checks remain deferred.

## Runtime gates

G7 dedicated multiplayer **NOT TESTED / BLOCKED**. Stable-release G8 **BLOCKED**.
Follow `RUNTIME_VALIDATION.md` on disposable saves only. No in-game success is
inferred from the offline suite, a GitHub push, or a PR review.
