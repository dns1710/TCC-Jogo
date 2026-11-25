class_name RewardRules
extends RefCounted
## The decisions behind battle and boss rewards, kept free of scenes so they can be tested.

## Rarity weights as a dictionary {rarity: weight}, leaving out zero weights.
static func weights_from(values: PackedInt32Array) -> Dictionary:
	var out := {}
	for rarity in values.size():
		if values[rarity] > 0:
			out[rarity] = values[rarity]
	return out


static func regular_weights(config: RewardConfig, tier: int) -> Dictionary:
	return weights_from(config.tier2_weights if tier == 2 else config.tier1_weights)


## Decides whether a won battle offers a relic and updates the pity counter.
## `roll` (0..1) can be passed for tests; otherwise the run's seeded RNG is used.
static func battle_drops_relic(config: RewardConfig, tier: int, run_stats: RunStats, roll := -1.0) -> bool:
	var chance := config.tier2_drop_chance if tier == 2 else config.battle_drop_chance
	var pity := config.pity_misses > 0 and run_stats.relic_drop_misses >= config.pity_misses
	if roll < 0.0:
		roll = RNG.instance.randf()
	var weak := config.weak_drop_score >= 0 and run_stats.dda_score <= config.weak_drop_score
	var drops := pity or weak or roll < chance
	run_stats.relic_drop_misses = 0 if drops else run_stats.relic_drop_misses + 1
	return drops


## Gold a battle gives when it drops no relic.
static func miss_gold(config: RewardConfig, gold: int) -> int:
	return gold + roundi(gold * config.miss_gold_bonus)


## A gold payout after the income scale. Never below 1 for a positive payout.
static func scale_gold(config: RewardConfig, amount: int) -> int:
	if amount <= 0:
		return amount
	return maxi(1, roundi(amount * config.income_scale))


static func starting_gold(config: RewardConfig) -> int:
	return config.starting_gold


## Index of a weighted pick. `roll` (1..sum) can be passed for tests.
static func weighted_index(weights: PackedInt32Array, roll := -1) -> int:
	var total := 0
	for weight in weights:
		total += maxi(weight, 0)
	if total <= 0:
		return 0
	if roll < 1:
		roll = RNG.pick_random(1, total)
	for i in weights.size():
		roll -= maxi(weights[i], 0)
		if roll <= 0:
			return i
	return weights.size() - 1


## A shop price inside the band of the rarity. `roll` can be passed for tests.
static func shop_price(config: RewardConfig, rarity: int, roll := -1) -> int:
	var low := config.shop_price_bands[rarity * 2]
	var high := config.shop_price_bands[rarity * 2 + 1]
	if roll < 0:
		roll = RNG.pick_random(low, high)
	return clampi(roll, low, high)
