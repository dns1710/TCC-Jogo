extends Node
## Headless guard for the reward-drop-rates spec: regular battles drop by chance, the pity counter
## forces a drop and survives saving, tier 2 always drops, bosses offer a choice of one, the first
## battle guarantee is untouched, shops use the configured count and price, and rates are data.
## Run: Godot --headless --path . res://tools/verify_reward_drops.tscn
## Backs up and restores user://savegame.tres so a real save is never lost.

const SAVE := "user://savegame.tres"
const BACKUP := "user://savegame.reward_check_backup"
const STATS_TMP := "user://reward_check_stats.tres"
var CONFIG: RewardConfig = preload("res://custom_resources/reward_config.tres")

var _errors: Array[String] = []
var _saved_config := {}
var sizes_by_case := {}


func _ready() -> void:
	var had_save := FileAccess.file_exists(SAVE)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	_remember_config()

	_check_defaults()
	_check_rules()
	_check_economy_rules()
	_check_saving()
	await _check_run()

	_restore_config()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STATS_TMP))
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if _errors.is_empty():
		print("REWARD DROPS CHECK OK")
		get_tree().quit(0)
	else:
		print("REWARD DROPS CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


func _remember_config() -> void:
	for prop in ["battle_drop_chance", "pity_misses", "tier2_drop_chance", "miss_gold_bonus", "income_scale", "boss_weights", "shop_rarity_weights", "shop_price_bands"]:
		_saved_config[prop] = CONFIG.get(prop)


func _restore_config() -> void:
	for prop in _saved_config:
		CONFIG.set(prop, _saved_config[prop])


# ---------------------------------------------------------------- config and rules

func _check_defaults() -> void:
	_expect(CONFIG.shop_rarity_weights.size() == 4 and CONFIG.shop_rarity_weights[Relic.Rarity.MYTHIC] >= 8, "mythic relics are weighted at 8 or more in shops")
	_expect(CONFIG.shop_price_bands.size() == 8, "a price band per rarity")
	_expect(CONFIG.battle_drop_chance > 0.0 and CONFIG.battle_drop_chance < 1.0, "regular battles drop by chance, not always or never")
	_expect(CONFIG.pity_misses >= 1, "the pity counter is on")
	_expect(is_equal_approx(CONFIG.tier2_drop_chance, 1.0), "tier 2 always drops")
	_expect(CONFIG.boss_weights[Relic.Rarity.COMMON] == 0 and CONFIG.boss_weights[Relic.Rarity.RARE] > 0, "a boss never drops a common")
	_expect(is_equal_approx(CONFIG.income_scale, 0.5), "income is halved")
	_expect(RewardRules.regular_weights(CONFIG, 2).has(Relic.Rarity.UNCOMMON) and not RewardRules.regular_weights(CONFIG, 2).has(Relic.Rarity.COMMON),
		"tier-2 weights start at uncommon")


func _check_rules() -> void:
	var stats := RunStats.new()
	var chance := CONFIG.battle_drop_chance
	var pity := CONFIG.pity_misses
	# A roll above the chance is a miss; the pity-th consecutive miss forces the next drop.
	for i in pity:
		_expect(not RewardRules.battle_drops_relic(CONFIG, 1, stats, 0.999), "roll above the chance is a miss (miss %d)" % (i + 1))
	_expect(stats.relic_drop_misses == pity, "misses are counted, got %d" % stats.relic_drop_misses)
	_expect(RewardRules.battle_drops_relic(CONFIG, 1, stats, 0.999), "pity forces a drop after %d misses" % pity)
	_expect(stats.relic_drop_misses == 0, "a drop resets the counter")
	_expect(RewardRules.battle_drops_relic(CONFIG, 1, stats, chance - 0.01), "roll under the chance drops")

	# Tier 2 always drops.
	var tier2_ok := true
	RNG.instance.seed = 4242
	for i in 200:
		tier2_ok = tier2_ok and RewardRules.battle_drops_relic(CONFIG, 2, stats)
	_expect(tier2_ok, "every tier-2 battle drops over 200 seeded rolls")

	# Long-run rate with pity sits above the raw chance and below 100%.
	stats = RunStats.new()
	var drops := 0
	var battles := 20000
	for i in battles:
		if RewardRules.battle_drops_relic(CONFIG, 1, stats):
			drops += 1
	var rate := float(drops) / battles
	_expect(rate > chance and rate < 0.8, "effective drop rate %.3f should be above %.2f and well under 1" % [rate, chance])

	_expect(RewardRules.miss_gold(CONFIG, 60) == 60 + roundi(60 * CONFIG.miss_gold_bonus), "miss gold adds the configured bonus")

	# Rates are data: changing the chance changes the outcome with no code edit.
	var edited := CONFIG.battle_drop_chance
	CONFIG.battle_drop_chance = 0.0
	CONFIG.pity_misses = 0
	stats = RunStats.new()
	_expect(not RewardRules.battle_drops_relic(CONFIG, 1, stats, 0.0), "chance 0 and no pity never drops")
	CONFIG.battle_drop_chance = 1.0
	_expect(RewardRules.battle_drops_relic(CONFIG, 1, stats, 0.999), "chance 1 always drops")
	CONFIG.battle_drop_chance = edited
	CONFIG.pity_misses = _saved_config["pity_misses"]


func _check_economy_rules() -> void:
	# Price bands: no overlap, mythic is a splurge (3x a common).
	var mins: Array[int] = []
	var maxs: Array[int] = []
	for rarity in 4:
		mins.append(CONFIG.shop_price_bands[rarity * 2])
		maxs.append(CONFIG.shop_price_bands[rarity * 2 + 1])
		_expect(mins[rarity] <= maxs[rarity], "band %d is ordered" % rarity)
	for rarity in 3:
		_expect(maxs[rarity] < mins[rarity + 1], "every rarity %d price is below every rarity %d price (%d vs %d)" % [rarity, rarity + 1, maxs[rarity], mins[rarity + 1]])
	_expect(mins[Relic.Rarity.MYTHIC] >= 170, "a mythic costs at least 170")
	_expect(float(mins[Relic.Rarity.MYTHIC] + maxs[Relic.Rarity.MYTHIC]) >= 2.9 * float(mins[Relic.Rarity.COMMON] + maxs[Relic.Rarity.COMMON]), "mythic is about 3x a common on average")
	RNG.instance.seed = 99
	for rarity in 4:
		for i in 200:
			var price := RewardRules.shop_price(CONFIG, rarity)
			_expect(price >= mins[rarity] and price <= maxs[rarity], "price %d is inside the rarity %d band" % [price, rarity])

	# Income scale: a 60-70 gold battle pays 30-35, costs are untouched, start gold halves.
	_expect(RewardRules.scale_gold(CONFIG, 60) == 30 and RewardRules.scale_gold(CONFIG, 70) == 35, "a 60-70 battle pays 30-35")
	_expect(RewardRules.starting_gold(CONFIG) == 35, "a new run starts with half the v2 purse")
	_expect(RewardRules.scale_gold(CONFIG, -40) == -40 and RewardRules.scale_gold(CONFIG, 0) == 0, "gold lost or zero is not scaled")
	_expect(RewardRules.scale_gold(CONFIG, 1) >= 1, "a positive payout never rounds to nothing")
	var bs := BattleStats.new()
	bs.gold_reward_min = 60
	bs.gold_reward_max = 70
	for i in 50:
		var gold := bs.roll_gold_reward()
		_expect(gold >= 30 and gold <= 35, "roll_gold_reward scales to 30-35, got %d" % gold)

	# Gold gained in events follows the scale; gold lost and costs do not.
	var gain := EventOutcome.new()
	gain.gold = 50
	var loss := EventOutcome.new()
	loss.gold = -40
	var rs := RunStats.new()
	rs.gold = 100
	var fake_event := EventRoom.new()
	fake_event.run_stats = rs
	fake_event.character_stats = CharacterStats.new()
	gain.apply(fake_event)
	_expect(rs.gold == 125, "a +50 outcome gives +25, gold is %d" % rs.gold)
	loss.apply(fake_event)
	_expect(rs.gold == 85, "a -40 outcome costs 40, gold is %d" % rs.gold)
	fake_event.free()

	# Golden Clover pays about half of v2.
	var clover := GoldenClover.new()
	_expect(clover.min_extra_gold == 8 and clover.max_extra_gold == 13, "Golden Clover pays 8-13")


func _check_saving() -> void:
	_expect(RunStats.new().relic_drop_misses == 0, "a fresh or old save starts the pity counter at 0")
	var stats := RunStats.new()
	stats.relic_drop_misses = 2
	_expect(ResourceSaver.save(stats, STATS_TMP) == OK, "run stats save")
	var loaded := ResourceLoader.load(STATS_TMP, "", ResourceLoader.CACHE_MODE_IGNORE) as RunStats
	_expect(loaded != null and loaded.relic_drop_misses == 2, "the pity counter survives saving and loading")


# ---------------------------------------------------------------- run flows

func _reward_view(run: Run) -> BattleReward:
	return run.current_view.get_child(0) as BattleReward


func _relic_buttons(reward: BattleReward) -> Array[RewardButton]:
	var out: Array[RewardButton] = []
	for node in reward.rewards.get_children():
		var button := node as RewardButton
		if button and not button.is_queued_for_deletion() and not button.reward_text.ends_with(" gold"):
			out.append(button)
	return out


func _gold_amount(reward: BattleReward) -> int:
	for node in reward.rewards.get_children():
		var button := node as RewardButton
		if button and button.reward_text.ends_with(" gold"):
			return int(button.reward_text.split(" ")[0])
	return -1


func _check_run() -> void:
	var run := load("res://scenes/run/run.tscn").instantiate() as Run
	add_child(run)
	await _frames()

	var room: Room = run.map.map_data[0][MapGenerator.MAP_WIDTH / 2]
	var battle: BattleStats = room.battle_stats
	_expect(battle != null, "the start room has battle stats")
	run.map.last_room = room
	var low := RewardRules.scale_gold(CONFIG, battle.gold_reward_min)
	var high := RewardRules.scale_gold(CONFIG, battle.gold_reward_max)

	# --- regular battle: misses give boosted gold only, pity forces a relic
	CONFIG.battle_drop_chance = 0.0
	CONFIG.pity_misses = 2
	run.stats.relic_drop_misses = 0
	for i in 2:
		run._show_regular_battle_rewards()
		await _frames()
		var reward := _reward_view(run)
		_expect(_relic_buttons(reward).is_empty(), "miss %d offers no relic" % (i + 1))
		var gold := _gold_amount(reward)
		_expect(gold >= roundi(low * (1.0 + CONFIG.miss_gold_bonus)) and gold <= roundi(high * (1.0 + CONFIG.miss_gold_bonus)),
			"miss gold %d should be %d..%d plus the bonus" % [gold, low, high])
	run._show_regular_battle_rewards()
	await _frames()
	var pity_reward := _reward_view(run)
	_expect(_relic_buttons(pity_reward).size() == 1, "the pity battle offers one relic")
	var pity_gold := _gold_amount(pity_reward)
	_expect(pity_gold >= low and pity_gold <= high, "a drop gives normal gold, got %d" % pity_gold)
	_expect(run.stats.relic_drop_misses == 0, "the pity drop resets the counter")

	# --- tier 2 always drops, uncommon or better
	var tier2: BattleStats = run.map.get_battle_pool().get_random_battle_for_tier(2)
	_expect(tier2 != null, "a tier-2 battle exists")
	if tier2:
		var tier2_room := Room.new()
		tier2_room.battle_stats = tier2
		run.map.last_room = tier2_room
		run.stats.relic_drop_misses = 0
		for i in 5:
			run._show_regular_battle_rewards()
			await _frames()
			var buttons := _relic_buttons(_reward_view(run))
			_expect(buttons.size() == 1, "tier-2 battle %d offers a relic" % (i + 1))
			if buttons.size() == 1:
				var found := _find_relic(run, buttons[0].reward_text)
				_expect(found != null and found.rarity >= Relic.Rarity.UNCOMMON, "tier-2 relic %s is uncommon or better" % buttons[0].reward_text)
		run.map.last_room = room

	# --- first battle guarantee is untouched even with drops off
	CONFIG.battle_drop_chance = 0.0
	CONFIG.pity_misses = 0
	run._show_first_battle_reward()
	await _frames()
	var first := _relic_buttons(_reward_view(run))
	_expect(first.size() == 2, "the first battle still offers two relics, got %d" % first.size())
	if first.size() == 2:
		var weapon := _find_relic(run, first[0].reward_text)
		var other := _find_relic(run, first[1].reward_text)
		_expect(weapon != null and weapon.equip == Relic.Equip.WEAPON, "first reward is a weapon")
		_expect(other != null and other.equip != Relic.Equip.WEAPON and other.rarity == Relic.Rarity.COMMON, "second first-battle reward is a common non-weapon")

	# --- boss: gold plus exactly one relic, never common, better odds than tier 2
	run._boss_reward_pending = false
	var held_before := run.relic_handler.get_all_relics().size()
	run._show_boss_rewards()
	await _frames()
	var boss_reward := _reward_view(run)
	var boss_buttons := _relic_buttons(boss_reward)
	_expect(boss_buttons.size() == 1, "the boss screen shows exactly 1 relic, got %d" % boss_buttons.size())
	_expect(_gold_amount(boss_reward) >= 0, "the boss screen shows gold")
	_expect(run._boss_reward_pending, "leaving the boss screen is routed to the act change")
	if boss_buttons.size() == 1:
		boss_buttons[0].pressed.emit()
		await _frames()
		_expect(run.relic_handler.get_all_relics().size() == held_before + 1, "the boss relic was taken")
	Events.battle_reward_exited.emit()
	await _frames()
	_expect(not run._boss_reward_pending, "the pending flag clears on exit")
	_expect(run.current_view.get_child_count() > 0 and run.current_view.get_child(0) is ActTransition, "leaving the boss reward shows the act transition")

	var boss_weights := RewardRules.weights_from(CONFIG.boss_weights)
	var tier2_weights := RewardRules.regular_weights(CONFIG, 2)
	var boss_high := 0
	var tier2_high := 0
	var boss_common := 0
	var rolls := 400
	RNG.instance.seed = 31337
	for i in rolls:
		var boss_relic := run._get_random_relic_reward(-1, false, boss_weights)
		var tier2_relic := run._get_random_relic_reward(-1, false, tier2_weights)
		if boss_relic:
			boss_common += 1 if boss_relic.rarity == Relic.Rarity.COMMON else 0
			boss_high += 1 if boss_relic.rarity >= Relic.Rarity.RARE else 0
		if tier2_relic:
			tier2_high += 1 if tier2_relic.rarity >= Relic.Rarity.RARE else 0
	_expect(boss_common == 0, "boss drops are never common over %d rolls" % rolls)
	_expect(boss_high > tier2_high, "a boss gives more rare and mythic relics (%d) than tier 2 (%d)" % [boss_high, tier2_high])

	# --- shops: 3 to 5 relics by score, banded prices, size recorded for DDA
	for case in [["strong", 85], ["average", 50], ["struggling", 15]]:
		run.stats.dda_score = case[1]
		var sizes := {}
		var banded := true
		for visit in 25:
			run._on_shop_entered()
			await _frames(3)
			var shop := run.current_view.get_child(0) as Shop
			var shop_relics: Array[ShopRelic] = []
			if shop:
				for row in [shop.relics_row_1, shop.relics_row_2]:
					for node in row.get_children():
						if node is ShopRelic and not node.is_queued_for_deletion():
							shop_relics.append(node)
			sizes[shop_relics.size()] = int(sizes.get(shop_relics.size(), 0)) + 1
			_expect(shop_relics.size() >= 3 and shop_relics.size() <= 5, "the %s shop stocks 3 to 5 relics, got %d" % [case[0], shop_relics.size()])
			_expect(run.stats.dda_state.shop_offered_items == shop_relics.size(), "the shop records its size (%d vs %d)" % [run.stats.dda_state.shop_offered_items, shop_relics.size()])
			for item in shop_relics:
				var band_low: int = CONFIG.shop_price_bands[item.relic.rarity * 2]
				var band_high: int = CONFIG.shop_price_bands[item.relic.rarity * 2 + 1]
				banded = banded and item.gold_cost >= band_low and item.gold_cost <= band_high
		_expect(banded, "every %s shop relic is priced inside its rarity band" % case[0])
		sizes_by_case[case[0]] = sizes
	_expect(_average_size(sizes_by_case["strong"]) < _average_size(sizes_by_case["average"]), "strong runs get smaller shops than average ones %s" % [sizes_by_case])
	_expect(_average_size(sizes_by_case["average"]) < _average_size(sizes_by_case["struggling"]), "struggling runs get larger shops than average ones %s" % [sizes_by_case])

	# --- a shop cost discount (the legacy Coupons relic uses it) still applies on top of banded prices
	run._on_shop_entered()
	await _frames(3)
	var discount_shop := run.current_view.get_child(0) as Shop
	if discount_shop:
		var cost_modifier := discount_shop.modifier_handler.get_modifier(Modifier.Type.SHOP_COST)
		var coupon := ModifierValue.create_new_modifier("coupons", ModifierValue.Type.PERCENT_BASED)
		coupon.percent_value = -0.5
		cost_modifier.add_new_value(coupon)
		_expect(discount_shop._get_updated_shop_cost(200) == 100, "a 50% shop discount halves a banded price")
	else:
		_expect(false, "a shop opened for the discount check")

	run.queue_free()


func _find_relic(run: Run, relic_name: String) -> Relic:
	for relic in run.battle_relic_pool:
		if relic and relic.relic_name == relic_name:
			return relic
	return null


func _average_size(sizes: Dictionary) -> float:
	var total := 0.0
	var count := 0
	for size in sizes:
		total += size * sizes[size]
		count += sizes[size]
	return total / maxf(count, 1)


func _unique_count(items: Array) -> int:
	var seen := {}
	for item in items:
		seen[item] = true
	return seen.size()
