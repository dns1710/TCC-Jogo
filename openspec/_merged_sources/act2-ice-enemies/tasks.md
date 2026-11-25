# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Requires `combat-status-toolkit` and `enemy-summoning-and-minions` applied. Run checks after a headless import.

## 1. Test harness first

- [ ] 1.1 Add `tools/verify_ice_enemies.tscn` and script: content validation (every enemy loads with positive stats and an AI with actions), the Act 2 pool (tier counts 3/4/2/1, tier 0 to 2 only Ice enemies, no empty tier), mechanic tests for every scenario in the `ice-enemies` spec, and a smoke run of every Act 2 battle in the real battle scene for 20 seconds with a stand-in player. Verify: it exits 1 on the current code.

## 2. Placeholder sprites

- [ ] 2.1 Generate recolored placeholder sprites for the 6 enemies into `art/placeholders/` with a one-off script. Verify: each file exists and loads, and the names match `art/ART_REQUESTS.md`.

## 3. Enemies

- [ ] 3.1 Snow Wolf pup and Alpha (pack bonus, Howl with its 4-action limit). Verify: the harness shows +1 damage per other wolf and no second Howl within 4 actions.
- [ ] 3.2 Ice-Crystal Spider (Web, Crystal Bite x1.5 vs slowed). Verify: the harness compares bite damage against a slowed and an unslowed target.
- [ ] 3.3 Snow Golem (Pack Snow, cap 20, Avalanche resets block). Verify: five Pack Snow actions reach 20 block, the next action is Avalanche and block is then 0.
- [ ] 3.4 Banshee (Haunt, Chill Touch, gated Frost Wail). Verify: no Wail without Brittle, none within 5 actions of the last, and no Freeze on an already frozen or immune player.
- [ ] 3.5 Yeti (Claw, telegraphed Ground Pound with Speed Down, Roar at 50%, slow immunity). Verify: the Roar is the next action after crossing 50% and Speed Down then has no effect.

## 4. Act 2 content

- [ ] 4.1 Build the 9 Act 2 battles with `BattleStats` (gold per tier as Act 1) and `battles/map2/battle_stats_pool.tres` with Act 1's two bosses as temporary tier 3. Verify: the pool test passes.
- [ ] 4.2 Point `acts/act_2_ice.tres` at the new pool and the Ice battle background. Verify: `verify_act_flow` passes and a rendered Act 2 battle shows the Ice background and a placeholder enemy.

## 5. Integration

- [ ] 5.1 Boot check and all suites, then play two Act 2 fights of different tiers. Verify: no script errors, every suite exits 0, and each fight can be won.

## Workflow follow-up

- Archive the change after review so `ice-enemies` becomes a main spec.
