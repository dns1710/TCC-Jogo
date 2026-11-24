extends Node
## Headless check of the dda-room-adjustment spec: one score function with recorded
## reasons, campfire scored before resting, decision tables for every trigger,
## flags used only on real conversions, per-act reset and saves, immediate room
## changes with a cosmetic animation.
## Run: Godot --headless --path . res://tools/verify_dda.tscn
## Backs up and restores user://savegame.tres so a real save is never lost.

const SAVE := "user://savegame.tres"
const BACKUP := "user://savegame.dda_check_backup"

var _errors: Array[String] = []
var _lock_events: Array[bool] = []
var dda := DDA.new()

var M := Room.Type.MONSTER
var S := Room.Type.SHOP
var CF := Room.Type.CAMPFIRE
var EV := Room.Type.EVENT
var T := Room.Type.TREASURE


func _ready() -> void:
	var had_save := FileAccess.file_exists(SAVE)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	Events.animation_dda_lock.connect(func(value: bool): _lock_events.append(value))

	_check_config()
	_check_relic_scoring()
	await _check_score()
	_check_score_tables()
	_check_decisions()
	_check_flags()
	_check_state_and_saves()
	await _check_run()

	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if _errors.is_empty():
		print("DDA CHECK OK")
		get_tree().quit(0)
	else:
		print("DDA CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 2) -> void:
	for i in count:
		await get_tree().process_frame


func _names(conversions: Array[DDAConversion]) -> String:
	var parts: Array[String] = []
	for c in conversions:
		parts.append(str(c))
	return ",".join(parts)


# ---------------------------------------------------------------- config

func _check_config() -> void:
	var c := dda.config
	_expect(c.tier2_upgrade_score == 75 and c.battle_high_score == 65 and c.battle_low_score == 35, "default battle thresholds")
	_expect(c.campfire_high_score == 70 and c.campfire_low_score == 30, "default campfire thresholds")
	_expect(c.shop_swap_score == 55 and c.broke_gold == 90 and c.broke_very_low_score == 15, "default shop thresholds")
	_expect(c.relic_rarity_scores == PackedInt32Array([1, 3, 5, 8]), "default relic scores")
	_expect(RunStats.new().dda_score == 50, "score starts at 50")
	var rewards: RewardConfig = load("res://custom_resources/reward_config.tres")
	_expect(c.shop_all_bought_items == rewards.shop_relic_count,
		"'bought everything on offer' (%d) must equal the shop's relic count (%d)" % [c.shop_all_bought_items, rewards.shop_relic_count])


func _check_relic_scoring() -> void:
	var rs := RunStats.new()
	var handler := (load("res://scenes/relic_handler/relic_handler.tscn") as PackedScene).instantiate() as RelicHandler
	handler.run_stats = rs
	var rare := load("res://relics/weapon/cinderbrand.tres") as Relic
	var before := rs.dda_score
	handler.add_relic(rare)
	var gained: int = rs.dda_score - before
	_expect(gained == dda.relic_score(rare.rarity), "picking up a relic adds its rarity score, got %d" % gained)
	var after_pick := rs.dda_score
	var count_before := handler.get_all_relics().size()
	handler.consume_relic(rare)
	_expect(rs.dda_score == after_pick, "consuming a relic keeps the score earned for it")
	_expect(handler.get_all_relics().size() == count_before - 1, "held-relic checks use the live count after consumption")
	handler.free()


# ---------------------------------------------------------------- one score function

func _check_score() -> void:
	var rs := RunStats.new()
	var applied := DDA.change_score(rs, 80, "test")
	_expect(rs.dda_score == 100 and applied == 50, "score clamps at 100 (applied %d)" % applied)
	_expect(rs.dda_state.history.back() == "test +50 -> 100", "change is recorded with its reason, got %s" % [rs.dda_state.history])
	DDA.change_score(rs, -500, "drop")
	_expect(rs.dda_score == 0, "score clamps at 0")
	var before := rs.dda_state.history.size()
	DDA.change_score(rs, 0, "nothing")
	_expect(rs.dda_state.history.size() == before, "a zero change records nothing")

	# Relic pickup goes through it.
	rs.dda_score = 50
	var handler := load("res://scenes/relic_handler/relic_handler.tscn").instantiate() as RelicHandler
	add_child(handler)
	handler.run_stats = rs
	await _frames()
	var uncommon: Relic = null
	for file in DirAccess.get_files_at("res://relics/trinket"):
		if file.ends_with(".tres"):
			var relic := load("res://relics/trinket/%s" % file) as Relic
			if relic and relic.rarity == Relic.Rarity.UNCOMMON and not relic.id.is_empty():
				uncommon = relic
				break
	_expect(uncommon != null, "an uncommon relic exists for the test")
	if uncommon:
		handler.add_relic(uncommon)
		_expect(rs.dda_score == 53, "uncommon relic adds 3, score is %d" % rs.dda_score)
		_expect(rs.dda_state.history.back() == "relic uncommon +3 -> 53", "relic change recorded, got %s" % [rs.dda_state.history.back()])
	handler.queue_free()

	# Event outcomes too.
	var event := EventRoom.new()
	event.character_stats = load("res://characters/player/player.tres").create_instance()
	event.run_stats = rs
	var outcome := EventOutcome.new()
	outcome.dda = 5
	outcome.apply(event)
	_expect(rs.dda_state.history.back().begins_with("event +5"), "event change recorded, got %s" % [rs.dda_state.history.back()])
	event.free()


# ---------------------------------------------------------------- score tables

func _check_score_tables() -> void:
	var battle := {3: -10, 5: -10, 20: -8, 25: -8, 40: -5, 45: -5, 50: 2, 54: 2, 55: 5, 70: 5, 75: 8, 90: 8, 95: 10, 100: 10}
	for hp in battle:
		_expect(dda.battle_score_delta(hp) == battle[hp], "battle at %d%% HP: expected %d, got %d" % [hp, battle[hp], dda.battle_score_delta(hp)])

	# Campfire: before resting; low HP now lowers the score, high HP raises it as before.
	var campfire := {100: 8, 91: 8, 90: 7, 85: 7, 75: 6, 65: 5, 55: 4, 50: 0, 47: 0, 45: -5, 30: -5, 20: -8, 3: -10}
	for hp in campfire:
		_expect(dda.campfire_score_delta(hp) == campfire[hp], "campfire at %d%% HP: expected %d, got %d" % [hp, campfire[hp], dda.campfire_score_delta(hp)])

	var rs := RunStats.new()
	dda.update_score_battle(0, 0, rs)
	dda.update_score_campfire(0, 0, rs)
	_expect(rs.dda_score == 50, "zero max HP must not change the score or crash")


# ---------------------------------------------------------------- decision tables

func _check_decisions() -> void:
	var fresh := DDAState.new()
	var used := DDAState.new()
	used.shop_changed = true

	# After a battle (score, hp, relics, gold, state) -> conversions
	var cases := [
		["battle hi, healthy", dda.decide_after_battle(70, 0.8, 3, 50, fresh), "CAMPFIRE->MONSTER"],
		["battle hi, hurt", dda.decide_after_battle(70, 0.3, 3, 50, fresh), "EVENT->MONSTER"],
		["battle hi, relics, flag free", dda.decide_after_battle(70, 0.8, 6, 50, fresh), "SHOP->MONSTER*"],
		["battle hi, relics, flag used", dda.decide_after_battle(70, 0.8, 6, 50, used), "CAMPFIRE->MONSTER"],
		["battle lo, rich", dda.decide_after_battle(30, 0.8, 3, 200, fresh), "MONSTER->SHOP"],
		["battle lo, poor", dda.decide_after_battle(30, 0.8, 3, 100, fresh), "MONSTER->CAMPFIRE"],
		["battle lo, rich but hurt", dda.decide_after_battle(30, 0.4, 3, 200, fresh), "MONSTER->CAMPFIRE"],
		["battle mid", dda.decide_after_battle(50, 0.8, 9, 500, fresh), ""],
		["campfire hi, arrived healthy", dda.decide_after_campfire(75, 0.6), "CAMPFIRE->MONSTER"],
		["campfire hi, arrived hurt", dda.decide_after_campfire(75, 0.4), "EVENT->MONSTER"],
		["campfire lo, arrived healthy", dda.decide_after_campfire(25, 0.6), "EVENT->CAMPFIRE"],
		["campfire lo, arrived hurt", dda.decide_after_campfire(25, 0.4), "MONSTER->CAMPFIRE"],
		["campfire mid", dda.decide_after_campfire(50, 0.4), ""],
		["shop bought all, loaded", dda.decide_after_shop(60, 8, 6, 10, fresh), "SHOP->MONSTER*"],
		["shop bought some", dda.decide_after_shop(60, 7, 6, 10, fresh), ""],
		["shop broke, very low", dda.decide_after_shop(10, 6, 6, 50, fresh), "MONSTER->TREASURE*"],
		["shop broke, low", dda.decide_after_shop(30, 6, 6, 50, fresh), "EVENT->TREASURE*"],
		["shop broke, ok score", dda.decide_after_shop(40, 6, 6, 50, fresh), ""],
		["shop with flag used", dda.decide_after_shop(10, 6, 6, 50, used), ""],
		["treasure, relics grew", dda.decide_after_treasure(60, 0.8, 5, 4, fresh), "SHOP->MONSTER*"],
		["treasure hi, healthy", dda.decide_after_treasure(75, 0.6, 3, 3, fresh), "CAMPFIRE->MONSTER"],
		["treasure hi, exactly half", dda.decide_after_treasure(75, 0.5, 3, 3, fresh), "EVENT->MONSTER"],
		["treasure mid", dda.decide_after_treasure(60, 0.6, 3, 3, fresh), ""],
	]
	for case in cases:
		var got := _names(case[1])
		_expect(got == case[2], "%s: expected '%s', got '%s'" % [case[0], case[2], got])

	_expect(dda.should_upgrade_to_tier2(75) and not dda.should_upgrade_to_tier2(74), "tier-2 upgrade at 75")


# ---------------------------------------------------------------- flags

func _check_flags() -> void:
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node\nvar result: Array = []\nvar calls := []\nfunc convert_rooms(a, b, c = 1):\n\tcalls.append([a, b, c])\n\treturn result\n"
	stub_script.reload()
	var stub := Node.new()
	stub.set_script(stub_script)

	var state := DDAState.new()
	var swap: Array[DDAConversion] = [DDAConversion.make(S, M, true)]

	stub.result = []
	_expect(dda.execute(swap, stub, state) == 0, "nothing to convert changes nothing")
	_expect(not state.shop_changed, "the once-per-act flag stays available when nothing converted")

	stub.result = [Room.new()]
	_expect(dda.execute(swap, stub, state) == 1, "a conversion reports the rooms it changed")
	_expect(state.shop_changed, "the flag is used after a real conversion")

	var plain_state := DDAState.new()
	var plain: Array[DDAConversion] = [DDAConversion.make(CF, M)]
	dda.execute(plain, stub, plain_state)
	_expect(not plain_state.shop_changed, "conversions without the flag never touch it")
	stub.free()


# ---------------------------------------------------------------- state, reset, saves

func _check_state_and_saves() -> void:
	var rs := RunStats.new()
	rs.dda_score = 63
	rs.dda_state.shop_changed = true
	rs.dda_state.treasure_pending = true
	rs.dda_state.shop_entered_items = 5
	DDA.change_score(rs, 2, "check")

	var path := "user://dda_check_stats.tres"
	ResourceSaver.save(rs, path)
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as RunStats
	_expect(loaded != null and loaded.dda_state.shop_changed and loaded.dda_state.treasure_pending, "flags survive saving")
	_expect(loaded != null and loaded.dda_state.shop_entered_items == 5, "shop count survives saving")
	_expect(loaded != null and loaded.dda_state.history.size() == 1, "history survives saving")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	rs.dda_state.reset_for_act()
	_expect(not rs.dda_state.shop_changed and not rs.dda_state.treasure_pending and rs.dda_state.shop_entered_items == 0, "flags reset for a new act")
	_expect(rs.dda_score == 65, "the score carries across acts")

	for i in 150:
		rs.dda_state.record("spam", 1, 50)
	_expect(rs.dda_state.history.size() <= DDAState.MAX_HISTORY, "history is capped")

	# The dead flag is gone from the save file.
	var save_properties := SaveGame.new().get_property_list().map(func(p): return p.name)
	_expect(not save_properties.has("dda_treasure_spawned"), "dead dda_treasure_spawned flag removed")


# ---------------------------------------------------------------- run level

func _reachable_target(run: Run) -> Room:
	for floor_rooms in run.map.map_data:
		for room: Room in floor_rooms:
			if room.active and room.row >= 2 and room.row <= 10 and run.map.get_reachable_rooms().has(room) and room.type == Room.Type.MONSTER:
				return room
	return null


## Reads the save file fresh (SaveGame.load_data may return Godot's cached copy).
func _load_save() -> SaveGame:
	return ResourceLoader.load(SAVE, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame


func _count_type(map_data: Array, type: Room.Type) -> int:
	var count := 0
	for floor_rooms in map_data:
		for room: Room in floor_rooms:
			if room.active and room.type == type:
				count += 1
	return count


func _check_run() -> void:
	var run := load("res://scenes/run/run.tscn").instantiate() as Run
	add_child(run)
	await _frames(3)

	# --- campfire: scored on arrival, before resting
	run.character.health = 12 # 30% of 40
	run.character.max_health = 40
	run.stats.dda_score = 50
	run._on_campfire_entered()
	await _frames(2)
	_expect(run.stats.dda_score == 45, "arriving at 30%% HP lowers the score by 5, score is %d" % run.stats.dda_score)
	_expect(absf(run.stats.dda_state.campfire_arrival_hp - 0.3) < 0.001, "arrival HP is remembered")
	run.character.heal(12)
	Events.campfire_exited.emit()
	await _frames(2)
	_expect(run.stats.dda_score == 45, "resting and leaving does not change the score again")

	# --- map: conversions change data at once and animate later
	run.map.hide_map()
	run.map.last_room = run.map.map_data[0][MapGenerator.MAP_WIDTH / 2]
	run.map.floors_climbed = 1
	var target := _reachable_target(run)
	_expect(target != null, "found a reachable room to convert")
	if target == null:
		run.queue_free()
		return
	target.type = Room.Type.EVENT
	target.original_type = Room.Type.EVENT
	var treasure_before := _count_type(run.map.map_data, T)
	_lock_events.clear()

	var changed := run.map.convert_rooms(EV, T, 1)
	_expect(changed.size() == 1 and changed[0].type == T, "convert_rooms changes the data at once and reports the room")
	_expect(_lock_events.is_empty(), "no animation plays while the map is hidden")
	_expect(not run.map._pending_conversions.is_empty(), "the animation waits for the next map view")

	# A save made right after the decision already holds the change.
	run._save_run(true)
	var saved := _load_save()
	_expect(saved != null and _count_type(saved.map_data, T) == treasure_before + 1, "the saved map contains the converted room")
	_expect(saved != null and saved.map_data[changed[0].row][changed[0].column].type == T, "the saved room has the new type")

	# Showing the map plays the pending animation and then releases the lock.
	run.map.show_map()
	_expect(_lock_events.size() >= 1 and _lock_events[0] == true, "showing the map starts the animation lock")
	var waited := 0.0
	while (_lock_events.is_empty() or _lock_events.back() == true) and waited < 12.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	_expect(not _lock_events.is_empty() and _lock_events.back() == false, "the animation lock is released")
	_expect(run.map._pending_conversions.is_empty(), "nothing is left pending")

	# --- shop exit: conversion happens before the map is shown and saved
	var event_room := _reachable_target(run)
	_expect(event_room != null, "found another room for the shop test")
	if event_room:
		event_room.type = Room.Type.EVENT
		event_room.original_type = Room.Type.EVENT
	run.stats.dda_score = 30
	run.stats.gold = 50
	run.stats.dda_state.shop_changed = false
	run.stats.dda_state.shop_entered_items = run.relic_handler.get_all_relics().size()
	var map_treasure_before := _count_type(run.map.map_data, T)
	run.map.hide_map()
	run._on_shop_exited()
	await _frames(2)
	_expect(run.stats.dda_state.shop_changed, "a real conversion uses the flag")
	var saved_after := _load_save()
	_expect(saved_after != null and _count_type(saved_after.map_data, T) == map_treasure_before + 1, "the save made on leaving the shop already has the conversion")

	# --- nothing to convert keeps the flag (real map, no reachable boss to convert)
	var state := run.stats.dda_state
	state.shop_changed = false
	var none_changed := dda.execute([DDAConversion.make(Room.Type.BOSS, Room.Type.MONSTER, true)], run.map, state)
	_expect(none_changed == 0 and not state.shop_changed, "protected or missing rooms leave the flag available")

	# --- a new act resets the flags and keeps the score
	state.shop_changed = true
	run.stats.dda_score = 61
	run._start_next_act()
	await _frames(2)
	_expect(not run.stats.dda_state.shop_changed, "a new act resets the DDA flags")
	_expect(run.stats.dda_score == 61, "a new act keeps the score")

	run.queue_free()
