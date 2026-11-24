extends Node
## Simulates how many relics a run holds under the old rewards (a relic after every battle, 3 to 5 shop
## relics) and the new ones (reward_config.tres), and how often each DDA relic-count check fires.
## It uses the real drop rules (RewardRules) on a simple route model, so it shows trends, not exact play.
## Model: act = start battle, 5 random floors, chest, 5 random floors, campfire, boss. Random floor mix
## matches the map generator (57% battle, 18% event, 8% campfire, 10% shop, 7% chest). Battle gold 60, chest
## gold 45, shop buys cheapest first while gold lasts. Event relics and DDA room swaps are not modelled.
## Run: Godot --headless --path . res://tools/simulate_rewards.tscn
## Output is advisory and always exits 0.

const RUNS := 4000
const ACTS := 3
const FLOORS_BEFORE_CHEST := 5
const FLOORS_AFTER_CHEST := 5
const BATTLE_GOLD := 60
const CHEST_GOLD := 45
const TIER2_SHARE := 0.10
const OLD_DDA := {"battle_swap": 6, "after_shop": 6, "treasure_swap": 4, "all_bought": 3}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var reward: RewardConfig = load("res://custom_resources/reward_config.tres")
	var dda: DDAConfig = load("res://custom_resources/dda_config.tres")
	var new_dda := {
		"battle_swap": dda.battle_shop_swap_relics, "after_shop": dda.shop_swap_relics_after_shop,
		"treasure_swap": dda.treasure_shop_swap_relics, "all_bought": dda.shop_all_bought_items}

	var old_stats := _simulate(null, OLD_DDA)
	var new_stats_old_dda := _simulate(reward, OLD_DDA)
	var new_stats := _simulate(reward, new_dda)

	print("Reward simulation, %d runs, seed fixed." % RUNS)
	print("Old rewards: a relic after every battle, 3-5 shop relics at 90-120 gold.")
	print("New rewards: drop %.2f, pity %d, tier 2 %.2f, boss choice of %d, %d shop relics at x%.2f." % [
		reward.battle_drop_chance, reward.pity_misses, reward.tier2_drop_chance, reward.boss_choices,
		reward.shop_relic_count, reward.shop_price_multiplier])
	print("")
	print("Relics held at the end of each act (average)")
	print("  old: %s" % _format_list(old_stats["held"]))
	print("  new: %s" % _format_list(new_stats["held"]))
	print("")
	print("DDA relic checks: share of runs where each check can fire in the act")
	print("  old thresholds %s" % [OLD_DDA])
	print("  new thresholds %s" % [new_dda])
	print("  check           act   old   new(old thresholds)   new(new thresholds)")
	for key in ["battle_swap", "treasure_swap", "all_bought"]:
		for act in ACTS:
			print("  %-14s  %d    %3d%%   %3d%%                 %3d%%" % [
				key, act + 1, roundi(old_stats[key][act] * 100), roundi(new_stats_old_dda[key][act] * 100),
				roundi(new_stats[key][act] * 100)])
	get_tree().quit(0)


func _format_list(values: Array) -> String:
	var parts: Array[String] = []
	for v in values:
		parts.append("%.1f" % v)
	return ", ".join(parts)


## `reward` null = old behaviour. `thresholds` are the DDA relic-count settings to check against.
func _simulate(reward: RewardConfig, thresholds: Dictionary) -> Dictionary:
	_rng.seed = 20260101
	var held_sum := [0.0, 0.0, 0.0]
	var battle_swap := [0, 0, 0]
	var treasure_swap := [0, 0, 0]
	var all_bought := [0, 0, 0]
	for run in RUNS:
		var stats := RunStats.new()
		var held := 0
		var gold := RunStats.STARTING_GOLD
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
						var tier2 := index > 0 and _rng.randf() < TIER2_SHARE
						var tier := 2 if tier2 else 1
						if reward == null:
							held += 1
							gold += BATTLE_GOLD
						elif act == 0 and index == 0:
							held += 2
							gold += BATTLE_GOLD
						elif RewardRules.battle_drops_relic(reward, tier, stats, _rng.randf()):
							held += 1
							gold += BATTLE_GOLD
						else:
							gold += RewardRules.miss_gold(reward, BATTLE_GOLD)
						if held >= thresholds["battle_swap"]:
							fired_battle = true
					"chest":
						held += 1
						gold += CHEST_GOLD
						if held >= thresholds["treasure_swap"]:
							fired_treasure = true
					"shop":
						var count := _rng.randi_range(3, 5) if reward == null else reward.shop_relic_count
						var multiplier := 1.0 if reward == null else reward.shop_price_multiplier
						var bought := 0
						for i in count:
							var price := roundi(_rng.randi_range(90, 120) * multiplier)
							if gold >= price:
								gold -= price
								held += 1
								bought += 1
						if bought == thresholds["all_bought"] and held >= thresholds["after_shop"]:
							fired_shop = true
					"boss":
						if reward != null and act < ACTS - 1:
							held += 1
						gold += BATTLE_GOLD
			held_sum[act] += held
			battle_swap[act] += 1 if fired_battle else 0
			treasure_swap[act] += 1 if fired_treasure else 0
			all_bought[act] += 1 if fired_shop else 0
	var avg: Array[float] = []
	var shares := {"battle_swap": [], "treasure_swap": [], "all_bought": []}
	for act in ACTS:
		avg.append(held_sum[act] / RUNS)
		shares["battle_swap"].append(float(battle_swap[act]) / RUNS)
		shares["treasure_swap"].append(float(treasure_swap[act]) / RUNS)
		shares["all_bought"].append(float(all_bought[act]) / RUNS)
	shares["held"] = avg
	return shares


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
