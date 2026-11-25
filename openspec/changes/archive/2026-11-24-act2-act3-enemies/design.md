# Design

## Context

Merged from the four Act 2/3 enemy changes. Enemies are an `EnemyStats` resource plus an AI scene of `EnemyAction` children (conditional actions first, otherwise weighted); battles are small scenes plus `BattleStats`, grouped in a `BattleStatsPool`. The toolkit (Freeze, Brittle, Scorch, Ashen, Sunder, per-source slows) and the summoning engine (`spawn_enemy`, fizzle, `HealAlliesAction`, `SummonAction`, `TelegraphAction`/`TelegraphedStrikeAction`, `ThresholdAction`, act battle background) are already applied. Spawn slots sit at y 68 to 98, so hand-placed battles use that band too.

## Goals / Non-Goals

**Goals:** twelve enemies and two bosses, each with one clear tactical problem; complete pools for both acts with no empty tier.

**Non-Goals:** balancing passes, final art, new engine features beyond the Phoenix death hook.

## Merge notes

- No temporary tier 3: pools go directly to Krampus and the Fire Dragon.
- Campfire and Fire Spirit live in `enemies/living_flame/` (existing PR #39 files: `campfire.tres`, `flames.tres` = Fire Spirit, `flames_burn_attack.gd` loses its one-shot flag, `campfire_heal.gd` becomes Stoke).
- One test harness (`tools/verify_act_enemies.tscn`) covers all four specs.

## Act 2 enemies (Ice)

**1. First-guess numbers (all data in `.tres`/scenes, retuned in the balancing pass).**

| Enemy | HP | Atk | Speed | Actions |
|---|---|---|---|---|
| Snow Wolf pup | 8 | 1 | 6 | Bite 1d4 + atk + pack bonus |
| Snow Wolf Alpha | 14 | 2 | 5 | Bite 1d6 + atk + pack bonus; Howl (Speed Up to wolves, 1 per 4 actions) |
| Ice-Crystal Spider | 14 | 2 | 6 | Web (Speed Down x2, weight 4); Crystal Bite 1d6 + atk, x1.5 vs slowed (weight 6) |
| Snow Golem | 30 | 3 | 2 | Pack Snow (+4 block, cap 20, weight 6); Snowball 1d4 + atk (weight 4); Avalanche 2d8 + atk at 20 block |
| Banshee | 16 | 1 | 5 | Haunt (Brittle, weight 5); Chill Touch 1d4 + atk (weight 3); Frost Wail (Freeze, only vs Brittle, 1 per 5 actions) |
| Yeti | 36 | 4 | 4 | Claw 1d8 + atk; Prepare then Ground Pound 2d8 + atk + Speed Down x2; Roar at 50% (Attack Up +3, slow-immune) |

**2. Battles.** Tier 0: 2 pups; pup + spider; 3 pups. Tier 1: Alpha + 2 pups; Golem + spider; Banshee + 2 pups; 2 spiders + Banshee. Tier 2: Yeti; Golem + Banshee. Gold ranges equal Act 1's per tier.

**3. Pack bonus by a small passive.** A wolf counts living wolves through the enemy handler at attack time (no stored state), so deaths take effect immediately.

**4. Banshee and Freeze.** Freeze on the player is short and gated (needs Brittle, once per 5 actions) so it is a rare punishment, not a lock; this follows the playtest feedback that long slows feel bad.

**5. Placeholder art.** A one-off script writes recolored copies of existing sprites to `art/placeholders/enemy_<name>.png`; enemy stats point at them. Final art replaces the files or the stats' `art`.

**6. Pool and boss floor.** `battles/map2/battle_stats_pool.tres` lists the 9 new battles plus Act 1's two tier 3 bosses as a temporary tier 3; Krampus is Act 2's tier 3 directly. Act 2 gets its pool and `battle_background` (`bg_neve_ato2.png`).

**Risks:**

- [A tier is empty and `get_random_battle_for_tier` returns null] → The pool test requires every tier populated, including tier 3.
- [Banshee plus Brittle plus a pack hits too hard] → Numbers are first guesses; the balancing pass tunes them and the cases are covered by tests.
- [Placeholder sprites look identical in testing] → Distinct tints; names listed for the art developer.
- [Pack bonus miscounts after minions or deaths] → Counted live from the handler at attack time and tested with deaths mid-fight.

## Krampus

**1. First-guess stats.** HP 90, attack 4, speed 4, Freeze-immune. Birch Switch: two hits of 1d4 + atk (weight 6). Chain Pull: Speed Down x3 and Brittle (weight 4). Winter's Wrath: prepare, then 3d8 + atk and a short Freeze. Gold 80 to 110. All in data.

**2. Phases by threshold actions, not a state machine.** Phase 2 and 3 are `ThresholdAction`s (once each at 50% and 25%) that set `special_state` (`PHASE2`, `PHASE3`); conditional actions check the state. Phase 3's Speed Up is applied by the phase 3 threshold action. This reuses the Bear boss pattern.

**3. Summon rule.** A `SummonAction` limited by alive count (2) and a 3-action cooldown, conditional on `PHASE2` or later. Alternative: summon once; rejected, respawning wolves keep pressure after the player clears them.

**4. Wrath cadence.** A counter of Krampus's own actions makes every third action Winter's Wrath in phase 3, as a conditional prepare action followed by the strike (the strike requires the prepare state, like the Bomb).

**5. Replace the temporary tier 3.** `battles/map2/battle_stats_pool.tres` drops the two Act 1 bosses for the Krampus battle.

**Risks:**

- [Freeze from Winter's Wrath feels bad] → It is short, telegraphed, and the player has a full bar to react (for example by blocking); numbers are tunable.
- [Wolves plus Chain Pull plus Wrath overwhelm] → Cap of 2 wolves and a 3-action cooldown; balancing pass may lower damage.
- [Thresholds crossed in one hit (jump from above 50% to below 25%)] → Both phase actions are performable in order; tests cover a big hit across both thresholds.

## Act 3 enemies (Fire)

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

**6. Pool and boss floor.** `battles/map3/battle_stats_pool.tres` lists the 9 new battles plus Act 1's two tier 3 bosses as a temporary tier 3; the Fire Dragon is Act 3's tier 3 directly. Act 3 gets its pool and `battle_background` (`bg_fogo_ato3.png`).

**7. Placeholder art.** Same one-off recolor script as Act 2 writes `art/placeholders/enemy_<name>.png`.

**Risks:**

- [Campfire encounter drags on] → Spirits are small and the Campfire has 18 HP; tests simulate a fight and the balancing pass tunes spawn rate.
- [Phoenix ash timer pauses incorrectly during Freeze or pause] → Timer runs in battle time and is tested.
- [Searing Hide punishes every attack too much] → The hide drops every third action and Scorch decays; numbers are data.
- [A tier is empty and returns null] → The pool test requires every tier populated, including tier 3.

**8. Reuse of `enemies/living_flame/` (PR #39).** The half-built Campfire and Flames are the Campfire and Fire Spirit; no `enemies/campfire/` or `fire_spirit/` folders. Flames gets attack 1 and HP 8; `flames_burn_attack.gd` drops its `already_used` one-shot flag and uses a reduced-dice Burn variant; the empty `campfire_heal.gd` becomes the Stoke action (heal Spirits 6) on top of the summoning change's heal-allies action, and the Campfire gets an AI scene (spawn, Stoke, Smolder). The display name "Fire Spirit" is used in game text.

## Fire Dragon

**1. First-guess stats.** HP 90, attack 5, speed 4, Freeze-immune. Claw 2d6 + atk (weight 6). Fire Breath: prepare, then 3d6 + atk and Scorch x2 (weight 4 for the prepare). Gold 80 to 110. All in data.

**2. Phases by threshold actions.** Phase 2 (60%) and phase 3 (30%) are `ThresholdAction`s that set `special_state` (`PHASE2`, `PHASE3`) and perform their one-time effect (Roar; Speed Up x2). Because thresholds have priority over ordinary actions, a hit crossing both thresholds still performs the Roar first and the phase 3 action on the following action.

**3. Summon rule.** The same `SummonAction` as Krampus (cap 2, 4-action cooldown), conditional on `PHASE2` or later.

**4. Ember Field.** In `PHASE3`, the Dragon's action-completed hook applies Scorch 1 to the player; implemented as a small status or listener on the Dragon so it reads in the status row ("Ember Field").

**5. Replace the temporary tier 3.** `battles/map3/battle_stats_pool.tres` drops the two Act 1 bosses for the Fire Dragon battle.

**Risks:**

- [Ember Field plus Breath plus imps is too much damage] → Numbers are first guesses; Scorch decays by stacks, and the balancing pass can lower Breath damage or Ember Field's stacks.
- [Roar buffs the Dragon but nothing else is alive] → Roar still applies to the Dragon itself; it gives value even alone.
- [Thresholds crossed in one hit] → Tests cover a single hit across both thresholds.

