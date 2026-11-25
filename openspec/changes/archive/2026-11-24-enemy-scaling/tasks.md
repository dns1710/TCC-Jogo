# Tasks

## 1. Act data

- [x] 1.1 Add `enemy_health_scale`, `enemy_attack_bonus` and `boss_extra_dice` to `custom_resources/act.gd` with neutral defaults and set initial values in `acts/act_1_forest.tres`, `act_2_ice.tres`, `act_3_fire.tres`; verify the resources load and act 1 values are neutral.

## 2. Applying the scaling

- [x] 2.1 Pass the current act's scaling to battle setup and apply health scale and attack bonus after `create_instance()` in `scenes/enemy/enemy.gd`; verify with `tools/verify_enemy_scaling.gd` that a 20 HP enemy has 25 HP under scale 1.25 and that the shared resource is untouched.
- [x] 2.2 Add boss extra dice through a shared enemy value read by the attack actions (`enemies/*/*_attack_action.gd`, `melee_attack_action.gd`, `telegraphed_strike_action.gd`), flagged for bosses only (`EnemyStats.is_boss`, `EnemyAction.roll_attack`); verify a boss rolls 2d6 and a regular enemy still rolls 1d6.
- [x] 2.3 Confirm `die_sides` still reaches `take_damage` for scaled attacks; verify Brittle adds one die of the attack's size on a scaled boss hit.

## 3. Curve check and tuning

- [x] 3.1 Extend `tools/verify_enemy_scaling.gd` to print effective health, average hit and worst-case hit per enemy per act, and fail when the curve is not monotonic or a boss's worst hit in its own act reaches the player's starting maximum health (boss versus regular growth is printed for information); verified it passes.
- [x] 3.2 Tune the act values using `item-balance-report` output and the check; verify `tools/verify_act_enemies.tscn`, `verify_act_flow.tscn` and `verify_combat_pacing.tscn` still pass with the Godot console binary and record the final values in design.md.
