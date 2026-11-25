# Proposal

## Why

The difficulty-adjustment (DDA) logic is spread across six handlers in `run.gd` with thresholds hardcoded in each. Its flags are never reset (so the shop conversion fires once per whole run), one flag (`dda_treasure_spawned`) is never read, flags are marked used even when no room was converted, and the campfire score is measured after the player has healed so it can only ever rise. Room conversions are un-awaited coroutines that mutate the map about two seconds into an animation, while saves snapshot the map immediately. With three acts coming, this must be fixed first.

## What Changes

- Move every DDA decision (when to convert a room, which types) into one DDA component with its thresholds in a tunable resource; `run.gd` only executes the conversions it returns.
- Persist all DDA flags with the run and reset them at the start of each act.
- Mark a flag as used only when a conversion actually happened.
- Measure campfire HP before the rest heal, and let low HP lower the score, mirroring battles.
- Apply room-type changes to the map data immediately and before saving; the conversion animation becomes cosmetic and plays only when the map is visible.
- Remove the dead `dda_treasure_spawned` flag; route all score changes (battles, campfire, relic pickup, events) through one function that records the reason.

Out of scope: rebalancing the threshold values themselves; the score-multiplier use of the DDA value (`add-run-scoring`); new event content.

## Capabilities

### New Capabilities
- `dda-room-adjustment`: how the game reads player performance and converts upcoming rooms, including flag lifetime, persistence and when changes take effect.

### Modified Capabilities

None.

## Impact

- Code: `custom_resources/dda.gd` (grows), `scenes/run/run.gd` (handlers shrink), `scenes/map/map.gd` (`change_room`, animation), `custom_resources/run_stats.gd`, `custom_resources/save_game.gd`, `scenes/relic_handler/relic_handler.gd`, `scenes/event_rooms/gamble_event.gd`, `marshmellow_event.gd`, `scenes/campfire/campfire.gd`.
- Depends on `add-act-framework` for the per-act reset hook; the rest can land first.
