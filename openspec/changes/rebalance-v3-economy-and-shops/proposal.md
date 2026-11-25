# Proposal

## Why

Playtesters of `rebalancing-v2` say the game is nearly unwinnable and "miserable" when under-itemized, while the enemy scaling felt good. The cause is item supply, not enemies: relic drops fell to 35% per battle, bosses give a choice of one, and shops shrank to 2 relics at a flat price that ignores rarity (the Needle costs the same as a common). A simulation of the run economy also shows gold piling up (about 700 gold at a shop, about 1400 unspent at the end), so prices never create a decision and mythic items cannot feel like a splurge.

## What Changes

- Restore the item supply to a level between v1 and v2: higher regular drop chance (0.6, pity 2), and bosses go back to one default drop with better rarity weights instead of "choose 1 of 3".
- Shops go back to 3, 4 or 5 relics. The count is a random roll weighted by the DDA score: strong, well-played runs get smaller shops, weak runs get larger ones.
- Shop prices follow rarity through per-rarity price bands that do not overlap, with mythic items priced as a splurge (about 3 times a common). The flat v2 price multiplier is removed.
- Mythic items show up in shops more often (weight 5% to 8%), so the splurge is actually seen.
- Gold income is cut to about half (battles, bosses, chests, gold from events, starting gold) so a mythic costs roughly half to all of a typical wallet and gold events matter. Event costs stay as they are.
- DDA gold thresholds and the "bought everything" check follow the new economy and the variable shop size.
- **BREAKING**: removes `boss_choices`, `shop_relic_count` and `shop_price_multiplier` from the reward configuration, and the boss choice screen.

## Capabilities

### New Capabilities
- `shop-offers`: how many relics a shop stocks (3 to 5, weighted by DDA score), which rarities it rolls, and the price of each relic by rarity.
- `gold-economy`: how much gold the run pays out and starts with, as one scale applied to every gold source, and the DDA gold thresholds that must move with it.

### Modified Capabilities
- `reward-drop-rates`: boss reward becomes a single drop instead of a choice of several; the fixed 2-relic, flat-multiplier shop requirement is removed (replaced by `shop-offers`).
- `dda-relic-scoring`: "bought everything" compares against the number of relics the shop actually offered, since shop size now varies.

## Impact

- Code: `custom_resources/reward_config.gd` and `.tres`, `custom_resources/dda_config.gd` and `.tres`, `custom_resources/dda.gd` (`decide_after_shop`), `custom_resources/dda_state.gd`, `custom_resources/run_stats.gd` (starting gold), `custom_resources/battle_stats.gd` (gold roll), `scenes/shop/shop.gd`, `scenes/shop/shop_relic.gd`, `scenes/run/run.gd` (boss reward, chest gold), `scenes/battle_reward/battle_reward.gd` (remove choice UI), `custom_resources/events/event_outcome.gd` (gold gains), `relics/trinket/golden_clover.gd`.
- Tools: `tools/simulate_rewards.gd` gains the new economy model; `tools/verify_reward_drops.gd`, `tools/verify_dda.gd` updated.
- Tuning source: the economy simulation done while exploring this change (Python scratch model, to be reproduced in `tools/simulate_rewards`).
- Unchanged: enemy scaling, relic stats, treasure rarity weights, first-battle guarantee, event costs.
