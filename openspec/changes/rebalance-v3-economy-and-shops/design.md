# Design

## Context

- See proposal.md for the playtest feedback. v2 values live in `reward_config.tres` (drop 0.35, pity 2, boss choice of 3, 2 shop relics, price x1.25) and in `shop_relic.gd` (`randi_range(90, 120)` for every rarity).
- Shop size before v2 was pure RNG (a tier of 1 to 3 giving 3, 4 or 5 relics). It never used the DDA score, so the DDA weighting is new behavior, not a revert.
- Gold today: battles 50-60 / 60-70, bosses 70-100 / 80-110 (in 33 `BattleStats` `.tres`), chest 40-50 hard-coded in `run.gd`, start gold `RunStats.STARTING_GOLD` = 70, Golden Clover +15-25, event gains 20-100 and costs 15-80 in event `.tres`.
- Shops are random rooms (about 10% of floors), so a run sees about one per act and gold piles up between visits.

## Goals / Non-Goals

**Goals:** enough relics that a run is winnable without perfect play; shop prices that follow rarity; mythic items as a visible, expensive splurge; gold events that matter; every number is data.
**Non-Goals:** enemy scaling (playtesters liked it), relic stats and the rarity budget, treasure and event rarity weights, guaranteeing a shop per act.

## Decisions

**Findings from the exploration simulation** (Python scratch model, 15k runs, route of 11 floors per act, greedy buyer; to be reproduced in `tools/simulate_rewards` during apply). "Wallet" is median gold at a shop visit; "commons" means the average common price of the column's price set.

| Income scale | Battle gold | Wallet | Can't buy everything | Mythic affordable when offered | Unspent at end | Relics at end of act 3 |
|---|---|---|---|---|---|---|
| 1.0 (v2) | 65 | about 10 commons | about 26% | 85% | 1300 | 29.5 |
| 0.67 | 43 | 5.5 | 45% | 69% | 726 | 28.1 |
| 0.55 | 36 | 4.2 | 56% | 59% | 546 | 27.3 |
| 0.45 | 29 | 3.2 | 66% | 48% | 407 | 26.4 |
| 0.33 | 21 | 2.2 | 81% | 33% | 267 | 25.0 |

