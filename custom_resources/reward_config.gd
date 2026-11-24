class_name RewardConfig
extends Resource
## Every number that decides when and what battles, bosses and shops give.
## Retune in custom_resources/reward_config.tres without code edits.

@export_group("Regular battles")
## Chance that a tier-1 battle offers a relic.
@export_range(0.0, 1.0) var battle_drop_chance := 0.35
## After this many consecutive misses the next regular battle always drops (0 turns pity off).
@export var pity_misses := 2
## Chance that a tier-2 battle offers a relic.
@export_range(0.0, 1.0) var tier2_drop_chance := 1.0
## Extra share of gold a battle gives when it drops no relic (0.5 = +50%).
@export var miss_gold_bonus := 0.5

@export_group("Rarity weights (common, uncommon, rare, mythic)")
@export var tier1_weights := PackedInt32Array([50, 35, 15, 0])
@export var tier2_weights := PackedInt32Array([0, 55, 35, 10])
## The top relic a boss offers is rare or mythic by these weights.
@export var boss_top_weights := PackedInt32Array([0, 0, 70, 30])

@export_group("Bosses")
## Relics a boss offers (the player takes one).
@export var boss_choices := 3

@export_group("Shops")
@export var shop_relic_count := 2
@export var shop_price_multiplier := 1.25
