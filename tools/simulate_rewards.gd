extends Node
## Simulates the run economy under three reward setups and reports what a player can actually do with
## their gold: v1 (a relic after every battle, 3-5 shop relics at 90-120 gold), v2 (35% drops, 2 shop
## relics at x1.25) and the current one (reward_config.tres and dda_config.tres).
## It uses the real rules (RewardRules, DDA) on a simple route model, so it shows trends, not exact play.
## Model: act = start battle, 5 random floors, chest, 5 random floors, campfire, boss. Random floor mix
## matches the map generator (57% battle, 18% event, 8% campfire, 10% shop, 7% chest). Battle gold 60-70,
## chest 40-50, boss 70-110. Events cost 15-80 gold 30% of the time and pay 20-60 gold 30% of the time.
## The shop buys the best rarity it can afford first. HP after a battle is uniform 10-95% and relics raise the
## DDA score by rarity. DDA room swaps and relics from events are not modelled.
## Run: Godot --headless --path . res://tools/simulate_rewards.tscn
## Output is advisory and always exits 0.

const RUNS := 4000
const ACTS := 3
const FLOORS_BEFORE_CHEST := 5
const FLOORS_AFTER_CHEST := 5
const TIER2_SHARE := 0.10
const OLD_DDA := {"battle_swap": 6, "after_shop": 6, "treasure_swap": 4}

var _rng := RandomNumberGenerator.new()
var _dda := DDA.new()


func _ready() -> void:
	var reward: RewardConfig = load("res://custom_resources/reward_config.tres")
	var dda: DDAConfig = load("res://custom_resources/dda_config.tres")
	var thresholds := {
		"battle_swap": dda.battle_shop_swap_relics, "after_shop": dda.shop_swap_relics_after_shop,
		"treasure_swap": dda.treasure_shop_swap_relics}

	var scenarios := [
		{"name": "v1", "drop": 1.0, "pity": 0, "tier2": 1.0, "miss_bonus": 0.0, "shop": "v1", "income": 1.0,
			"start": 70, "common_price": 105.0, "boss_relic": false},
		{"name": "v2", "drop": 0.35, "pity": 2, "tier2": 1.0, "miss_bonus": 0.5, "shop": "v2", "income": 1.0,
			"start": 70, "common_price": 131.0, "boss_relic": true},
		{"name": "current", "drop": reward.battle_drop_chance, "pity": reward.pity_misses, "tier2": reward.tier2_drop_chance,
			"miss_bonus": reward.miss_gold_bonus, "shop": "banded", "income": reward.income_scale,
			"start": RewardRules.starting_gold(reward), "common_price": _band_mid(reward, 0), "boss_relic": true},
	]

	print("Economy simulation, %d runs, seed fixed." % RUNS)
	print("Current: drop %.2f, pity %d, income x%.2f, shop 3-5 by score, price bands %s, shop rarity weights %s" % [
		reward.battle_drop_chance, reward.pity_misses, reward.income_scale, reward.shop_price_bands, reward.shop_rarity_weights])
	print("")
	var results := {}
	for scenario in scenarios:
		results[scenario["name"]] = _simulate(scenario, reward, thresholds)

	print("Relics held at the end of each act (average)")
	for scenario in scenarios:
		print("  %-8s %s" % [scenario["name"], _format_list(results[scenario["name"]]["held"], "%.1f")])
	print("")
	print("Gold and shops (per shop visit unless noted)")
	print("  %-8s %6s %8s %10s %9s %9s %9s %9s %9s" % ["setup", "visits", "wallet", "=commons", "can't buy", "mythic", "mythic", "mythic", "unspent"])
	print("  %-8s %6s %8s %10s %9s %9s %9s %9s %9s" % ["", "/run", "median", "(median)", "all", "offered", "afford", "bought/run", "at end"])
	for scenario in scenarios:
		var r: Dictionary = results[scenario["name"]]
		print("  %-8s %6.2f %8d %10.1f %8d%% %8d%% %8d%% %9.2f %9d" % [
			scenario["name"], r["visits"], r["wallet_median"], r["wallet_median"] / scenario["common_price"],
			roundi(r["cant_buy_all"] * 100), roundi(r["mythic_offered"] * 100), roundi(r["mythic_affordable"] * 100),
			r["mythic_bought"], roundi(r["end_gold"])])
	print("  Gold at the first shop visit of a run (median): %s" % [_format_list([
		results["v1"]["first_wallet"], results["v2"]["first_wallet"], results["current"]["first_wallet"]], "%d")])
	print("")
	var current: Dictionary = results["current"]
	print("Shop size under the current rules (share of visits): 3 relics %d%%, 4 relics %d%%, 5 relics %d%%, average %.2f" % [
		roundi(current["size_share"][3] * 100), roundi(current["size_share"][4] * 100), roundi(current["size_share"][5] * 100), current["size_avg"]])
	print("")
	print("DDA relic checks: share of runs where each check can fire in the act (thresholds %s)" % [thresholds])
	print("  check           act     v1     v2   current")
	for key in ["battle_swap", "treasure_swap", "all_bought"]:
		for act in ACTS:
			print("  %-14s  %d   %4d%%  %4d%%  %4d%%" % [
				key, act + 1, roundi(results["v1"][key][act] * 100), roundi(results["v2"][key][act] * 100),
				roundi(results["current"][key][act] * 100)])
	print("")
	print("Difficulty-system pressure on the map: a strong player (score 80, wins every fight healthy), 3 rooms wide, 11 floors")
	print("(floor 5 is all treasure, floor 10 is the pre-boss campfire floor; the player picks the best non-battle room each floor)")
	print("  %-44s %16s %24s" % ["setup", "battles on path", "pre-boss campfire stays"])
	var cases := [
		["old: no limit, pre-boss campfire open", 1000000, false],
		["pre-boss campfire fixed, no limit", 1000000, true],
		["pre-boss fixed, limit %d per act (current)" % dda.max_battle_conversions_per_act, dda.max_battle_conversions_per_act, true],
	]
	for case in cases:
		var result := _conversion_pressure(case[1], case[2])
		print("  %-44s %16.1f %23d%%" % [case[0], result["battles"], roundi(result["campfire_kept"] * 100)])
	get_tree().quit(0)


