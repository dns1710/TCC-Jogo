class_name DDA
extends RefCounted
## Dynamic difficulty adjustment: reads how the player is doing (one 0..100 score)
## and decides which upcoming rooms to convert. Pure decisions: it returns
## DDAConversions and the run executes them, so it can be tested without scenes.

const MAX_SCORE := 100
const MIN_SCORE := 0

var config: DDAConfig = preload("res://custom_resources/dda_config.tres")


# ---------------------------------------------------------------- score

## The one way the score changes. Clamps to 0..100 and records the reason.
static func change_score(run_stats: RunStats, amount: int, reason: String) -> int:
	if amount == 0:
		return 0

	var before := run_stats.dda_score
	run_stats.dda_score = clampi(before + amount, MIN_SCORE, MAX_SCORE)
	var applied := run_stats.dda_score - before
	run_stats.dda_state.record(reason, applied, run_stats.dda_score)
	return applied


func relic_score(rarity: int) -> int:
	if rarity < 0 or rarity >= config.relic_rarity_scores.size():
		return 0
	return config.relic_rarity_scores[rarity]


func update_score_battle(current_health: int, max_health: int, run_stats: RunStats) -> void:
	if max_health <= 0:
		return
	var hp_percentage := float(current_health) / float(max_health) * 100.0
	change_score(run_stats, battle_score_delta(hp_percentage), "battle")


## Called when the player arrives at a campfire, before resting.
func update_score_campfire(current_health: int, max_health: int, run_stats: RunStats) -> void:
	if max_health <= 0:
		return
	var hp_percentage := float(current_health) / float(max_health) * 100.0
	change_score(run_stats, campfire_score_delta(hp_percentage), "campfire")


func battle_score_delta(hp_percentage: float) -> int:
	var low_delta := _low_band_delta(hp_percentage)
	if low_delta != 0:
		return low_delta

	for i in config.battle_high_thresholds.size():
		if hp_percentage >= config.battle_high_thresholds[i]:
			return config.battle_high_deltas[i]
	return config.battle_mid_delta


func campfire_score_delta(hp_percentage: float) -> int:
	var low_delta := _low_band_delta(hp_percentage)
	if low_delta != 0:
		return low_delta

	for i in config.campfire_high_thresholds.size():
		if hp_percentage > config.campfire_high_thresholds[i]:
			return config.campfire_high_deltas[i]
	return 0


func _low_band_delta(hp_percentage: float) -> int:
	for i in config.battle_low_thresholds.size():
		if hp_percentage <= config.battle_low_thresholds[i]:
			return config.battle_low_deltas[i]
	return 0


# ---------------------------------------------------------------- decisions

func should_upgrade_to_tier2(score: int) -> bool:
	return score >= config.tier2_upgrade_score


func decide_after_battle(score: int, hp: float, relic_count: int, gold: int, state: DDAState) -> Array[DDAConversion]:
	var result: Array[DDAConversion] = []

	# High score: shop -> battle if loaded with relics, else take a campfire or event away.
	if score >= config.battle_high_score:
		if relic_count >= config.battle_shop_swap_relics and not state.shop_changed:
			result.append(DDAConversion.make(Room.Type.SHOP, Room.Type.MONSTER, true))
		elif hp >= config.hp_split:
			result.append(DDAConversion.make(Room.Type.CAMPFIRE, Room.Type.MONSTER))
		else:
			result.append(DDAConversion.make(Room.Type.EVENT, Room.Type.MONSTER))

	# Low score: a shop if gold and HP are healthy, otherwise a campfire.
	if score <= config.battle_low_score:
		if gold >= config.battle_low_gold and hp > config.hp_split:
			result.append(DDAConversion.make(Room.Type.MONSTER, Room.Type.SHOP))
		else:
			result.append(DDAConversion.make(Room.Type.MONSTER, Room.Type.CAMPFIRE))

	return result


## `arrival_hp` is the HP share before resting.
func decide_after_campfire(score: int, arrival_hp: float) -> Array[DDAConversion]:
	var result: Array[DDAConversion] = []

	if score >= config.campfire_high_score:
		if arrival_hp >= config.hp_split:
			result.append(DDAConversion.make(Room.Type.CAMPFIRE, Room.Type.MONSTER))
		else:
			result.append(DDAConversion.make(Room.Type.EVENT, Room.Type.MONSTER))

	if score <= config.campfire_low_score:
		if arrival_hp >= config.hp_split:
			result.append(DDAConversion.make(Room.Type.EVENT, Room.Type.CAMPFIRE))
		else:
			result.append(DDAConversion.make(Room.Type.MONSTER, Room.Type.CAMPFIRE))

	return result


func decide_after_shop(score: int, relic_count: int, entered_items: int, gold: int, state: DDAState) -> Array[DDAConversion]:
	var result: Array[DDAConversion] = []
	if state.shop_changed:
		return result

	# Bought everything on offer and loaded with relics: the shop becomes a battle.
	if (score >= config.shop_swap_score
			and relic_count == entered_items + config.shop_all_bought_items
			and relic_count >= config.shop_swap_relics_after_shop):
		result.append(DDAConversion.make(Room.Type.SHOP, Room.Type.MONSTER, true))
	# Bought nothing because of too little gold: help with a treasure room.
	elif relic_count == entered_items and gold < config.broke_gold:
		if score <= config.broke_very_low_score:
			result.append(DDAConversion.make(Room.Type.MONSTER, Room.Type.TREASURE, true))
		elif score <= config.broke_low_score:
			result.append(DDAConversion.make(Room.Type.EVENT, Room.Type.TREASURE, true))

	return result


func decide_after_treasure(score: int, hp: float, relic_count: int, entered_items: int, state: DDAState) -> Array[DDAConversion]:
	var result: Array[DDAConversion] = []

	if (not state.shop_changed
			and score >= config.shop_swap_score
			and relic_count > entered_items
			and relic_count >= config.treasure_shop_swap_relics):
		result.append(DDAConversion.make(Room.Type.SHOP, Room.Type.MONSTER, true))
	elif score >= config.treasure_high_score:
		if hp > config.hp_split:
			result.append(DDAConversion.make(Room.Type.CAMPFIRE, Room.Type.MONSTER))
		else:
			result.append(DDAConversion.make(Room.Type.EVENT, Room.Type.MONSTER))

	return result


# ---------------------------------------------------------------- execution

## Asks the map to convert rooms. A shop-swap flag is used up only when a room
## really changed. Returns how many rooms changed.
func execute(conversions: Array[DDAConversion], map: Object, state: DDAState) -> int:
	var total := 0
	for conversion in conversions:
		var changed: Array = map.call("convert_rooms", conversion.from_type, conversion.to_type, 1)
		if changed.is_empty():
			continue
		total += changed.size()
		if conversion.uses_shop_flag:
			state.shop_changed = true
	return total
