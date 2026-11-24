# Tasks

## 1. Configuration and simulation baseline

- [x] 1.1 Replace `boss_choices`, `boss_top_weights`, `shop_relic_count` and `shop_price_multiplier` in `reward_config.gd` / `.tres` with `boss_weights`, `income_scale` 0.5, `shop_rarity_weights` and `shop_price_bands`, and set `battle_drop_chance` to 0.6; verify the resource loads headless with the defaults.
- [x] 1.2 Add shop-size weights and their score thresholds to `dda_config.gd` / `.tres`, remove `shop_all_bought_items`, and halve `battle_low_gold` and `broke_gold`; verify the config loads headless (the DDA suite passes after 4.3).
- [x] 1.3 Make `tools/run_suite.ps1` read `$env:GODOT` and fall back to `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`; verify `run_suite.ps1 verify_reward_drops` starts Godot.
- [x] 1.4 Extend `tools/simulate_rewards.gd` with the new model (shop stock by score, rarity bands, income scale) and the report fields from the gold-economy spec; verify it runs and prints median wallet in commons, can't-buy-everything share, mythic affordability and unspent gold.

## 2. Gold income

- [x] 2.1 Apply `income_scale` in `BattleStats.roll_gold_reward()`, the chest roll in `run.gd`, and starting gold; verify a 60-70 gold battle pays 30-35 at scale 0.5 and a new run starts with half the v2 purse.
- [x] 2.2 Scale positive event gold in `EventOutcome` and leave costs untouched; verify with a seeded event test that a +50 outcome gives +25 and a 40-gold cost stays 40.
- [x] 2.3 Set Golden Clover to 8-13 extra gold; verify with a relic test that a won battle adds that range.

## 3. Boss and battle rewards

- [x] 3.1 Boss reward gives gold plus one relic rolled with `boss_weights`; remove `add_relic_choice`, `_on_relic_choice_taken` and `_get_boss_relic_choices`; verify 200 seeded boss rolls never return a common and give a higher rare and mythic share than tier 2.
- [x] 3.2 Update `tools/verify_reward_drops.gd` for the boss drop, the new drop chance and the removed shop requirement; verify `REWARD DROPS CHECK OK`.

## 4. Shops

- [x] 4.1 Roll the stock size (3 to 5) from `dda_score` with the DDA weights and record it in `DDAState.shop_offered_items`; verify seeded shops at score 80, 50 and 20 favor 3, 4 and 5, and that a small pool stocks only what exists.
- [x] 4.2 Roll rarity with `shop_rarity_weights` and price each relic in the band of its rarity in `shop.gd` / `shop_relic.gd`, removing the flat multiplier; verify bands never overlap and a mythic costs at least 170.
- [x] 4.3 Make `DDA.decide_after_shop` compare against `shop_offered_items`; verify the 3-of-3, 2-of-2 and 3-of-5 cases in `tools/verify_dda.gd`.
- [x] 4.4 Confirm the Coupons relic discount still applies on top of banded prices; verify one price before and after buying Coupons.

## 5. Calibration and playtest handoff

- [x] 5.1 Run the simulation and check the median wallet at a shop is about 3 to 4 commons, mythic is affordable in about half of the offers and relics at the end of act 3 are at least about 27; retune data values if not and record the final numbers in design.md.
- [x] 5.2 Re-check the DDA relic-count calibration (act-1 shares within 10 points of the old rewards) and run the full verify suite headless; verify every suite passes.
- [x] 5.3 Start the game, play the first act through a shop and a boss; verify the shop shows 3 to 5 relics with banded prices and the boss reward shows exactly one relic.
