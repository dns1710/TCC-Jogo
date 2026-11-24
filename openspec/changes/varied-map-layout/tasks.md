# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import. Screenshots: temporary scene in `tools/` run non-headless, deleted afterwards.

## 1. Test harness first

- [x] 1.1 Update `tools/verify_map_generation.gd`: `EXPECTED_WIDTH` to 7 and add checks for the new requirements (3 or 4 connections from the start, at least 4 distinct routes, 3 to 5 active rooms on floors 1 to 12, no straight route, at least 35% slot-changing connections, offsets within `PLACEMENT_RANDOMNESS`, active rooms at least 14 px apart), still over 1000 maps for each of the 3 acts. Verify: it fails on the current generator.

## 2. Generator

- [x] 2.1 Set `MAP_WIDTH = 7`, `Y_DIST = 20` and `PLACEMENT_RANDOMNESS = Vector2(20, 10)` with symmetric offsets and rejection sampling. Verify: positions check passes; `map.gd` camera extent still follows the constants.
- [x] 2.2 Replace the per-room column nudging with route generation (3 or 4 start branches, 4 to 6 non-crossing walks with mid-map splits and merges, all floor-12 rooms to the boss), keeping the start, boss, treasure floor and pre-boss campfire rules. Verify: reachability, no dead ends, no crossings, single boss and key floors checks pass over 1000 maps per act.
- [x] 2.2b Check the drawn lines: no intersections except at shared rooms, 8 px clearance from unrelated rooms, 12 degrees between lines sharing a room, start and pre-boss floor on the inner 5 lanes, 30 px frame gap. Verify: the test fails with the check disabled and passes with it over 1000 maps per act.
- [x] 2.3 Add the layout validation (occupancy, no straight lane, slot-change share, route count) with bounded regeneration. Verify: the layout checks pass over 1000 maps per act and the fallback after 60 attempts never happens (print the retry rate).

## 3. Integration

- [x] 3.1 Compare room-type counts per map before and after over 1000 maps. Verify: average counts of monsters, events, shops, campfires and treasures per map change by less than about 15%, or the difference is reported to the user.
- [x] 3.2 Boot check and all suites (`verify_map_generation`, `verify_dda`, `verify_act_flow`, `verify_act_framework`, `verify_event_rooms`, `verify_item_pools`, `verify_combat_pacing`, `verify_combat_statuses`, `verify_enemy_summoning`, `verify_act_enemies`). Verify: no script errors and every suite exits 0.
- [x] 3.3 Render the map screen and look at it with the camera at the start, middle and boss, plus a continued run loaded from an old 3-slot save. Verify: the map fits the screen, routes look varied and lines do not pass through unrelated rooms.
- [ ] 3.4 Manual playtest of choosing routes through one act. Left to the user.

## Workflow follow-up

- Archive after review so `map-generation` is updated in the main specs.
