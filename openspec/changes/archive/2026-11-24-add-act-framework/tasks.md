# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Requires `fix-map-generator-merge` applied.

## 1. Act definition and generation

- [x] 1.1 Add the `Act` resource and three act `.tres` files (Forest, Ice, Fire) with their own name, background and transition text; Acts 2 and 3 point at the Act 1 pools for now. Verify: the resources load with no errors in `$GODOT --headless --path . --quit-after 90`.
- [x] 1.2 Change `generate_map` to take an act and use its pools; add `get_battle_pool()` / `get_event_pool()` on the map and switch the four `map.gd` lookups and `run.gd`'s tier-2 upgrade to them. Verify: `grep -rn "map_generator.battle_stats_pool\|map_generator.event_room_pool" scenes` returns nothing.
- [x] 1.3 Extend `tools/verify_map_generation.gd` to generate 1000 maps per act and check every `map-generation` invariant plus that each room's battle/event comes from that act's pool. Verify: `$GODOT --headless --path . res://tools/verify_map_generation.tscn` exits 0.

## 2. Run flow and saves

- [x] 2.1 Add `act_index` to the run and `SaveGame`, restore it in Continue, and default old saves to 0. Verify: a save file without the field loads as Act 1 (headless check or manual Continue).
- [x] 2.2 Add the act transition scene (name, lore text, continue button) and wire boss victory: show transition, full heal, carry gold/relics/rerolls, generate the next act. After the last act go to the win screen. Verify: playtest Act 1 to Act 2 with 120 gold, relics and rerolls unchanged and HP full.
- [x] 2.3 Restrict the first-battle weapon/gear reward to `act_index == 0`. Verify: Act 2's first battle shows the regular reward.

## 3. Integration

- [x] 3.1 Run the boot check and the generation harness, then play Acts 1 to 3 once with a saved-and-continued session in Act 2. Verify: no script errors, correct act on Continue, win screen after Act 3.
