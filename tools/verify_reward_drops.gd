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


func _ready() -> void:
	var had_save := FileAccess.file_exists(SAVE)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	_remember_config()

	_check_defaults()
	_check_rules()
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
	for prop in ["battle_drop_chance", "pity_misses", "tier2_drop_chance", "miss_gold_bonus", "boss_choices", "shop_relic_count", "shop_price_multiplier"]:
		_saved_config[prop] = CONFIG.get(prop)


func _restore_config() -> void:
	for prop in _saved_config:
		CONFIG.set(prop, _saved_config[prop])


# ---------------------------------------------------------------- config and rules

func _check_defaults() -> void:
	_expect(CONFIG.shop_relic_count >= 1 and CONFIG.shop_price_multiplier >= 1.0, "shop defaults make sense")
	_expect(CONFIG.battle_drop_chance > 0.0 and CONFIG.battle_drop_chance < 1.0, "regular battles drop by chance, not always or never")
	_expect(CONFIG.pity_misses >= 1, "the pity counter is on")
	_expect(is_equal_approx(CONFIG.tier2_drop_chance, 1.0), "tier 2 always drops")
	_expect(CONFIG.boss_choices >= 2, "a boss offers a choice")
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
	var low := battle.gold_reward_min
	var high := battle.gold_reward_max

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

	# --- boss: choose one of several, different rarities, one rare or mythic
	CONFIG.boss_choices = 3
	for attempt in 20:
		var choices := run._get_boss_relic_choices()
		_expect(choices.size() == 3, "boss offers 3 relics, got %d" % choices.size())
		var rarities: Array[int] = []
		var ids: Array[String] = []
		for relic in choices:
			rarities.append(relic.rarity)
			ids.append(relic.id)
		_expect(rarities.any(func(r: int) -> bool: return r >= Relic.Rarity.RARE), "a boss offers a rare or mythic relic")
		_expect(_unique_count(rarities) == rarities.size(), "boss relics differ in rarity: %s" % [rarities])
		_expect(_unique_count(ids) == ids.size(), "boss relics are distinct")
	run._boss_reward_pending = false
	var held_before := run.relic_handler.get_all_relics().size()
	run._show_boss_rewards()
	await _frames()
	var boss_reward := _reward_view(run)
	var boss_buttons := _relic_buttons(boss_reward)
	_expect(boss_buttons.size() == 3, "the boss screen shows 3 relics, got %d" % boss_buttons.size())
	_expect(run._boss_reward_pending, "leaving the boss screen is routed to the act change")
	if boss_buttons.size() == 3:
		boss_buttons[1].pressed.emit()
		await _frames()
		_expect(_relic_buttons(boss_reward).is_empty(), "taking one boss relic removes the others")
		_expect(run.relic_handler.get_all_relics().size() == held_before + 1, "exactly one boss relic was taken")
	Events.battle_reward_exited.emit()
	await _frames()
	_expect(not run._boss_reward_pending, "the pending flag clears on exit")
	_expect(run.current_view.get_child_count() > 0 and run.current_view.get_child(0) is ActTransition, "leaving the boss reward shows the act transition")

	# --- shop: configured count and price
	CONFIG.shop_relic_count = 2
	CONFIG.shop_price_multiplier = 1.25
	run._on_shop_entered()
	await _frames(4)
	var shop := run.current_view.get_child(0) as Shop
	var shop_relics: Array[ShopRelic] = []
	if shop:
		for row in [shop.relics_row_1, shop.relics_row_2]:
			for node in row.get_children():
				if node is ShopRelic:
					shop_relics.append(node)
	_expect(shop_relics.size() == 2, "the shop offers 2 relics, got %d" % shop_relics.size())
	for item in shop_relics:
		_expect(item.gold_cost >= roundi(90 * 1.25) and item.gold_cost <= roundi(120 * 1.25), "shop price %d should be 90..120 times 1.25" % item.gold_cost)

	run.queue_free()


func _find_relic(run: Run, relic_name: String) -> Relic:
	for relic in run.battle_relic_pool:
		if relic and relic.relic_name == relic_name:
			return relic
	return null


func _unique_count(items: Array) -> int:
	var seen := {}
	for item in items:
		seen[item] = true
	return seen.size()
