extends Node
## Headless check of the event-rooms spec: content validity, effects and clamps,
## weighted and stat-check resolution, the outcome screen, the per-act pool and
## the run-level flow (seen events, hooks, act reset).
## Run: Godot --headless --path . res://tools/verify_event_rooms.tscn
## Backs up and restores user://savegame.tres so a real save is never lost.

const POOLS := {
	"forest": "res://scenes/event_rooms/event_room_pool.tres",
	"ice": "res://scenes/event_rooms/pools/ice_events.tres",
	"fire": "res://scenes/event_rooms/pools/fire_events.tres",
}
const CHOICE_EVENT := preload("res://scenes/event_rooms/choice_event.tscn")
const SAVE := "user://savegame.tres"
const BACKUP := "user://savegame.event_check_backup"

var _errors: Array[String] = []
var _exited := false


func _ready() -> void:
	var had_save := FileAccess.file_exists(SAVE)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))

	Events.event_room_exited.connect(func(): _exited = true)
	_check_content()
	await _check_effects()
	await _check_resolution()
	await _check_screen()
	_check_pool()
	await _check_every_choice()
	await _check_run_flow()
	await _check_empty_treasure()

	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if _errors.is_empty():
		print("EVENT CHECK OK")
		get_tree().quit(0)
	else:
		print("EVENT CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 2) -> void:
	for i in count:
		await get_tree().process_frame


# ---------------------------------------------------------------- content

func _check_content() -> void:
	var all_paths: Array[String] = []
	for act in POOLS:
		var pool: EventRoomPool = load(POOLS[act])
		_expect(pool != null, "%s pool must load" % act)
		if pool == null:
			continue
		_expect(pool.events.size() >= 6, "%s pool must have at least 6 events, has %d" % [act, pool.events.size()])
		for event in pool.events:
			var id := event.resource_path
			_expect(not all_paths.has(id), "duplicate event %s" % id)
			all_paths.append(id)
			_expect(not event.title.is_empty() and event.title.length() <= 28, "%s: bad title" % id)
			_expect(not event.body.is_empty() and event.body.length() <= 120, "%s: body empty or over 120 characters" % id)
			_expect(event.choices.size() >= 1 and event.choices.size() <= 4, "%s: needs 1 to 4 choices" % id)
			for choice in event.choices:
				_expect(not choice.label.is_empty() and choice.label.length() <= 34, "%s: bad choice label '%s'" % [id, choice.label])
				_expect(choice.outcomes.size() >= 1, "%s: choice '%s' has no outcomes" % [id, choice.label])
				if choice.check_stat != EventChoice.CheckStat.NONE:
					_expect(choice.outcomes.size() >= 2, "%s: stat check needs success and failure" % id)
				for outcome in choice.outcomes:
					_expect(not outcome.text.is_empty() and outcome.text.length() <= 100, "%s: outcome text empty or over 100 characters" % id)
					_expect(outcome.weight > 0.0, "%s: outcome weight must be positive" % id)
	_expect(all_paths.size() == 24, "expected 24 events in total, found %d" % all_paths.size())


# ---------------------------------------------------------------- helpers

func _make_event(definition: EventDefinition) -> ChoiceEvent:
	var event := CHOICE_EVENT.instantiate() as ChoiceEvent
	add_child(event)
	event.character_stats = load("res://characters/player/player.tres").create_instance()
	event.run_stats = RunStats.new()
	event.definition = definition
	return event


func _outcome(fx: Dictionary) -> EventOutcome:
	var outcome := EventOutcome.new()
	outcome.text = "result"
	for key in fx:
		outcome.set(key, fx[key])
	return outcome


func _definition(choice: EventChoice) -> EventDefinition:
	var definition := EventDefinition.new()
	definition.title = "T"
	definition.body = "B"
	definition.choices = [choice]
	return definition


func _choice(outcomes: Array[EventOutcome]) -> EventChoice:
	var choice := EventChoice.new()
	choice.label = "go"
	choice.outcomes = outcomes
	return choice


func _apply(event: EventRoom, fx: Dictionary, bet := 0) -> Array[String]:
	return _outcome(fx).apply(event, bet)


# ---------------------------------------------------------------- effects

func _check_effects() -> void:
	var event := _make_event(EventDefinition.new())
	await _frames()
	var stats := event.character_stats
	var run := event.run_stats

	run.gold = 100
	_apply(event, {"gold": 45})
	# Gold gained follows the income scale (45 -> 23 at 0.5); gold lost is not scaled.
	_expect(run.gold == 100 + RewardRules.scale_gold(preload("res://custom_resources/reward_config.tres"), 45), "gold effect follows the income scale, got %d" % run.gold)
	var gold_after_gain := run.gold
	var lines := _apply(event, {"gold": -500})
	_expect(run.gold == 0, "gold must not go below 0")
	_expect(lines == ["-%d gold" % gold_after_gain], "gold line shows the real change, got %s" % [lines])
	run.gold = 50
	_apply(event, {"bet_multiplier": 2.0}, 50)
	_expect(run.gold == 150, "bet multiplier pays out bet x multiplier")

	stats.health = 5
	lines = _apply(event, {"hp": -8})
	_expect(stats.health == 1, "damage must leave at least 1 HP, got %d" % stats.health)
	_expect(lines == ["-4 HP"], "HP line shows the real change, got %s" % [lines])
	stats.health = 10
	_apply(event, {"heal_share": 0.5})
	_expect(stats.health == 30, "heal share of max HP (10 + 20), got %d" % stats.health)

	var max_hp := stats.max_health
	_apply(event, {"max_hp": 5})
	_expect(stats.max_health == max_hp + 5, "max HP effect")

	var attack := stats.max_attack
	var block := stats.max_block
	var speed := stats.max_speed
	_apply(event, {"attack": 2, "block": 1, "speed": 1})
	_expect(stats.max_attack == attack + 2 and stats.max_block == block + 1 and stats.max_speed == speed + 1, "attack, block and speed effects")
	_apply(event, {"speed": -50, "attack": -50})
	_expect(stats.max_speed == 1 and stats.max_attack == 1, "speed and attack keep their minimum of 1")

	run.rerolls = 2
	_apply(event, {"rerolls": -5})
	_expect(run.rerolls == 0, "rerolls must not go below 0")

	run.dda_score = 95
	_apply(event, {"dda": 20})
	_expect(run.dda_score == 100, "difficulty score clamps at 100")

	# Costs and affordability.
	var choice := EventChoice.new()
	choice.cost_gold = 50
	run.gold = 30
	_expect(not choice.can_afford(stats, run), "cannot afford 50 gold with 30")
	run.gold = 50
	_expect(choice.can_afford(stats, run), "can afford 50 gold with 50")
	var hp_choice := EventChoice.new()
	hp_choice.cost_hp = 12
	stats.health = 12
	_expect(not hp_choice.can_afford(stats, run), "an HP cost may not take the last HP")
	var all_in := EventChoice.new()
	all_in.all_in = true
	run.gold = 0
	_expect(not all_in.can_afford(stats, run), "all-in needs at least 1 gold")

	# Room conversion hook with a stub map.
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node\nvar calls := []\nfunc change_room(a, b, c = 1):\n\tcalls.append([a, b, c])\n"
	stub_script.reload()
	var stub := Node.new()
	stub.set_script(stub_script)
	event.map = stub
	lines = _apply(event, {"convert_from": Room.Type.MONSTER, "convert_to": Room.Type.CAMPFIRE})
	_expect(stub.calls == [[Room.Type.MONSTER, Room.Type.CAMPFIRE, 1]], "conversion must call change_room, got %s" % [stub.calls])
	_expect(lines.has("The path ahead shifts"), "conversion shows a line")
	stub.free()
	event.map = null

	# Relic hook.
	var handler := load("res://scenes/relic_handler/relic_handler.tscn").instantiate() as RelicHandler
	add_child(handler)
	event.relic_handler = handler
	event.relic_pool = _relic_pool()
	await _frames()
	lines = _apply(event, {"relic_rarity": 1})
	_expect(handler.get_all_relics().size() == 1, "an uncommon relic must be granted")
	_expect(handler.get_all_relics().size() == 1 and handler.get_all_relics()[0].rarity == 1, "granted relic must be uncommon")
	_expect(lines.size() == 1 and lines[0].begins_with("Found: "), "relic line names the relic, got %s" % [lines])
	var owned_before := handler.get_all_relics().size()
	for i in 60:
		_apply(event, {"relic_rarity": 1})
	_expect(handler.get_all_relics().size() > owned_before, "more relics can be found")
	var ids: Array[String] = []
	for relic in handler.get_all_relics():
		_expect(not ids.has(relic.id), "a relic must never be granted twice")
		ids.append(relic.id)

	event.queue_free()
	handler.queue_free()


func _relic_pool() -> Array[Relic]:
	var pool: Array[Relic] = []
	for folder in ["armor", "helmet", "trinket", "weapon"]:
		for file in DirAccess.get_files_at("res://relics/%s" % folder):
			if file.ends_with(".tres"):
				var relic := load("res://relics/%s/%s" % [folder, file]) as Relic
				if relic and not relic.id.is_empty():
					pool.append(relic)
	return pool


# ---------------------------------------------------------------- resolution

func _check_resolution() -> void:
	var event := _make_event(EventDefinition.new())
	await _frames()
	var stats := event.character_stats

	var coin := _choice([_outcome({"gold": 1}), _outcome({"gold": 2})])
	var first := 0
	for i in 2000:
		if coin.pick_outcome(stats).gold == 1:
			first += 1
	_expect(absf(first / 2000.0 - 0.5) < 0.05, "equal weights must land about 50%%, got %.3f" % (first / 2000.0))

	var heavy := _choice([_outcome({"gold": 1, "weight": 7.0}), _outcome({"gold": 2, "weight": 3.0})])
	first = 0
	for i in 3000:
		if heavy.pick_outcome(stats).gold == 1:
			first += 1
	_expect(absf(first / 3000.0 - 0.7) < 0.04, "7:3 weights must land about 70%%, got %.3f" % (first / 3000.0))

	var check := _choice([_outcome({"gold": 1}), _outcome({"gold": 2})])
	check.check_stat = EventChoice.CheckStat.SPEED
	check.check_base = 0.4
	check.check_per_point = 0.08
	stats.max_speed = 5
	_expect(absf(check.check_chance(stats) - 0.8) < 0.0001, "40%% + 8%% per point at speed 5 is 80%%")
	var wins := 0
	for i in 3000:
		if check.pick_outcome(stats).gold == 1:
			wins += 1
	_expect(absf(wins / 3000.0 - 0.8) < 0.04, "stat check must succeed about 80%%, got %.3f" % (wins / 3000.0))
	stats.max_speed = 20
	_expect(check.check_chance(stats) == 1.0, "stat check chance clamps at 100%")

	event.queue_free()


# ---------------------------------------------------------------- outcome screen

func _check_screen() -> void:
	var losing := _outcome({"text": "You lost.", "bet_multiplier": 0.0})
	var choice := _choice([losing])
	choice.cost_gold = 50
	var event := _make_event(_definition(choice))
	await _frames()
	event.run_stats.gold = 80
	event.setup()
	_expect(event.buttons.size() == 1 and not event.buttons[0].disabled, "affordable choice must be enabled")
	event.run_stats.gold = 30
	event.buttons[0].disabled = not choice.can_afford(event.character_stats, event.run_stats)
	_expect(event.buttons[0].disabled, "unaffordable choice must be disabled")
	event.choose(0)
	_expect(not event.chosen, "a disabled choice must not play out")

	event.run_stats.gold = 80
	event.choose(0)
	_expect(event.chosen and event.result_box.visible, "choosing shows the outcome screen")
	_expect(event.result_label.text == "result" or event.result_label.text == "You lost.", "outcome text is shown")
	_expect(event.effect_lines.has("-50 gold"), "cost line is shown, got %s" % [event.effect_lines])
	_expect(event.effects_box.get_child_count() == event.effect_lines.size(), "one label per effect line")
	_expect(ChoiceEvent._line_color("-50 gold") == ChoiceEvent.LOSS_COLOR, "losses are red")
	_expect(ChoiceEvent._line_color("+100 gold") == ChoiceEvent.GAIN_COLOR, "gains are green")
	_expect(ChoiceEvent._line_color("Found: Boot") == ChoiceEvent.NEUTRAL_COLOR, "other lines are neutral")
	_expect(event.effects_box.get_child(0).get_theme_color("font_color") == ChoiceEvent.LOSS_COLOR, "the cost label is drawn red")
	_expect(event.run_stats.gold == 30, "cost was paid")
	_expect(not event.choices_box.visible, "choices are hidden on the outcome screen")

	_exited = false
	_expect(not _exited, "must not leave before Continue")
	event.continue_button.pressed.emit()
	_expect(_exited, "Continue must emit event_room_exited")

	# A choice with no effects still gets an outcome screen.
	var quiet := _choice([_outcome({"text": "Nothing happens."})])
	var quiet_event := _make_event(_definition(quiet))
	await _frames()
	quiet_event.setup()
	quiet_event.choose(0)
	_expect(quiet_event.result_box.visible and quiet_event.continue_button.visible, "no-effect choice still shows an outcome screen")

	# The ported Slot Machine: an all-in either doubles or loses the bet.
	var slot: EventDefinition = load("res://scenes/event_rooms/events/forest/gamblers_stump.tres")
	var seen_win := false
	var seen_loss := false
	for i in 40:
		var slot_event := _make_event(slot)
		await _frames(1)
		slot_event.run_stats.gold = 200
		slot_event.setup()
		slot_event.choose(1)
		if slot_event.run_stats.gold == 400:
			seen_win = true
		elif slot_event.run_stats.gold == 0:
			seen_loss = true
		else:
			_errors.append("all-in must end at 400 or 0 gold, got %d" % slot_event.run_stats.gold)
		slot_event.queue_free()
	_expect(seen_win and seen_loss, "all-in must be able to win and lose")

	event.queue_free()
	quiet_event.queue_free()


# ---------------------------------------------------------------- every choice of every event

func _check_every_choice() -> void:
	var handler := load("res://scenes/relic_handler/relic_handler.tscn").instantiate() as RelicHandler
	add_child(handler)
	await _frames()
	var played := 0
	for act in POOLS:
		var pool: EventRoomPool = load(POOLS[act])
		for definition in pool.events:
			for i in definition.choices.size():
				var event := CHOICE_EVENT.instantiate() as ChoiceEvent
				add_child(event)
				event.character_stats = load("res://characters/player/player.tres").create_instance()
				event.run_stats = RunStats.new()
				event.run_stats.gold = 500
				event.run_stats.rerolls = 3
				event.relic_handler = handler
				event.relic_pool = _relic_pool()
				event.definition = definition
				await _frames(1)
				event.setup()
				event.choose(i)
				played += 1
				var where := "%s / '%s'" % [definition.resource_path.get_file(), definition.choices[i].label]
				_expect(event.chosen, "%s: choice did not play out" % where)
				_expect(event.result_box.visible and not event.result_label.text.is_empty(), "%s: no outcome screen text" % where)
				_expect(event.character_stats.health >= 1, "%s: left the player with less than 1 HP" % where)
				event.queue_free()
	_expect(played >= 60, "expected to play at least 60 choices, played %d" % played)
	handler.queue_free()


# ---------------------------------------------------------------- pool

func _check_pool() -> void:
	var pool: EventRoomPool = load(POOLS["forest"])
	var seen: Array[String] = []
	for i in pool.events.size():
		var picked := pool.pick(seen)
		_expect(not seen.has(picked.resource_path), "pick must not repeat an event while unseen remain")
		seen.append(picked.resource_path)
	var repeat := pool.pick(seen)
	_expect(repeat != null and seen.has(repeat.resource_path), "an exhausted pool falls back to a repeat")

	var run_stats := RunStats.new()
	run_stats.seen_events = ["a", "b"]
	var path := "user://event_check_stats.tres"
	ResourceSaver.save(run_stats, path)
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as RunStats
	_expect(loaded != null and loaded.seen_events == ["a", "b"], "seen events must survive saving")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ---------------------------------------------------------------- treasure room with nothing left to give

func _check_empty_treasure() -> void:
	var handler := load("res://scenes/relic_handler/relic_handler.tscn").instantiate() as RelicHandler
	add_child(handler)
	var treasure := load("res://scenes/treasure/treasure.tscn").instantiate() as Treasure
	add_child(treasure)
	await _frames()
	treasure.relic_handler = handler
	treasure.char_stats = load("res://characters/player/player.tres").create_instance()

	# Empty pool: no relic, and no crash.
	treasure.treasure_relic_pool = []
	treasure.generate_relic()
	_expect(treasure.found_relic == null, "an empty treasure pool finds no relic")

	# Every eligible relic already owned: still no crash.
	treasure.treasure_relic_pool = _relic_pool()
	for relic in treasure.treasure_relic_pool:
		handler.add_relic(relic, false)
	treasure.generate_relic()
	_expect(treasure.found_relic == null, "a treasure with everything already owned finds no relic")

	# The run turns that into a gold-only reward.
	var run := load("res://scenes/run/run.tscn").instantiate() as Run
	add_child(run)
	await _frames(3)
	run._on_treasure_room_exited(null)
	await _frames(3)
	var reward: BattleReward = null
	for child in run.current_view.get_children():
		if child is BattleReward:
			reward = child
	_expect(reward != null, "a null relic still opens the reward screen")
	_expect(reward != null and reward.rewards.get_child_count() == 1, "only the gold reward is offered")

	run.queue_free()
	treasure.queue_free()
	handler.queue_free()


# ---------------------------------------------------------------- run flow

func _check_run_flow() -> void:
	var run := load("res://scenes/run/run.tscn").instantiate() as Run
	add_child(run)
	await _frames(3)

	_expect(run.map.get_event_pool() == load(Run.ACTS[0].event_room_pool.resource_path), "Act 1 uses its own event pool")
	_expect(Run.ACTS[1].event_room_pool != Run.ACTS[0].event_room_pool, "Acts have different event pools")
	_expect(Run.ACTS[2].event_room_pool != Run.ACTS[1].event_room_pool, "Acts have different event pools")

	run._on_event_room_entered(null)
	await _frames(2)
	var first := _current_event(run)
	_expect(first != null, "entering an event room shows an event")
	_expect(first != null and first.relic_handler == run.relic_handler and first.map == run.map, "hooks are injected")
	_expect(first != null and first.relic_pool == run.battle_relic_pool, "relic pool is injected")
	var first_definition: EventDefinition = first.definition if first else null
	run._on_event_room_entered(null)
	await _frames(2)
	var second := _current_event(run)
	_expect(run.stats.seen_events.size() == 2, "two entries record two seen events")
	_expect(second != null and first_definition != null and second.definition != first_definition, "two entries give two different events")

	for i in 6:
		run._on_event_room_entered(null)
		await _frames(1)
	_expect(run.stats.seen_events.size() == 8, "eight entries see all 8 events, got %d" % run.stats.seen_events.size())
	var distinct := {}
	for path in run.stats.seen_events:
		distinct[path] = true
	_expect(distinct.size() == 8, "all seen events are distinct")

	run._start_next_act()
	await _frames(2)
	_expect(run.stats.seen_events.is_empty(), "a new act clears the seen events")
	_expect(run.map.get_event_pool() == Run.ACTS[1].event_room_pool, "Act 2 uses the Ice event pool")

	run.queue_free()


func _current_event(run: Run) -> ChoiceEvent:
	for child in run.current_view.get_children():
		if child is ChoiceEvent and not child.is_queued_for_deletion():
			return child
	return null
