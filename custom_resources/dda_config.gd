class_name DDAConfig
extends Resource
## Every number the difficulty adjustment uses. Defaults are the values the game
## shipped with; retune them in custom_resources/dda_config.tres without code edits.

@export_group("Score from a battle (HP left, in percent)")
## Finishing at or below these HP percentages lowers the score by the matching delta.
@export var battle_low_thresholds := PackedInt32Array([5, 25, 45])
@export var battle_low_deltas := PackedInt32Array([-10, -8, -5])
## Finishing at or above these percentages raises it.
@export var battle_high_thresholds := PackedInt32Array([95, 75, 55])
@export var battle_high_deltas := PackedInt32Array([10, 8, 5])
## Anything in between.
@export var battle_mid_delta := 2

@export_group("Score from arriving at a campfire (HP before resting)")
## Arriving above these HP percentages raises the score. Arriving low uses the battle low bands.
@export var campfire_high_thresholds := PackedInt32Array([90, 80, 70, 60, 50])
@export var campfire_high_deltas := PackedInt32Array([8, 7, 6, 5, 4])

@export_group("Score from relics (by rarity: common, uncommon, rare, mythic)")
@export var relic_rarity_scores := PackedInt32Array([1, 3, 5, 8])

@export_group("Room conversions")
@export var tier2_upgrade_score := 75
## HP share that counts as "healthy".
@export var hp_split := 0.5

@export var battle_high_score := 65
@export var battle_low_score := 35
@export var battle_shop_swap_relics := 6
@export var battle_low_gold := 75

@export var campfire_high_score := 70
@export var campfire_low_score := 30

@export var shop_swap_score := 55
@export var shop_swap_relics_after_shop := 6
@export var broke_gold := 45
@export var broke_very_low_score := 15
@export var broke_low_score := 35

@export var treasure_high_score := 70
@export var treasure_shop_swap_relics := 4

@export_group("Shop size (3, 4 or 5 relics) by score")
## Score at or above this: the run is doing well, shops lean small.
@export var shop_size_high_score := 65
## Score at or below this: the run is struggling, shops lean large.
@export var shop_size_low_score := 35
@export var shop_size_weights_high := PackedInt32Array([60, 30, 10])
@export var shop_size_weights_mid := PackedInt32Array([25, 50, 25])
@export var shop_size_weights_low := PackedInt32Array([10, 30, 60])
## Smallest shop; the weights above are for this size, this size + 1, and so on.
@export var shop_size_min := 3
