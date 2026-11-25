# Tasks

Godot binary used below: `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe` (call it `$GODOT`).

## 1. Verification harness (written first, so it fails on the broken generator)

- [x] 1.1 Add `tools/verify_map_generation.tscn` and its script: instantiate `MapGenerator` with `battles/battle_stats_pool.tres` and `scenes/event_rooms/event_room_pool.tres`, call `setup()` once, generate 1000 maps, assert every spec invariant (14x3 layout, one start room in the middle slot, all active rooms reachable, no dead ends, no crossing connections, exactly one tier-3 boss at floor 13 middle slot, start room tier-0 monster, floor 12 all campfires, floor 6 all treasure), print a one-line summary, and `quit(1)` on any failure. Verify: `$GODOT --headless --path . res://tools/verify_map_generation.tscn` currently fails or errors on the unfixed generator.

## 2. Restore the generator and protected floors

- [x] 2.1 Diff `scenes/map/map_generator.gd` against `c5a54c6` and confirm the only extra code at HEAD is the two-region logic. Verify: the diff shows nothing else of value.
- [x] 2.2 Replace `generate_map()` and drop `_generate_region()` with the `c5a54c6` single-region version; remove every `FLOORS_PER_REGION` use and the duplicate `treasure_floor`. Keep `X_DIST`, `Y_DIST`, `PLACEMENT_RANDOMNESS := 0`, `FLOORS := 14`, `MAP_WIDTH := 3`. Verify: `grep -rn FLOORS_PER_REGION scenes` returns nothing and the file parses.
- [x] 2.3 In `scenes/map/map.gd`, change `_is_protected_floor` to `row == 0 or row == MapGenerator.FLOORS - 1`. Verify: no `FLOORS_PER_REGION` remains in the project and `map.gd` parses.
- [x] 2.4 Run the headless boot: `$GODOT --headless --path . --quit-after 90`. Verify: output contains no `SCRIPT ERROR` or `Parse Error` lines (it previously reported errors in `map.gd`, `map_generator.gd` and `run.gd`).
- [x] 2.5 Run `$GODOT --headless --path . res://tools/verify_map_generation.tscn`. Verify: it exits 0 and reports 1000 maps checked with zero violations.

## 3. Repo hygiene

- [x] 3.1 `git rm` the 14 tracked `*.tmp` files under `scenes/battle`, `scenes/map`, `scenes/run` and `scenes/shop`, and add `*.tmp` to `.gitignore`. Verify: `git ls-files | grep '\.tmp$'` is empty, and `$GODOT --headless --path . --quit-after 90` still prints no script errors.
- [x] 3.2 Final integration check on a clean working tree: re-run 2.4 and 2.5. Verify: both pass, and `git status` shows only the intended changes (generator, `map.gd`, `.gitignore`, `tools/`, removed `.tmp` files, this change's artifacts).

## Workflow follow-up

- Archive the change after review so `map-generation` becomes the first spec under `openspec/specs/`.
