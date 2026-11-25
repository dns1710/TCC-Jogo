# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import (`--import --quit`) so new classes are known.

## 1. Guard test (written first, so it fails now)

- [x] 1.1 Add `tools/verify_item_pools.tscn` and script: read `battle_relic_pool`, `treasure_relic_pool` and `shop_relics` from the three scenes, scan `relics/**/*.tres` (skipping `1old/`), and fail on any non-starter item in no pool, any item still flagged as a starter, a missing or duplicate id, the five added items missing from their expected pools (Heavier Armor, Barbarian Armor, Snowballs, Shadow Sneakers in all three; Gloves in reward and shop), and a new run whose relic handler is not empty (backing up and restoring `user://savegame.tres`). Verify: `$GODOT --headless --path . res://tools/verify_item_pools.tscn` exits 1 on the current code and names the five unpooled items, Hunter's Axe, and the starting relic.

## 2. Itemless start

- [x] 2.1 Remove the three starter lines (preload, `add_relic`, `equip_relic`) from `_start_new_run` in `scenes/run/run.gd`. Verify: the new-run check in the guard test passes, the other suites (`verify_act_flow`, `verify_dda`, `verify_event_rooms`) still pass, and `grep -n "starter_relic" scenes/run/run.gd` finds nothing.

## 3. Item data

- [x] 3.1 Rename `barbarian.tres` to "Barbarian Armor" and `icy.tres` to "Snowballs" (display names only; ids stay). Verify: the names read back from the resources, and no other file refers to the old display names.
- [x] 3.2 Set the Gloves tooltip to "You [wave amp=3.0 freq=5.0][color=#ffd04d]receive[/color][/wave] unexplainable confidence, +1 attack" in `receba.tres`. Verify: render the hover tooltip once and check it reads cleanly with "receive" styled differently.
- [x] 3.3 Clear `starter_relic` on `hunters_axe.tres`. Verify: the guard test's "no starter-flagged item" check passes and `Relic.can_appear_as_reward` is true for Hunter's Axe.

## 4. Pools

- [x] 4.1 Add `slow`, `barbarian`, `icy` and `shadow` to the reward, treasure and shop arrays, and `receba` to the reward and shop arrays, in `run.tscn`, `treasure.tscn` and `shop.tscn` (array entries and their `ext_resource` lines only; no other pool membership changes). Verify: the guard test passes, and a diff of the three scenes shows only those additions.

## 5. Integration

- [x] 5.1 Boot check and all headless suites (`verify_item_pools`, `verify_map_generation`, `verify_act_framework`, `verify_act_flow`, `verify_combat_pacing`, `verify_event_rooms`, `verify_dda`), then start a new run in the game. Verify: no script errors, all suites exit 0, and the first battle starts with no items and rewards a weapon and gear.

## Workflow follow-up

- Archive the change after review so `item-availability` becomes a main spec.
