# B47ANCE'd Power in-game validation

Current development version: `0.16.0`. Enable Mod ID `B47ANCEDPower` on a fresh
disposable save. Reconfigure sandbox settings; do not load a prior-identity save
to test this breaking rename. This document is a procedure, not runtime evidence.

B47ANCEDPower is stage 4 of the progressive Nightfall test. Begin only after the
first three reports are reviewed as PASS. Test B47ANCEDPower alone on a disposable
save; the earlier stack remains certified separately.

Run `B47ANCEDPowerTestStart(true)`. The harness provides `B47ANCEDPowerTestAuto()`,
`B47ANCEDPowerTestKit()`, `B47ANCEDPowerTestReload()`, `B47ANCEDPowerTestSandbox()`, the
standard Pass/Fail/Blocked commands, `B47ANCEDPowerTestReport()`, and
`B47ANCEDPowerTestWhere()`.

The result is `%USERPROFILE%\Zomboid\Lua\theWorks Test Results - B47ANCEDPower.txt`.
It covers standalone startup, watch servicing, cell compatibility, crafting,
energy persistence, settings, and multiplayer authority. Host execution does
not certify native timed actions, item serialization, alarms, or networking.
