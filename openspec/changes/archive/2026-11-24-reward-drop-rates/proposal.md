## Why

Every regular battle drops one relic (100%), the first battle guarantees a weapon plus a common, shops sell 3 relics and chests and events add more, so players pick their build every run and numbers feel too high. Fewer relics also lowers the difficulty score (DDA), which awards +1/+3/+5/+8 points per relic picked up by rarity and uses relic counts as thresholds (`battle_shop_swap_relics`, `shop_all_bought_items`, `treasure_shop_swap_relics`), so the two must be retuned together. Phoenix Feather is now consumed on use and can drop again, which the drop rules must account for.

## What Changes

- Regular tier-1 battles drop a relic with a configurable chance (start at about 45%) backed by a pity counter that guarantees a drop after N misses.
- Tier-2 battles always drop a relic. Bosses offer a choice of relics at different rarities. When no relic drops, the gold reward is raised as consolation.
- The first-battle guarantee (weapon plus common) stays as it is.
- Shops sell fewer relics and/or at higher prices (counts and price multiplier are config values).
- All numbers live in a new `RewardConfig` resource, not in `run.gd` and `shop.gd`.
- Retune `dda_config.tres` so relic-count thresholds and per-rarity scores match the new expected holdings, and state how consumed relics count.
- Treasure rooms and event relic rewards are unchanged.

## Capabilities

### New Capabilities
- `reward-drop-rates`: when and what battles, bosses and shops give.
- `dda-relic-scoring`: how the difficulty score counts relics picked up and held.

### Modified Capabilities

## Impact

- `scenes/run/run.gd` (`_show_regular_battle_rewards`, `_get_battle_reward_weights`), `scenes/shop/shop.gd`, `scenes/battle_reward/battle_reward.gd`, run save data (pity counter), `custom_resources/dda_config.tres`.
- New `custom_resources/reward_config.gd` and `.tres`; new `tools/verify_reward_drops.tscn`; `tools/verify_dda.gd` updated.
- Depends on `item-balance-report` (rarity counts per slot) and on the map layout (14 floors per act, treasure on floor 6, campfire on floor 12).
