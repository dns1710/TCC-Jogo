class_name RewardConfig
extends Resource
## Every number that decides when and what battles, bosses and shops give.
## Retune in custom_resources/reward_config.tres without code edits.

@export_group("Regular battles")
## Chance that a tier-1 battle offers a relic.
@export_range(0.0, 1.0) var battle_drop_chance := 0.6
## After this many consecutive misses the next regular battle always drops (0 turns pity off).
@export var pity_misses := 2
## Chance that a tier-2 battle offers a relic.
@export_range(0.0, 1.0) var tier2_drop_chance := 1.0
## Extra share of gold a battle gives when it drops no relic (0.5 = +50%).
@export var miss_gold_bonus := 0.5

@export_group("Rarity weights (common, uncommon, rare, mythic)")
@export var tier1_weights := PackedInt32Array([50, 35, 15, 0])
@export var tier2_weights := PackedInt32Array([0, 55, 35, 10])
## A boss always drops one relic, rolled by these weights.
@export var boss_weights := PackedInt32Array([0, 40, 45, 15])

@export_group("Gold")
## Multiplies every gold payout (battles, bosses, chests, gold gained in events, starting gold).
## Costs (events, shops) are not scaled, so a lower scale makes gold scarcer.
@export_range(0.1, 2.0) var income_scale := 0.5
## Gold a new run starts with, before the income scale.
@export var base_starting_gold := 70

@export_group("Shops")
## Rarity weights for each relic a shop stocks (common, uncommon, rare, mythic).
@export var shop_rarity_weights := PackedInt32Array([38, 32, 22, 8])
## Price band per rarity as min, max pairs (common, uncommon, rare, mythic). Bands must not overlap.
@export var shop_price_bands := PackedInt32Array([55, 70, 72, 90, 95, 125, 170, 230])
