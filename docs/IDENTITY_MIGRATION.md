# B47ANCE'd Power identity migration

Project Version: 0.16.0

## Decision and compatibility

The user authorized local work without Git freshness and establishment of version
0.16.0 on 2026-10-16. The final title is **B47ANCE'd Power** and the technical
identity is **B47ANCEDPower**. Earlier naming candidates are superseded.
The source version was 0.15.3; the previous `Contents` copy was 0.15.1.
This is an explicitly incompatible 0.x MINOR iteration: all project-owned
identities change together. It is not stable-release approval.

| Surface | Previous identity (historical) | Current identity |
| --- | --- | --- |
| Public title | powerWorks | B47ANCE'd Power |
| Mod ID / enabled-mod list | `powerWorks` | `B47ANCEDPower` |
| Project/source/mirror folder | `powerWorks` | `B47ANCEDPower` |
| Lua require / global | `powerWorks/API`, `powerWorks` | `B47ANCEDPower/API`, `B47ANCEDPower` |
| Script module and items | `powerWorks.BatteryAA` | `B47ANCEDPower.BatteryAA` |
| Sandbox owner | `SandboxVars.powerWorks` | `SandboxVars.B47ANCEDPower` |
| Translation families | `Sandbox_powerWorks_*`, `powerWorks.*` in ItemName.json, `ContextMenu_powerWorks_*` | Equivalent `B47ANCEDPower` families |
| State and recovery keys | `powerWorks*` | `B47ANCEDPower*` |
| Event store | `powerWorks.InfrastructureEvents.v1` | `B47ANCEDPower.InfrastructureEvents.v1` |
| Network channels / timed action | `powerWorks*` | `B47ANCEDPower*` |
| Debug entry points | `powerWorksTest*` | `B47ANCEDPowerTest*` |

Use a **fresh disposable save** and explicitly reconfigure all sandbox options.
No legacy alias, saved-item conversion, ModData migration, sandbox migration or
downgrade compatibility is supplied. Loading an old world under the new identity
is unsupported and may leave missing items or ignored state. Real saves and
installed mod copies are untouched. Restore the old build with its original
identity to continue an old save; retain a separate save backup before any test.

The nominal cell schema and registry/protocol schema numbers are unchanged:
the project version is not a schema version. Shared state is still mutated only
through the existing server/SP authority checks, bounded ownership resolution,
transaction recovery and synchronization paths. No new APIs, gameplay values,
configuration knobs, Java code, client authority or networking behavior is added.
Implementation limits remain internal; meaningful gameplay configuration retains
its existing defaults and bounds under the new server-owned sandbox namespace.

## Integrations and source layout

The authoritative mod root is `src/B47ANCEDPower/`; the local mirror is
`Contents/mods/B47ANCEDPower/`. The older mirror was backed up before being
refreshed from the authoritative renamed source, including localization files.
This is not a Workshop upload or installation to a live mods directory.

Separate lightWorks, Nightfall, waterWorks and optional uiWorks/weatherWorks
integrations must be reviewed for old dependency IDs, imports, globals, item
types, state keys and protocol names. Those projects have not been edited here.
New clients and servers must use the same renamed version; mixed identities
and stale dependent mods are unsupported. The Workshop item remains `3788592598`.

No Git repository or remote exists for this local project. Git freshness is
UNKNOWN, explicitly waived for this local iteration. There is no commit or push:
**NOT BACKED UP TO GITHUB**. No repository, remote or public URL was invented.

The previous working source, mirror, docs, tests and artwork were copied to the
local sibling `Repository Cleanup Backups/powerWorks-before-B47ANCEDPower-0.16.0-20261016`.
Its `before-sha256.json` records the original project files;
`protected-sha256.json` records immutable files checked after the rename.
Historical ZIPs and staging backups in `dist/`, `SHA256SUMS.txt`, the last upload
hash, Workshop ID, original artwork and asset-validation hashes are unchanged.
Original image-generation prompts in `art/README.md` retain their historical
wording. These are intentional historical references, not missed active names.

The project folder is now `B47ANCEDPower`. The four existing workspace project
selectors (`B47ANCED`, `B47ANCED-Chats`, `B47ANCED-Saved-Chats` and
`B47ANCED-Sidebar` `.code-workspace` files) were updated only for this project’s
label/path, after preserving their originals under the backup’s
`workspace-selectors/` folder. The generated `WORKSPACE-SETUP.json` report and
older workspace audit records remain historical and were not rewritten.

## Version inventory and validation

Root `VERSION` is canonical. `version-inventory.json` declares active metadata,
Lua, README, roadmap, handoff, validation and Workshop mirrors; historical and
game/schema versions are classified separately. The dependency-free checker and
policy were copied unchanged from the existing reviewed team files in the local
B47ANCEDRooms project. No current ZIP is created; future authorized release
artifacts belong in `dist/current/` and must pass `--release` checking.

Baseline [TESTED — offline]: all 19 existing Lua test files passed under host
Lua 5.1 via Lupa, and all 42 source/old-mirror Lua files compiled. The baseline
version preflight failed because the project had no canonical version inventory;
this was a pre-existing onboarding gap, not evidence of a current release pass.

Post-change [TESTED — offline], run from the renamed project root:

| Check | Result |
| --- | --- |
| `scripts/check_versions.py --root . --json` | PASS: canonical 0.16.0 and all declared current mirrors; packaging deferred |
| `scripts/check_identity.py` | PASS: 114 source files and 114 byte-identical mirror files; 32 case-correct local Lua require references; all 29 language folders retain matching keys and the renamed sandbox title |
| `scripts/run_lua_tests.py` | PASS: all 19 regression files in isolated Lua 5.1 VMs; all 42 production/mirror Lua files compile |
| `art/test_asset_coverage.py` | PASS: 11 isolated host tests |
| `art/check_asset_coverage.py` | PASS: 10 scripted battery source exports match their original hashes and 10 selected RGBA source icon masters pass the existing checks |
| Preservation audit against the local backup manifest | PASS: all 1,280 protected files retain their SHA-256 hashes |
| Comparison of production Lua against the backup | PASS: all 21 files differ only by mechanical identity, version and display-text substitutions; no gameplay calculations or authority checks changed |

Exact PowerShell validation commands (the available bundled development runtime):

```powershell
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' scripts/check_versions.py --root . --json
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' scripts/check_identity.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' scripts/run_lua_tests.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' art/test_asset_coverage.py
& 'C:\Users\willi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' art/check_asset_coverage.py
```

The current-artifact `--release` check was not run: no current archive was
requested or created. Historical packages are not current 0.16.0 evidence.
Source case validation is not Linux dedicated-server execution. Matching
translation keys are fallback-coverage evidence, not proof of native display or
translation quality. Host harness PASS results are fixture results, never in-game
proof. Original artwork approvals and native rendering remain at their prior
recorded status.

[RUNTIME GATE] Project Zomboid SP, hosted MP and dedicated MP have not been run.
G7 **NOT TESTED / BLOCKED** and stable-release G8 **BLOCKED**. Native loading,
item scripts, localization, timed-action transport, save/reload, reconnect, late
join, concurrent service, settings and dedicated restart require actual runtime
evidence. Offline checks cannot prove these. No deploy, publish or game/server
launch was performed.
