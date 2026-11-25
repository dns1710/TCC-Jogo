# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import (`--import --quit`) so new classes are known.

## 1. Event model and pool

- [x] 1.1 Add `EventOutcome`, `EventChoice` and `EventDefinition` resources with effect application, cost and affordability, weighted and stat-check resolution, and effect summary lines. Verify: a headless test with synthetic definitions covers every effect type, the safety clamps, weights (about 50% over 2000 picks) and the 80% stat check at speed 5.
- [x] 1.2 Change `EventRoomPool` to hold definitions and `pick(seen)` using the `RNG` autoload (repeat fallback with a warning); add saved `RunStats.seen_events`. Verify: a headless test draws 8 distinct events from an 8-event pool, then a repeat with a warning, and a save round trip keeps the list.

## 2. Playing an event

- [x] 2.1 Add the `ChoiceEvent` scene and script: title, text, choice buttons (disabled when unaffordable), outcome screen with effect lines and Continue; extend `EventRoom` with `definition`, `relic_handler`, `map`, `relic_pool`. Verify: a headless test builds the scene, presses a choice, sees the outcome text and effect lines, and Continue emits `event_room_exited`.
- [x] 2.2 Add the relic and room-conversion effects (random relic by rarity from the reward pool, `map.change_room`). Verify: the test grants an uncommon relic not already owned and the summary names it; a conversion is requested with a stub map.

## 3. Run flow and map

- [x] 3.1 Pick the event on entry in `run.gd` (inject hooks, record seen, support `custom_scene`), clear seen events at act start and new run, and stop assigning events in `map_generator.gd` and `map.gd`. Verify: `grep -rn "get_random()" scenes custom_resources` finds nothing for events and a run-level test shows two entries give two different events and a new act clears the list.
- [x] 3.2 Re-cut `_assign_random_type` to 57/18/8/10/7 and update `tools/verify_map_generation.gd` (event share 18% within 2 points, rooms carry no event). Verify: `$GODOT --headless --path . res://tools/verify_map_generation.tscn` exits 0.

## 4. Content

- [x] 4.1 Port Slot Machine and Marshmallow to definitions and remove the old gamble and marshmallow scripts and scenes. Verify: both appear in the Forest pool, the all-in bet shows its multiplier result, and no reference to the old files remains.
- [x] 4.2 Author the 8 Forest, 8 Ice and 8 Fire events as resources, create the three act pools and point each act at its own. Verify: a validation test checks every event has a title, text of at most 120 characters, valid choices and outcomes with text of at most 100 characters, every pool has at least 6 events, and all 24 ids are unique.

## 5. Integration

- [x] 5.1 Boot check, all headless tests, and one playthrough of each act's events at least once. Verify: no script errors, no repeats inside an act, every event shows its outcome screen.

## Workflow follow-up

- Archive the change after review so `event-rooms` becomes a main spec.