## Plays the real DDA decisions for a strong player over many generated acts.
## Returns the average battles on the player's path and the share of acts where the pre-boss campfire survived.
func _conversion_pressure(cap: int, protect_pre_boss: bool) -> Dictionary:
	_rng.seed = 777
	var config := DDAConfig.new()
	config.max_battle_conversions_per_act = cap
	var dda := DDA.new()
	dda.config = config
	var acts := 2000
	var floors_count := 11
	var pre_boss := floors_count - 1
	var treasure_floor := 5
	var battle_total := 0
	var campfire_kept := 0
	for act in acts:
		var rooms: Array = []
		for row in floors_count:
			var row_rooms: Array[Room.Type] = []
			for column in 3:
				if row == 0:
					row_rooms.append(Room.Type.MONSTER)
				elif row == treasure_floor:
					row_rooms.append(Room.Type.TREASURE)
				elif row == pre_boss:
					row_rooms.append(Room.Type.CAMPFIRE)
				else:
					row_rooms.append(_floor_room_type())
			rooms.append(row_rooms)
		var state := DDAState.new()
		var battles := 0
		for row in floors_count:
			var visited := _best_room(rooms[row])
			var type: Room.Type = rooms[row][visited]
			if type == Room.Type.MONSTER:
				battles += 1
			var decisions: Array[DDAConversion] = []
			match type:
				Room.Type.MONSTER:
					decisions = dda.decide_after_battle(80, 0.9, 3, 50, state, true)
				Room.Type.CAMPFIRE:
					decisions = dda.decide_after_campfire(80, 0.9, state)
				Room.Type.TREASURE:
					decisions = dda.decide_after_treasure(80, 0.9, 3, 1, state)
			for conversion in decisions:
				var converted := false
				for target_row in range(row + 1, floors_count):
					if protect_pre_boss and target_row == pre_boss:
						continue
					for column in 3:
						if rooms[target_row][column] == conversion.from_type:
							rooms[target_row][column] = conversion.to_type
							converted = true
							break
					if converted:
						break
				if converted:
					if conversion.to_type == Room.Type.MONSTER:
						state.battle_conversions += 1
					if conversion.uses_shop_flag:
						state.shop_changed = true
		battle_total += battles
		if rooms[pre_boss].has(Room.Type.CAMPFIRE):
			campfire_kept += 1
	return {"battles": float(battle_total) / acts, "campfire_kept": float(campfire_kept) / acts}


