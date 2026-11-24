# Design

## Context

- `run.gd::_show_regular_battle_rewards` always adds gold plus one relic from `_get_random_relic_reward` with weights from `_get_battle_reward_weights(tier)`: tier 1 is 50/35/15 (common/uncommon/rare), tier 2 is 55/35/10 (uncommon/rare/mythic). The pool excludes relics the player already holds.
- Shop rarity weights start at common 40, uncommon 35. Shops sell 3 relics; chests give a relic plus 40-50 gold.
- DDA scores a relic by rarity (`relic_rarity_scores` = 1/3/5/8) and uses held-relic counts (`get_all_relics().size()`) in the shop-swap and treasure checks.
- A map act has 14 floors with a treasure floor and a pre-boss campfire; the number of battles per act is random, so expected relics per run must be measured, not assumed.

## Goals / Non-Goals

**Goals:** a run ends with a smaller, more varied set of relics; every rate is data; DDA stays calibrated.
**Non-Goals:** changing relic stats (`item-balance-pass`), enemy strength (`enemy-scaling`), treasure and event rewards.

## Decisions

- **`RewardConfig` resource** holds `battle_drop_chance` (0.35), `pity_misses` (2), `tier2_drop_chance` (1.0), `boss_choices` (3), `miss_gold_bonus` (+50%), `shop_relic_count` (2), `shop_price_multiplier` (1.25) and the rarity weights. Alternative (constants in `run.gd`) repeats the problem DDA already solved with `dda_config.tres`.
- **Pity counter** is stored in run stats, increments on a regular-battle miss, resets on any drop, and is saved with the run. Alternative (pure random) allows long droughts that make a run unwinnable.
- **Boss choice** = offer `boss_choices` relics of different rarities (at least one rare or mythic) and let the player take one. Assumption: "a choice of rarity" in the roadmap means choose among rarities. A consumed relic (Phoenix Feather) is back in the pool because the pool skips only relics currently held.
- **Miss consolation** is gold, shown on the reward screen as a gold reward only.
- **DDA retune** works from simulated holdings: run the drop logic over many generated maps, record relics held at each shop and treasure, and set thresholds so a median run triggers the same share of swaps as today. Per-rarity scores stay unless the simulation shows the score range collapsing. Consuming a relic does not remove points already earned; held-count checks use the live count.

## Simulation results (apply)

`tools/simulate_rewards.tscn` (4000 runs, route model, real drop rules; events and DDA room swaps not modelled):

| | act 1 end | act 2 end | act 3 end |
|---|---|---|---|
| Relics held, old rewards | 10.3 | 21.8 | 33.6 |
| Relics held, new rewards (0.35 / pity 2 / boss choice / 2 shop relics x1.25) | 8.8 | 16.9 | 24.0 |

- Held-relic counts are cumulative, so the battle and treasure shop-swap checks (6 and 4) are already true in act 2 and 3 under both rewards. They only separate players in act 1, where the new share is 89% against 98% (9 points, close to the limit) and 98% against 99%: within 10 points, so those thresholds stay.
- "Bought everything on offer" was `== 3` against shops of 3 to 5 relics, so it fired about 20 to 29% of the time. With a fixed 2-relic shop it is set to 2 (`shop_all_bought_items`), and it now fires more often (36% in act 1, about 64% later) because buying both is easier. The price multiplier barely moves it (x2.0 still gives 24% in act 1), because gold piles up. This is a known difference and stays in the DDA score gate (score >= 55) and the once-per-act flag.
- The new rewards cut relics held by about 29% at the end of a run (24.0 against 33.6), not by half. Chests (guaranteed uncommon or better) and shop purchases are the other sources; lowering them or the drop chance further is a decision for the owner.

Final numbers kept: drop chance 0.35 (owner's call after the first simulation at 0.45), pity 2, tier 2 always, boss choice of 3, 2 shop relics, price x1.25, DDA `shop_all_bought_items` 2, other DDA thresholds and rarity scores unchanged.

## Risks / Trade-offs

- [45% may starve early acts] → pity counter plus the first-battle guarantee; the config makes it a data change.
- [Run saves from before the change lack the pity counter] → default 0 on load.
- [Fewer shop relics make gold pile up] → price multiplier and shop count are tuned together after the simulation.

## Open Questions

- Final values for drop chance, pity length and shop prices are set from the simulation during apply; the structure above does not change.
