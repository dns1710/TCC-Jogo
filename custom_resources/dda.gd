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

## How many relics a shop stocks: a weighted roll whose weights lean small for a strong
## run and large for a struggling one. `roll` (1..sum) can be passed for tests.
func shop_stock_size(score: int, roll := -1) -> int:
	var weights := config.shop_size_weights_mid
	if score >= config.shop_size_high_score:
		weights = config.shop_size_weights_high
	elif score <= config.shop_size_low_score:
		weights = config.shop_size_weights_low
	return config.shop_size_min + RewardRules.weighted_index(weights, roll)


func should_upgrade_to_tier2(score: int) -> bool:
	return score >= config.tier2_upgrade_score


## A weak run faces tier-0 battles in place of tier-1 ones.
func should_downgrade_to_tier0(score: int) -> bool:
	return score <= config.tier0_downgrade_score


## Extra share of max health a campfire rest heals: only for a weak run.
func campfire_bonus_heal(score: int) -> float:
	return config.campfire_weak_heal_share if score <= config.campfire_low_score else 0.0


## How many more rooms may be turned into battles in the current act.
func battle_budget(state: DDAState) -> int:
	if state == null:
		return 1000000
	return maxi(config.max_battle_conversions_per_act - state.battle_conversions, 0)


## `shop_ahead` is true when a shop is already reachable on the map.
func decide_after_battle(score: int, hp: float, relic_count: int, gold: int, state: DDAState, shop_ahead := false) -> Array[DDAConversion]:
	var result: Array[DDAConversion] = []

	# High score: shop -> battle if loaded with relics (and without gold to spend there), else take a
	# campfire or event away
	# (as long as this act has not turned too many rooms into battles already).
	if score >= config.battle_high_score and battle_budget(state) > 0:
		if relic_count >= config.battle_shop_swap_relics and not state.shop_changed and gold < config.hoard_gold:
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

	# Lots of unspent gold: one upcoming battle becomes a shop (once per act, none already ahead).
	if gold >= config.hoard_gold and not state.hoard_shop_used and not shop_ahead \
			and not _has_conversion(result, Room.Type.MONSTER, Room.Type.SHOP):
		var hoard := DDAConversion.make(Room.Type.MONSTER, Room.Type.SHOP)
		hoard.uses_hoard_flag = true
		result.append(hoard)

	# Almost dead: one upcoming battle becomes a campfire (once per run), unless one is queued already.
	if hp <= config.emergency_hp and not state.emergency_campfire_used \
			and not _has_conversion(result, Room.Type.MONSTER, Room.Type.CAMPFIRE):
		var emergency := DDAConversion.make(Room.Type.MONSTER, Room.Type.CAMPFIRE)
		emergency.uses_emergency_flag = true
		result.append(emergency)

	return result


func _has_conversion(list: Array[DDAConversion], from_type: Room.Type, to_type: Room.Type) -> bool:
	for conversion in list:
		if conversion.from_type == from_type and conversion.to_type == to_type:
			return true
	return false


## `arrival_hp` is the HP share before resting. `state` limits how many battles are added per act.
func decide_after_campfire(score: int, arrival_hp: float, state: DDAState = null) -> Array[DDAConversion]:
	var result: Array[DDAConversion] = []

	if score >= config.campfire_high_score and battle_budget(state) > 0:
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

	# Bought everything on offer and loaded with relics: the shop becomes a battle
	# (if the act still has room for another battle).
	if (battle_budget(state) > 0
			and score >= config.shop_swap_score
			and state.shop_offered_items > 0
			and relic_count == entered_items + state.shop_offered_items
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
	if battle_budget(state) <= 0:
		return result

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
		if conversion.to_type == Room.Type.MONSTER:
			state.battle_conversions += changed.size()
		if conversion.uses_shop_flag:
			state.shop_changed = true
		if conversion.uses_hoard_flag:
			state.hoard_shop_used = true
		if conversion.uses_emergency_flag:
			state.emergency_campfire_used = true
	return total
