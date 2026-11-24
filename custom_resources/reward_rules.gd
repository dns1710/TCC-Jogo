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
	var drops := pity or roll < chance
	run_stats.relic_drop_misses = 0 if drops else run_stats.relic_drop_misses + 1
	return drops


## Gold a battle gives when it drops no relic.
static func miss_gold(config: RewardConfig, gold: int) -> int:
	return gold + roundi(gold * config.miss_gold_bonus)
