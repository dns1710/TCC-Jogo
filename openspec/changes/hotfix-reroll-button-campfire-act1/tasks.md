## 1. Reroll button fix

- [x] 1.1 Call `_update_reroll_button()` from `show_map()` in `scenes/map/map.gd` (and after `run_stats` is set / run loaded)
- [x] 1.2 Check reroll-gaining event outcomes (Fallen Adventurer +1, Forest Guardian +2) re-enable the button after returning to the map

## 2. Move Campfire to Act 1

- [x] 2.1 `git mv` `tier_2_campfire.tres/.tscn` (and any `.import`/uid files) from `battles/map3/tier2/` to `battles/map1/tier2/` and fix internal paths
- [x] 2.2 Add the battle to `battles/battle_stats_pool.tres`; remove it from `battles/map3/battle_stats_pool.tres`
- [x] 2.3 Update `tools/verify_act_enemies.gd`: drop `campfire` from `FIRE_ENEMIES`, add an Act 1 pool check that allows it

## 3. Verification

- [ ] 3.1 Run `Godot --headless --path . res://tools/verify_act_enemies.tscn` and `verify_event_rooms` / `verify_map_generation`
- [ ] 3.2 Manually test: reach 0 rerolls, take a +1 reroll event, confirm the button works; confirm Campfire fights appear in Act 1 and not Act 3