## The room the player picks on a floor: campfire, then shop, treasure, event, battle.
func _best_room(row_rooms: Array) -> int:
	var order := [Room.Type.CAMPFIRE, Room.Type.SHOP, Room.Type.TREASURE, Room.Type.EVENT, Room.Type.MONSTER]
	for wanted in order:
		for column in row_rooms.size():
			if row_rooms[column] == wanted:
				return column
	return 0


func _floor_room_type() -> Room.Type:
	var roll := _rng.randf()
	if roll < 0.57:
		return Room.Type.MONSTER
	if roll < 0.75:
		return Room.Type.EVENT
	if roll < 0.83:
		return Room.Type.CAMPFIRE
	if roll < 0.93:
		return Room.Type.SHOP
	return Room.Type.TREASURE


func _band_mid(reward: RewardConfig, rarity: int) -> float:
	return (reward.shop_price_bands[rarity * 2] + reward.shop_price_bands[rarity * 2 + 1]) / 2.0


func _format_list(values: Array, pattern: String) -> String:
	var parts: Array[String] = []
	for v in values:
		parts.append(pattern % v)
	return ", ".join(parts)


func _simulate(scenario: Dictionary, reward: RewardConfig, thresholds: Dictionary) -> Dictionary:
	_rng.seed = 20260101
	var income: float = scenario["income"]
	var held_sum := [0.0, 0.0, 0.0]
	var battle_swap := [0, 0, 0]
	var treasure_swap := [0, 0, 0]
	var all_bought := [0, 0, 0]
	var wallets: Array[int] = []
	var first_wallets: Array[int] = []
	var visits := 0
	var cant_buy_all := 0
	var mythic_offer_visits := 0
	var mythic_affordable := 0
	var mythic_bought := 0
	var end_gold := 0.0
	var sizes := {3: 0, 4: 0, 5: 0}
	var size_total := 0
	for run in RUNS:
		var stats := RunStats.new()
		var held := 0
		var gold: int = scenario["start"]
		var first_shop := true
		var score := 50
		for act in ACTS:
			var fired_battle := false
			var fired_treasure := false
			var fired_shop := false
			var floor_types: Array[String] = ["battle"]
			for i in FLOORS_BEFORE_CHEST:
				floor_types.append(_random_floor())
			floor_types.append("chest")
			for i in FLOORS_AFTER_CHEST:
				floor_types.append(_random_floor())
			floor_types.append("campfire")
			floor_types.append("boss")
			for index in floor_types.size():
				match floor_types[index]:
					"battle":
						var base_gold := roundi(_rng.randi_range(60, 70) * income)
						var tier2: bool = index > 0 and _rng.randf() < TIER2_SHARE
						var tier := 2 if tier2 else 1
						var drops := false
						if act == 0 and index == 0:
							held += 2
							gold += base_gold
							score = clampi(score + _dda.relic_score(0) * 2, 0, 100)
						else:
							drops = _drops(scenario, reward, tier, stats)
							if drops:
								held += 1
								gold += base_gold
								score = clampi(score + _dda.relic_score(_roll_rarity(RewardRules.regular_weights(reward, tier))), 0, 100)
							else:
								gold += base_gold + roundi(base_gold * float(scenario["miss_bonus"]))
						score = clampi(score + _dda.battle_score_delta(_rng.randf_range(10.0, 95.0)), 0, 100)
						if held >= thresholds["battle_swap"]:
							fired_battle = true
					"chest":
						held += 1
						gold += roundi(_rng.randi_range(40, 50) * income)
						score = clampi(score + _dda.relic_score(1), 0, 100)
						if held >= thresholds["treasure_swap"]:
							fired_treasure = true
					"event":
						var roll := _rng.randf()
						if roll < 0.30:
							var cost := _rng.randi_range(15, 80)
							gold = maxi(0, gold - cost)
						elif roll < 0.60:
							gold += roundi(_rng.randi_range(20, 60) * income)
					"shop":
						var stock := _stock(scenario, reward, score)
						visits += 1
						wallets.append(gold)
						if first_shop:
							first_wallets.append(gold)
							first_shop = false
						var cheapest_mythic := 100000
						var total_price := 0
						for item in stock:
							total_price += item["price"]
							if item["rarity"] == 3:
								cheapest_mythic = mini(cheapest_mythic, item["price"])
						if total_price > gold:
							cant_buy_all += 1
						if cheapest_mythic < 100000:
							mythic_offer_visits += 1
							if gold >= cheapest_mythic:
								mythic_affordable += 1
						if scenario["shop"] == "banded":
							sizes[stock.size()] = int(sizes.get(stock.size(), 0)) + 1
							size_total += stock.size()
						stock.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["rarity"] > b["rarity"])
						var bought := 0
						for item in stock:
							if gold >= item["price"]:
								gold -= item["price"]
								held += 1
								bought += 1
								score = clampi(score + _dda.relic_score(item["rarity"]), 0, 100)
								if item["rarity"] == 3:
									mythic_bought += 1
						var expected: int = stock.size() if scenario["shop"] != "v1" else 3
						if bought == expected and held >= thresholds["after_shop"]:
							fired_shop = true
					"boss":
						if bool(scenario["boss_relic"]) and act < ACTS - 1:
							held += 1
						gold += roundi(_rng.randi_range(70, 110) * income)
			held_sum[act] += held
			battle_swap[act] += 1 if fired_battle else 0
			treasure_swap[act] += 1 if fired_treasure else 0
			all_bought[act] += 1 if fired_shop else 0
		end_gold += gold
	var avg: Array[float] = []
	var out := {"battle_swap": [], "treasure_swap": [], "all_bought": []}
	for act in ACTS:
		avg.append(held_sum[act] / RUNS)
		out["battle_swap"].append(float(battle_swap[act]) / RUNS)
		out["treasure_swap"].append(float(treasure_swap[act]) / RUNS)
		out["all_bought"].append(float(all_bought[act]) / RUNS)
	var visit_count := maxf(visits, 1)
	wallets.sort()
	first_wallets.sort()
	out["held"] = avg
	out["visits"] = float(visits) / RUNS
	out["wallet_median"] = wallets[wallets.size() / 2] if not wallets.is_empty() else 0
	out["first_wallet"] = first_wallets[first_wallets.size() / 2] if not first_wallets.is_empty() else 0
	out["cant_buy_all"] = cant_buy_all / visit_count
	out["mythic_offered"] = mythic_offer_visits / visit_count
	out["mythic_affordable"] = float(mythic_affordable) / maxf(mythic_offer_visits, 1)
	out["mythic_bought"] = float(mythic_bought) / RUNS
	out["end_gold"] = end_gold / RUNS
	out["size_share"] = {3: sizes[3] / visit_count, 4: sizes[4] / visit_count, 5: sizes[5] / visit_count}
	out["size_avg"] = size_total / visit_count
	return out


