# Design

## Context

Existing feedback: `Shaker.shake` (position jitter), `Popup` labels that rise and fade, a white sprite material flash on hit, `RedFlash` on the player, a scale-in tween for spawned enemies, and attack dashes built from tweens in the enemy action scripts (about 0.4 s in, 0.25 s hold, 0.4 s out). `Enemy.take_damage` frees the enemy right after its hit tween when health reaches 0, after emitting `Events.enemy_died`; `EnemyHandler`, `ATBManager` and the new summoning logic rely on `is_queued_for_deletion` and on the died event timing, so deaths must not be delayed. The player bar is a `TextureProgressBar`; buttons live in `BattleUI`. See proposal.md.

## Goals / Non-Goals

**Goals:**
- A handful of small visual effects that make fights clearer, with zero logic impact.

**Non-Goals:**
- Particle systems, new art or audio, any gameplay change.

## Decisions

**1. Death on a ghost.** At the moment the enemy frees itself, create a `Sprite2D` copy (texture, position, scale, flip) as a child of the battle (the enemy's grandparent), tween it to fade and shrink over about 0.3 s, then free it. The enemy node itself is freed exactly as today. Alternative: delay `queue_free` and play the tween on the enemy; rejected, it would keep dead enemies in `EnemyHandler` and delay battle end.

**2. Ready pulse as a small node.** A `ReadyPulse` helper tweens `modulate` brightness on the player's `ATBProgress` and on the two buttons in a looping 0.6 s ease while `player.can_act` is true and kills the tween when it becomes false. It reads state only (`player.can_act`) in `_process` of `BattleUI` (or its own node), with no new signals.

**3. Block feedback at the effect.** `BlockEffect.execute` already computes the gained amount (`floori(amount * multiplier)`); after applying it, spawn a popup "+N" (reusing `Popup` and the existing `_spawn_popup` on actors) and play a brief modulate flash on the target's `StatsUI`. No change to the value added to `stats.block`.

**4. Anticipation by easing, not by adding time.** In the dash tweens, change the first move from a quint ease to a back-in-out ease (`TRANS_BACK`, `EASE_IN_OUT` or an explicit small reverse step inside the first 0.4 s), so the pull back is part of the existing duration. A test measures the action duration before and after. Older actions (`zscout`, `onca`, `croc`, bombs, bosses) keep their scripts; only the shared `MeleeAttackAction` and a common helper are changed first, others opt in later.

**5. Heavy hits.** In `Enemy.take_damage` and `Player.take_damage` the existing `Shaker.shake(self, 16, 0.15)` strength becomes a function of damage over max health (16 normally, up to about 24 at 25% or more) and the flash lasts slightly longer. This uses values already available and changes no state.

**6. Pausing.** All new tweens are created from nodes with default process mode so they stop when the tree is paused (the tutorial and pause menu pause the tree).

## Risks / Trade-offs

- [Effects accidentally delay actions] → A test records `enemy_action_completed` timing for a melee action and the time of `enemy_died` relative to the lethal hit, before and after; both must match within 0.05 s.
- [Ghost sprites leak or stay on screen] → Each ghost frees itself on tween finish and when its parent leaves the tree.
- [Pulses look noisy on top of the HUD change] → Keep pulses subtle (about 15% brightness) and coordinate with `battle-hud-polish` so the armed highlight and the ready pulse do not fight.
- [Heavy-hit emphasis on a single big boss hit every time] → Threshold is relative to max health, so bosses with large pools rarely trigger it.
