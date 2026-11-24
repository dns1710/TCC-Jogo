# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Requires `combat-status-toolkit`, `enemy-summoning-and-minions` and `act2-ice-enemies` applied. Run checks after a headless import.

## 1. Test harness first

- [ ] 1.1 Add `tools/verify_krampus.tscn` and script covering every scenario in the `krampus-boss` spec (Freeze immunity, Chain Pull effects, wolf summon with cap and cooldown, phase thresholds including one hit crossing both, Wrath telegraph and cadence) and Act 2's boss floor battle. Verify: it exits 1 on the current code.

## 2. Boss

- [ ] 2.1 Add the placeholder Krampus sprite (with phase 2 and telegraph variants) to `art/placeholders/` and the Krampus `EnemyStats` (immune to Freeze). Verify: the stats load and the sprite files match `art/ART_REQUESTS.md`.
- [ ] 2.2 Phase 1: Birch Switch and Chain Pull in the AI scene. Verify: the harness shows two hits per Birch Switch and 3 Speed Down stacks plus Brittle from Chain Pull.
- [ ] 2.3 Phase 2: threshold at 50% and the wolf `SummonAction` (cap 2, 3-action cooldown). Verify: the harness shows 2 wolves at the threshold, none while 2 are alive, and a resummon after the cooldown.
- [ ] 2.4 Phase 3: threshold at 25% (Speed Up once) and the Winter's Wrath cadence with its telegraph. Verify: a warning precedes the strike, every third action is Wrath, and Speed Up is applied once.

## 3. Act 2 wiring

- [ ] 3.1 Add the Krampus tier 3 battle and replace the temporary Act 1 bosses in `battles/map2/battle_stats_pool.tres`. Verify: the pool test shows tier 3 contains only Krampus and `verify_ice_enemies` still passes.

## 4. Integration

- [ ] 4.1 Boot check and all suites, then fight Krampus once through all three phases. Verify: no script errors, every suite exits 0, and the fight can be won.

## Workflow follow-up

- Archive the change after review so `krampus-boss` becomes a main spec.
