# Build 42.20 vanilla generator boundary

## Evidence

Inspected the installed `projectzomboid.jar` `IsoGenerator` implementation and
the installed vanilla Lua timed actions/context menus. No native or third-party
source was copied into B47ANCEDPower.

The loaded generator exposes read access to fuel, maximum fuel, condition,
activation, connection, current powered-item load/fuel consumption, item type,
square and object index. Vanilla owns all mutation, fuel use, condition decay,
backfire/fire behavior, surrounding electricity and synchronization.

## Confirmed limitation

`getTotalPowerUsing()` is the native consumption value after the generator fuel
multiplier. It is not a rated electrical output, wattage, spare capacity, or
surplus measurement. The installed class exposes no verified external-energy
input and no safe way to derive generator surplus from that value.

Accordingly, B47ANCEDPower 0.11.0 provides only a read-only source/network
observation adapter. It reports `powerKnown=false`; consumers must fail closed
for charging, inverter discharge, or grid balancing. Gasoline is never mutated
to represent battery energy.

## In-game gates

- Confirm every inspected method is Lua-visible on SP, host and dedicated server.
- Confirm object index and square identity remain stable for a loaded placement
  and change safely after pickup/replacement.
- Confirm fuel, condition, activation, connection and native-use observations
  converge for clients without additional B47ANCEDPower mutation.
- Do not implement surplus charging until a verified output-capacity boundary
  exists or B47ANCEDPower owns an explicit rated-output profile for that generator.
