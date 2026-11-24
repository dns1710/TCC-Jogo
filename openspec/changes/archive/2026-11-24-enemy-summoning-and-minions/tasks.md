# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import (`--import --quit`).

## 1. Test harness first

- [x] 1.1 Add `tools/verify_enemy_summoning.tscn` and script covering the `enemy-summoning` scenarios (spawn into a free slot and acting, cap of 5, minion-first and summoner-first deaths with fizzle and the 6 second fallback, victory when only fizzled minions remain, heal-allies, telegraph then strike, one-time threshold) and the act background rules. Verify: it exits 1 on the current code.

## 2. Spawning

- [x] 2.1 Add the 5 slots and `EnemyHandler.spawn_enemy` with the spawn animation, empty turn bar and cap. Verify: the harness shows a spawned enemy appears, acts after its bar fills, and a sixth spawn is refused.
- [x] 2.2 Record the summoner on spawned enemies and add the fizzle logic (next action or 6 seconds). Verify: the harness covers minion-first, summoner-first and simultaneous deaths, and the battle ends in victory afterwards.

## 3. Action building blocks

- [x] 3.1 Add `HealAlliesAction`, `SummonAction`, `TelegraphAction`/`TelegraphedStrikeAction` and `ThresholdAction` under `scenes/enemy/`. Verify: the harness builds a small AI from them and checks heal clamping, telegraph then strike, summon cooldown and once-only threshold; existing Bomb and Bear fights still start (a boot and a battle smoke test).

## 4. Battle background

- [x] 4.1 Add `Act.battle_background`, pass it from `Run` to `Battle`, and rescale the background sprite; leave the forest as the default. Verify: the harness checks the forest is used when null and the act's texture otherwise, and a rendered screenshot shows an act background filling the screen.

## 5. Integration

- [x] 5.1 Boot check and all suites (`verify_enemy_summoning`, `verify_combat_pacing`, `verify_act_flow`, `verify_event_rooms`, `verify_dda`, `verify_item_pools`, `verify_map_generation`). Verify: no script errors and every suite exits 0.

## Workflow follow-up

- Archive the change after review so `enemy-summoning` becomes a main spec and `act-progression` gains the background requirement.
