# Tasks

## 1. Configuration

- [x] 1.1 Create `custom_resources/reward_config.gd` and `reward_config.tres` with the fields in design.md; verify the resource loads headless with the default values.
- [x] 1.2 Add the pity counter to run stats, default 0 for older saves, saved and loaded with the run; verify with a save and load round trip in `tools/verify_reward_drops.gd`.

## 2. Battle, boss and first-battle rewards

- [x] 2.1 Make `run.gd::_show_regular_battle_rewards` roll the drop chance, apply pity, and add the miss gold bonus; verify with a seeded test that a miss shows gold only and the pity-th miss forces a relic.
- [x] 2.2 Tier-2 always drops using tier-2 weights; verify over 200 seeded rolls that every tier-2 battle has a relic of uncommon or higher.
- [x] 2.3 Boss reward offers `boss_choices` relics of different rarities, taking one removes the rest; verify the reward screen has one relic left selectable after a pick.
- [x] 2.4 Confirm the first-battle guarantee is untouched; verify the first reward is a weapon plus a common non-weapon with the drop chance forced to 0.

## 3. Shops

- [x] 3.1 Read `shop_relic_count` and `shop_price_multiplier` in `shop.gd`; verify the generated shop has the configured count and prices.

## 4. DDA calibration

- [x] 4.1 Write a headless simulation (`tools/simulate_rewards.tscn`, a route model with the generator's room mix, not generated maps) that plays the real drop logic to record relics held at each shop and treasure; verify it prints the share of runs reaching each DDA relic-count threshold before and after the change.
- [x] 4.2 Retune `dda_config.tres` (`shop_all_bought_items` = shop size; other thresholds checked and kept, rarity scores unchanged); verified with the simulation (act-1 shares within 10 points) and `tools/verify_dda.tscn`.
- [x] 4.3 Confirm consumed relics keep their score and live counts are used; verify with a `verify_dda.gd` case that picks up and consumes a relic.
- [x] 4.4 Set final drop chance, pity length, shop count and prices from the simulation and record the chosen numbers in design.md; verify the reward and DDA suites pass with the Godot console binary.
