# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Requires `combat-status-toolkit`, `enemy-summoning-and-minions` and `act3-fire-enemies` applied. Run checks after a headless import.

## 1. Test harness first

- [ ] 1.1 Add `tools/verify_fire_dragon.tscn` and script covering every scenario in the `fire-dragon-boss` spec (Freeze immunity, Breath telegraph with Scorch, Roar once, imp summon cap and cooldown, Ember Field, both thresholds in one hit) and Act 3's boss floor battle. Verify: it exits 1 on the current code.

## 2. Boss

- [ ] 2.1 Add the placeholder Fire Dragon sprite (with telegraph and later-phase variants) to `art/placeholders/` and the Dragon `EnemyStats` (immune to Freeze). Verify: the stats load and the sprite files match `art/ART_REQUESTS.md`.
- [ ] 2.2 Phase 1: Claw and the telegraphed Fire Breath. Verify: the harness shows a warning before the Breath and 2 Scorch stacks applied.
- [ ] 2.3 Phase 2: threshold at 60% (Roar once) and the imp `SummonAction` (cap 2, 4-action cooldown). Verify: one Roar only, 2 imps at most, and a resummon after the cooldown.
- [ ] 2.4 Phase 3: threshold at 30% (Speed Up x2 once) and Ember Field. Verify: the player gains 1 Scorch stack after each Dragon action and Speed Up is applied once.

## 3. Act 3 wiring

- [ ] 3.1 Add the Fire Dragon tier 3 battle and replace the temporary Act 1 bosses in `battles/map3/battle_stats_pool.tres`. Verify: the pool test shows tier 3 contains only the Dragon and `verify_fire_enemies` still passes.

## 4. Integration

- [ ] 4.1 Boot check and all suites, then fight the Dragon once through all three phases. Verify: no script errors, every suite exits 0, and the fight can be won.

## Workflow follow-up

- Archive the change after review so `fire-dragon-boss` becomes a main spec.