1. **Income scale 0.5, not the 0.67 the dev suggested.** Cutting prices and income by the same factor is a pure rescale: relics at the end stay the same and the wallet stays at about 5 commons. Only the ratio of income to price creates tension, so income falls more than prices. Prices drop from 90-120 to about 55-85 for commons; income halves. Below about 0.4 events become hard to afford (4.5% of events unpayable at 0.33). Alternative: halve prices only. Rejected: it leaves the wallet large.
2. **Per-rarity price bands, not multipliers.** The base roll spans about 21%, larger than the 1.1x uncommon step, so multipliers let an uncommon cost less than a common. Default bands: common 55-70, uncommon 70-90, rare 95-125, mythic 170-230 (mythic about 3x a common). Multipliers of 1.1 / 1.25 / 1.5 on 55-85 put a mythic at about 104 gold (1.5 commons), affordable 85% of the time, which is not a splurge. Alternative: steeper multipliers. Rejected: the tiers still overlap and the numbers are harder to read.
3. **Mythic shop weight 5 to 8.** At 5% only 17% of shops show a mythic and about 0.25 are bought per run, so most players never see the splurge. Weights become common 38, uncommon 32, rare 22, mythic 8 (27% of shops, about 0.4 bought per run). Higher weights lower relic totals slightly and are a later tuning step.
4. **Shop size from the DDA score.** `dda_config` gets stock-size weights for three bands. Thresholds reuse `battle_high_score` (65) and `battle_low_score` (35). Defaults: strong 60/30/10 over 3/4/5, middle 25/50/25, weak 10/30/60. The scratch model used relic count as a stand-in for the score, so the effect is to be re-measured with the real score model; it is small either way (about 0.1 relics per visit). Fallback: pure RNG as before v2, if the score proves too noisy.
5. **Shop records its size.** `DDAState` gets `shop_offered_items`, set when the shop is generated; `decide_after_shop` compares `relic_count == entered_items + shop_offered_items` instead of the fixed `shop_all_bought_items`, which is removed. Alternative: keep a fixed count of 3. Rejected: buying 3 of a 5-relic shop would then count as buying everything.
6. **Boss: one default drop.** `boss_top_weights` is replaced by `boss_weights` = common 0, uncommon 40, rare 45, mythic 15. `boss_choices`, `add_relic_choice` and `_get_boss_relic_choices` are deleted. Boss gold scales with the income scale like every other source.
7. **Drop chance 0.6, pity 2.** Relics at the end of act 3 go from 24.6 at 0.35 to 27.3 at 0.6 (28.7 at 0.7), which offsets the relics lost by cutting gold (about 1.5 to 2). Drop chance moves item volume; income moves shop tension. They are tuned separately.
8. **One `income_scale` in `RewardConfig`.** Applied in `BattleStats.roll_gold_reward()` (battles and bosses, so the 33 `.tres` files stay untouched), the chest roll in `run.gd`, and positive event gold in `EventOutcome`. Event costs are not scaled, so events cost about twice as much relative to income, which is the intent. Alternative: edit every `.tres`. Rejected: 33+ files to retune on every change.
9. **Golden Clover** pays 8-13 extra gold (about half of 15-25). Left alone it would add about 60% to a battle's gold. It stays data on the relic.
10. **DDA gold thresholds** are halved with the economy: `battle_low_gold` 150 to 75, `broke_gold` 90 to 45. Left alone, the broke check would fire almost every time and the low-score shop offer would almost never fire.
11. **Verification runs headless.** Godot 4.6.2 lives at `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. `tools/run_suite.ps1` hardcodes a path from another machine, so it reads `$env:GODOT` first and falls back to the path above.

12. **Starting gold is 50, set directly.** After a full playtest run the scaled purse (35) was too tight, so `starting_gold` is its own value (50) and is not multiplied by the income scale. It buys about one common at the first shop and keeps the opening choices open. The simulated median first-shop wallet barely moves (226 to 232).
13. **The campfire before the boss is fixed for the difficulty system.** `Map.convert_rooms` skips the floor right before the boss (floor 12), as it already skips floors 0 and 13. The player's own reroll on that floor is unchanged.

## Simulation results (apply)

`tools/simulate_rewards.tscn` (4000 runs, real `RewardRules` and `DDA` rules on the route model; events and DDA room swaps are only partly modelled). Final numbers kept: income 0.5, drop 0.6 with pity 2, bands 55-70 / 72-90 / 95-125 / 170-230, shop rarity weights 38/32/22/8, boss weights 0/40/45/15, DDA shop-size weights 60/30/10, 25/50/25, 10/30/60 at scores 65 and 35.

| | v1 | v2 | current |
|---|---|---|---|
| Relics held at end of act 1 / 2 / 3 | 11.3 / 23.0 / 34.9 | 9.0 / 17.0 / 24.1 | 9.8 / 19.3 / 28.0 |
| Median gold at a shop visit | 473 (4.5 commons) | 698 (5.3) | 226 (3.6) |
| Median gold at the first shop of a run | 434 | 485 | 226 |
| Visits where the player cannot buy everything | 45% | 18% | 63% |
| Mythic offered / affordable when offered | 18% / 92% | 10% / 94% | 26% / 54% |
| Mythic bought per run | 0.54 | 0.29 | 0.44 |
| Gold unspent at the end of a run | 936 | 1473 | 465 |

- The task 5.1 targets hold without retuning: median wallet 3.6 commons (target about 3 to 4), mythic affordable in 54% of offers (about half) and 28.0 relics at the end of act 3 (at least about 27).
- Shop size: 51% of shops stock 3 relics, 35% stock 4 and 14% stock 5 (average 3.63). The simulated score climbs quickly because every relic adds to it, so most visits fall in the "strong" band. This is a model artifact until a playtest shows the real score distribution; the weights are data.
- DDA relic checks, act 1: battle shop-swap 95% (v2 90%, v1 99%) and treasure shop-swap 99% (v2 98%, v1 100%), so both stay within 10 points of the old rewards and no relic-count threshold changed. "Bought everything" fires in 8% of act-1 runs (v2 38%) and 40 to 48% in acts 2 and 3 (v2 about 64%), because a 3 to 5 relic shop is harder to clear at current prices. It stays behind the score gate (55) and the once-per-act flag.

## Risks / Trade-offs

- [Lower income cuts relics from shops by about 1.5 to 2] → raise the drop chance to 0.6 and re-read the simulation; both are data.
- [Gold still piles up: about 400 unspent at the end at scale 0.5, because there are only about three shops per run] → later: more gold sinks or more shops; out of scope here.
- [The shop size can be gamed by playing worse] → the bands are coarse and the effect is about 0.1 relics per visit.
- [Mythic at 170-230 is unaffordable in a first-act shop] → intended, it should be a goal; check the median first-visit wallet in the simulation.
- [The exploration model ignores events as relic sources, DDA room swaps and real routing] → treat results as trends; re-run in `tools/simulate_rewards` with the real rules before locking numbers.
- [`dda-relic-scoring` requires act-1 DDA shares within 10 points of the old rewards] → re-run the calibration and adjust thresholds if the new drop chance and income move them.

## Migration Plan

Config-only values plus small code changes. Old saves hold no shop size, so `shop_offered_items` defaults to 0 and the "bought everything" check simply does not fire for a shop entered before the update. Nothing else needs migrating. Roll back by restoring the v2 `reward_config.tres` and `dda_config.tres` values.

## Open Questions

- Final numbers (income scale, bands, weights, drop chance) are starting points; the playtest after apply decides whether they move. They do not change the tasks.
