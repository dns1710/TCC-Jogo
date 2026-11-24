extends Node
## Headless run-level check of act progression: carry-over, full heal, act
## advance, saves, and the Act 1-only first-battle reward.
## Run: Godot --headless --path . res://tools/verify_act_flow.tscn
## Backs up and restores user://savegame.tres so a real save is never lost.

const SAVE := "user://savegame.tres"
const BACKUP := "user://savegame.act_flow_backup"

var _errors: Array[String] = []


func _ready() -> void:
	var had_save := FileAccess.file_exists(SAVE)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))

	await _run_checks()

	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if _errors.is_empty():
		print("ACT FLOW OK")
		get_tree().quit(0)
	else:
		print("ACT FLOW FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


func _run_checks() -> void:
	var run := load("res://scenes/run/run.tscn").instantiate() as Run
	add_child(run)
	await _frames()

	_expect(run.act_index == 0, "new run must start in Act 1")
	_expect(run.map.current_act == Run.ACTS[0], "map must use Act 1")

	# First battle of Act 1 gives the starting reward (gold + weapon + gear).
	var act1_rewards := await _first_battle_reward_count(run)
	# Same room in Act 2 gives the regular reward.
	run.act_index = 1
	var act2_rewards := await _first_battle_reward_count(run)
	run.act_index = 0
	_expect(act1_rewards > act2_rewards, "Act 1 first battle must give more rewards than Act 2 (got %d vs %d)" % [act1_rewards, act2_rewards])

	# Carry-over across the act boundary.
	run.character.health = 1
	run.stats.gold = 120
	run.stats.rerolls = 2
	var relic_count := run.relic_handler.get_all_relics().size()
	run._start_next_act()
	await _frames()

	_expect(run.act_index == 1, "boss victory must advance to Act 2")
	_expect(run.character.health == run.character.max_health, "player must be fully healed")
	_expect(run.stats.gold == 120, "gold must carry over")
	_expect(run.stats.rerolls == 2, "rerolls must carry over")
	_expect(run.relic_handler.get_all_relics().size() == relic_count, "relics must carry over")
	_expect(run.map.current_act == Run.ACTS[1], "map must use Act 2")
	_expect(run.map.floors_climbed == 0 and not run.map.map_data.is_empty(), "Act 2 must start at floor 0 with a map")

	var saved := SaveGame.load_data()
	_expect(saved != null and saved.act_index == 1, "save must record Act 2")

	run._start_next_act()
	run._start_next_act()
	_expect(run.act_index == Run.ACTS.size() - 1, "act index must clamp at the last act")

	# Transition screen shows lore and the next act.
	var transition := Run.ACT_TRANSITION_SCENE.instantiate() as ActTransition
	add_child(transition)
	await _frames(2)
	transition.setup(Run.ACTS[0], Run.ACTS[1])
	_expect(transition.body_label.text == Run.ACTS[0].transition_text, "transition must show the lore")
	_expect(transition.next_label.text.contains(Run.ACTS[1].act_name), "transition must name the next act")

	run.queue_free()
	transition.queue_free()


func _first_battle_reward_count(run: Run) -> int:
	var start_room: Room = run.map.map_data[0][MapGenerator.MAP_WIDTH / 2]
	run.map.last_room = start_room
	run.map.floors_climbed = 1
	run._on_battle_won()
	await _frames(4)

	var reward: BattleReward = null
	for child in run.current_view.get_children():
		if child is BattleReward:
			reward = child
	if reward == null:
		_errors.append("no reward screen after the first battle")
		return 0
	return reward.rewards.get_child_count()
