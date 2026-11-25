# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import. Screenshots and short sequences: temporary scene in `tools/` run non-headless, deleted afterwards.

## 1. Test harness first

- [ ] 1.1 Add `tools/verify_combat_feedback.tscn` and script: lethal hit emits `enemy_died` and queues removal at the same time as without effects and leaves a ghost that frees itself; ready pulse starts and stops with `can_act`; block gain popup shows the amount actually gained (Ashen case); melee attack duration unchanged within 0.05 s; heavy-hit shake strength larger than for a light hit; tweens stop while the tree is paused. Verify: the feedback checks fail on the current code, and the timing baseline is recorded first.

## 2. Effects

- [ ] 2.1 Enemy death ghost fade and shrink. Verify: harness death check passes and `verify_enemy_summoning` still passes.
- [ ] 2.2 Ready pulse on the turn bar and ATTACK and BLOCK buttons. Verify: harness pulse check passes.
- [ ] 2.3 Block gain popup and stats row flash. Verify: harness block check passes, including Ashen (+4 from 9).
- [ ] 2.4 Attack anticipation easing in `MeleeAttackAction` without changing its duration. Verify: harness duration check passes and `verify_act_enemies` still passes.
- [ ] 2.5 Heavy-hit emphasis scaled by damage over max health. Verify: harness heavy-hit check passes.

## 3. Integration

- [ ] 3.1 Boot check and all suites. Verify: no script errors and every suite exits 0; no combat rule, effect value or ATB script changed except the listed visual hooks.
- [ ] 3.2 Look at short rendered sequences (death, ready pulse, block, attack) at real scale. Verify: effects are readable and not distracting; adjust amplitudes if not.
- [ ] 3.3 Manual playtest of two fights. Left to the user.

## Workflow follow-up

- Archive after review so `combat-feedback` becomes a main spec.