func _drops(scenario: Dictionary, reward: RewardConfig, tier: int, stats: RunStats) -> bool:
	# The real rule, with this scenario's chances and pity.
	var config := RewardConfig.new()
	config.battle_drop_chance = scenario["drop"]
	config.tier2_drop_chance = scenario["tier2"]
	config.pity_misses = scenario["pity"]
	return RewardRules.battle_drops_relic(config, tier, stats, _rng.randf())


func _roll_rarity(weights: Dictionary) -> int:
	var total := 0
	for rarity in weights:
		total += weights[rarity]
	var roll := _rng.randi_range(1, maxi(total, 1))
	for rarity in weights:
		roll -= weights[rarity]
		if roll <= 0:
			return rarity
	return 0


## The shop's stock as {rarity, price} items.
func _stock(scenario: Dictionary, reward: RewardConfig, score: int) -> Array[Dictionary]:
	var stock: Array[Dictionary] = []
	match scenario["shop"]:
		"v1":
			for i in _rng.randi_range(3, 5):
				stock.append({"rarity": _roll_rarity({0: 40, 1: 35, 2: 20, 3: 5}), "price": _rng.randi_range(90, 120)})
		"v2":
			for i in 2:
				stock.append({"rarity": _roll_rarity({0: 40, 1: 35, 2: 20, 3: 5}), "price": roundi(_rng.randi_range(90, 120) * 1.25)})
		_:
			var size := _dda.shop_stock_size(score, _rng.randi_range(1, 100))
			for i in size:
				var rarity := _roll_rarity(RewardRules.weights_from(reward.shop_rarity_weights))
				stock.append({"rarity": rarity, "price": RewardRules.shop_price(reward, rarity, _rng.randi_range(
					reward.shop_price_bands[rarity * 2], reward.shop_price_bands[rarity * 2 + 1]))})
	return stock


func _random_floor() -> String:
	var roll := _rng.randf()
	if roll < 0.57:
		return "battle"
	if roll < 0.75:
		return "event"
	if roll < 0.83:
		return "campfire"
	if roll < 0.93:
		return "shop"
	return "chest"
