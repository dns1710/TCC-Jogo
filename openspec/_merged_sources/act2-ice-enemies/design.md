# Design

## Context

Enemies are an `EnemyStats` resource (health, attack, speed, sprite, AI scene) plus an AI scene whose `EnemyAction` children define behavior; conditional actions fire first, otherwise a weighted pick. A battle is a small scene placing `Enemy` nodes plus a `BattleStats` resource (tier 0 to 3, weight, gold range); a `BattleStatsPool` lists them. Act 1 has 3 tier 0, 4 tier 1, 2 tier 2 and 2 tier 3 battles, and `acts/act_2_ice.tres` still points at Act 1's pool. See proposal.md for motivation. Prerequisite changes provide Freeze and Brittle (`combat-status-toolkit`) and telegraph, threshold and act-background support (`enemy-summoning-and-minions`).

## Goals / Non-Goals

**Goals:**
- Five enemies with one clear tactical problem each, a complete Act 2 pool, safe boss floor.

**Non-Goals:**
- Krampus, art, balancing passes, new engine features.

## Decisions

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

**6. Pool and boss floor.** `battles/map2/battle_stats_pool.tres` lists the 9 new battles plus Act 1's two tier 3 bosses as a temporary tier 3; `act2-boss-krampus` replaces them. Act 2 gets its pool and `battle_background` (`bg_neve_ato2.png`).

## Risks / Trade-offs

- [A tier is empty and `get_random_battle_for_tier` returns null] → The pool test requires every tier populated, including tier 3.
- [Banshee plus Brittle plus a pack hits too hard] → Numbers are first guesses; the balancing pass tunes them and the cases are covered by tests.
- [Placeholder sprites look identical in testing] → Distinct tints; names listed for the art developer.
- [Pack bonus miscounts after minions or deaths] → Counted live from the handler at attack time and tested with deaths mid-fight.
