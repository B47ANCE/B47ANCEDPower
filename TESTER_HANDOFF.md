# B47ANCE'd Power 0.17.0-dev.2 playtester handoff

This is an updated test procedure, not a runtime result. Use a fresh disposable
save with Mod ID `B47ANCEDPower` and reconfigure sandbox settings. No legacy-save
migration is supplied. Dedicated G7 NOT TESTED / BLOCKED; stable-release G8 BLOCKED.

Begin only after stages 1–3 are reviewed as PASS. Enable B47ANCEDPower alone on a
disposable save and run `B47ANCEDPowerTestStart(true)` in the Lua debug console.

1. Run `B47ANCEDPowerTestKit()` and follow its watch-battery instructions.
2. Confirm a classic watch offers no battery action and a solar military watch needs no battery.
3. Try wrong, empty, occupied, nested, and equipped battery cases; confirm rejection causes no loss.
4. Craft the improvised AA and taped packs from partly charged cells; confirm outputs retain charge and fit the expected devices.
5. Save/quit/reload after servicing the watch, confirm its charge/state, then run `B47ANCEDPowerTestReload()`.
6. Run `B47ANCEDPowerTestSandbox()` and follow its setting instructions.
7. Mark hosted/dedicated testing BLOCKED until actually performed.
8. Run `B47ANCEDPowerTestReport()`.

Return the result file, `console.txt`, and screenshots for visual failures. Do
not add lightWorks or Nightfall until this stage is reviewed.
