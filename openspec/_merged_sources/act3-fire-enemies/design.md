# Design

## Context

Same enemy model as Act 2: an `EnemyStats` resource plus an AI scene of `EnemyAction` nodes (conditional first, otherwise weighted), battles as small scenes with a `BattleStats` resource, pools as `BattleStatsPool`. `Enemy.take_damage` frees the enemy when health reaches 0, with no way to intercept that. `act_3_fire.tres` still points at Act 1's pool. See proposal.md for motivation. The prerequisite changes provide Scorch, Ashen, Sunder, spawning, fizzle, heal-allies and telegraph actions, and the act battle background.

## Goals / Non-Goals

**Goals:**
- Six enemies with one clear tactical problem each, a complete Act 3 pool, a safe boss floor.

**Non-Goals:**
- The Fire Dragon, art, balancing passes.

## Decisions

**1. First-guess numbers (data in `.tres`/scenes, retuned in the balancing pass).**

| Enemy | HP | Atk | Speed | Actions |
|---|---|---|---|---|
| Campfire (`enemies/living_flame/campfire.tres`, replaces the stub 26 HP) | 18 | 0 | 3 | Spawn Spirit (when under 2, every 2+ actions); Stoke (heal Spirits 6, when any damaged); Smolder (idle, weight 2) |
| Fire Spirit (`enemies/living_flame/flames.tres`, replaces the stub 13 HP, no longer one-shot) | 8 | 1 | 5 | Singe 1d4 + atk and Burn (1d4, 3 ticks); bound to the Campfire |
| Fire Salamander | 12 | 2 | 5 | Bite 1d6 + atk; Searing Hide (Scorch 1 to attackers; down after every 3rd action) |
| Fire Imp | 5 | 1 | 7 | Poke 1d4 + atk; Frenzy (Speed Up to survivors, cap 3) |
| Ashen Warrior | 24 | 3 | 4 | Sunder Strike 1d6 + atk + Sunder (weight 6); Rally (Attack Up to allies, 1 per 4 actions) |
| Phoenix | 22 | 2 | 6 | Gale 1d6 + atk + Scorch 1 (weight 6); Ember Dive 1d8 + atk (weight 3); ash pile 5 HP, revives at 60% after 6s |
| Magma Golem | 40 | 4 | 2 | 15 starting block; Prepare (+8 block) then Slam 2d8 + atk + Ashen; Cinder Punch 1d6 + atk (weight 5) |

**2. Battles.** Tier 0: 3 imps; Salamander + imp; 2 Salamanders. Tier 1: Campfire with 1 starting Spirit; Warrior + 2 imps; Salamander + 2 imps; Warrior + Salamander. Tier 2: Magma Golem; Phoenix + imp. Gold ranges equal Act 1's per tier.

**3. Burn for Spirits.** Spirits reuse the existing Burn status with reduced dice (1d4), keeping the "low damage, inflicts burn" identity without a new status.

**4. Searing Hide reacts to damage received.** The Salamander listens to its own `damage_received` signal (from the toolkit) and scorches the player; the hide flag flips on its action counter.

**5. Death intercept for the Phoenix.** `Enemy` gains a small `before_death` hook: an enemy script can veto the first lethal hit and swap into a different state. The Phoenix sets 5 health, `special_state = "ASH"`, disables its attacks and starts a 6 second timer in battle time (so it pauses with the battle). On expiry it heals to 60% and clears the state; a lethal hit while in ASH or after revival is not intercepted.

**6. Pool and boss floor.** `battles/map3/battle_stats_pool.tres` lists the 9 new battles plus Act 1's two tier 3 bosses as a temporary tier 3; `act3-boss-fire-dragon` replaces them. Act 3 gets its pool and `battle_background` (`bg_fogo_ato3.png`).

**7. Placeholder art.** Same one-off recolor script as Act 2 writes `art/placeholders/enemy_<name>.png`.

## Risks / Trade-offs

- [Campfire encounter drags on] → Spirits are small and the Campfire has 18 HP; tests simulate a fight and the balancing pass tunes spawn rate.
- [Phoenix ash timer pauses incorrectly during Freeze or pause] → Timer runs in battle time and is tested.
- [Searing Hide punishes every attack too much] → The hide drops every third action and Scorch decays; numbers are data.
- [A tier is empty and returns null] → The pool test requires every tier populated, including tier 3.

**8. Reuse of `enemies/living_flame/` (PR #39).** The half-built Campfire and Flames are the Campfire and Fire Spirit; no `enemies/campfire/` or `fire_spirit/` folders. Flames gets attack 1 and HP 8; `flames_burn_attack.gd` drops its `already_used` one-shot flag and uses a reduced-dice Burn variant; the empty `campfire_heal.gd` becomes the Stoke action (heal Spirits 6) on top of the summoning change's heal-allies action, and the Campfire gets an AI scene (spawn, Stoke, Smolder). The display name "Fire Spirit" is used in game text.
