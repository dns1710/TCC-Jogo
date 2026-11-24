extends Node
## Headless check of the combat-pacing spec: turn-bar timing, percent Speed Down,
## decay per action, tooltip text and the relic activation cap.
## Run: Godot --headless --path . res://tools/verify_combat_pacing.tscn

const SPEED_DOWN := preload("res://statuses/status_speed_down.tres")
const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const STEP := 0.05

var _errors: Array[String] = []


func _ready() -> void:
	await _run_checks()
	if _errors.is_empty():
		print("PACING CHECK OK")
		get_tree().quit(0)
	else:
		print("PACING CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _near(value: float, expected: float, tolerance: float, message: String) -> void:
	_expect(absf(value - expected) <= tolerance, "%s (expected %.2f, got %.2f)" % [message, expected, value])


func _frames(count := 2) -> void:
	for i in count:
		await get_tree().process_frame


func _make_enemy(path: String) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	enemy.stats = load(path)
	return enemy


func _slow(target: Node, stacks: int) -> void:
	var status: Status = SPEED_DOWN.duplicate()
	status.stacks = stacks
	target.status_handler.add_status(status)


func _time_to_act(actor: Node) -> float:
	var elapsed := 0.0
	while not actor.can_act and elapsed < 120.0:
		actor.add_atb(STEP)
		elapsed += STEP
	return elapsed


func _run_checks() -> void:
	_expect(ATBConfig.MAX == 20.0, "ATB requirement must be 20")
	_near(ATBConfig.MAX * ATBConfig.PLAYER_START_RATIO, 10.0, 0.001, "player starts at 50%")
	_near(ATBConfig.MAX * ATBConfig.ENEMY_START_MAX_RATIO, 6.67, 0.01, "enemy head start tops out at 33%")

	# Enemy timing: speed 4, no slow, then 3 stacks.
	var zscout := _make_enemy("res://enemies/zscout/zscout.tres")
	await _frames()
	_near(_time_to_act(zscout), 5.0, 0.1, "speed-4 enemy time to act")

	var slowed := _make_enemy("res://enemies/zscout/zscout.tres")
	await _frames()
	_slow(slowed, 3)
	_near(slowed.atb_rate_multiplier, pow(0.85, 3), 0.001, "3-stack multiplier")
	_expect(slowed.stats.speed == 4, "Speed Down must not change the speed stat")
	_near(_time_to_act(slowed), 8.14, 0.15, "speed-4 enemy with 3 stacks")

	# Low-speed enemy: 2 stacks on speed 3 is about 9.2s, not the old 20s.
	var croc := _make_enemy("res://enemies/croc/croc.tres")
	await _frames()
	_slow(croc, 2)
	_near(_time_to_act(croc), 9.23, 0.15, "speed-3 enemy with 2 stacks")

	# Decay: only the owner's actions count, one stack each, removed at zero.
	var owner := _make_enemy("res://enemies/zscout/zscout.tres")
	var bystander := _make_enemy("res://enemies/zscout/zscout.tres")
	await _frames()
	_slow(owner, 3)
	Events.enemy_action_completed.emit(bystander)
	_near(owner.atb_rate_multiplier, pow(0.85, 3), 0.001, "other enemy's action must not decay")
	Events.enemy_action_completed.emit(owner)
	_near(owner.atb_rate_multiplier, pow(0.85, 2), 0.001, "3 -> 2 stacks")
	Events.enemy_action_completed.emit(owner)
	_near(owner.atb_rate_multiplier, 0.85, 0.001, "2 -> 1 stacks")
	Events.enemy_action_completed.emit(owner)
	_near(owner.atb_rate_multiplier, 1.0, 0.001, "removed at zero stacks")
	await _frames()
	_expect(not owner.status_handler._has_status("SpeedDown"), "status must be gone at zero stacks")

	# Player: same rules through the player action event.
	var player := PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.stats = load("res://characters/player/player.tres").create_instance()
	await _frames()
	var speed := float(player.stats.speed)
	_near(_time_to_act(player), 20.0 / speed, 0.1, "player time to act")
	player.reset_atb()
	_slow(player, 2)
	_near(player.atb_rate_multiplier, pow(0.85, 2), 0.001, "player 2-stack multiplier")
	Events.player_action_completed.emit()
	_near(player.atb_rate_multiplier, 0.85, 0.001, "player decays on its own action")

	# Tooltip.
	var tip_status: Status = SPEED_DOWN.duplicate()
	tip_status.stacks = 2
	var tip := tip_status.get_tooltip()
	_expect(tip.contains("28%") and tip.contains("2 stacks"), "tooltip must show 28%% and 2 stacks, got: %s" % tip)

	# Relic activation wait.
	for count in range(1, 7):
		_near(RelicHandler.get_apply_interval(count), 0.25, 0.0001, "interval for %d relics" % count)
	_expect(RelicHandler.get_apply_interval(10) * 10 <= 1.5001, "10 relics must take no more than 1.5s")
	_expect(RelicHandler.get_apply_interval(20) * 20 <= 1.5001, "20 relics must take no more than 1.5s")

	await _check_croc()


func _speed_down_stacks(target: Node) -> int:
	var status: Status = target.status_handler._get_status("SpeedDown")
	return status.stacks if status else 0


func _await_enemy_action(enemy: Enemy) -> bool:
	var done := [false]
	var on_done := func(e: Enemy): if e == enemy: done[0] = true
	Events.enemy_action_completed.connect(on_done)
	var started := Time.get_ticks_msec()
	while not done[0] and Time.get_ticks_msec() - started < 6000:
		await get_tree().process_frame
	Events.enemy_action_completed.disconnect(on_done)
	return done[0]


func _check_croc() -> void:
	# Enemies target the first node in the "player" group, so clear earlier test players.
	for node in get_tree().get_nodes_in_group("player"):
		node.queue_free()
	await _frames()
	var victim := PLAYER_SCENE.instantiate() as Player
	add_child(victim)
	victim.stats = load("res://characters/player/player.tres").create_instance()
	await _frames()
	var croc := _make_enemy("res://enemies/croc/croc.tres")
	await _frames()
	var attack: EnemyAction = croc.enemy_action_picker.get_node("AttackAction")
	var grab: EnemyAction = croc.enemy_action_picker.get_node("GrabAction")

	# Opening hit: the grab applies 2 stacks.
	_expect(croc.do_action(), "croc must have an opening action")
	_expect(croc.current_action == grab, "croc must open with its grab")
	_expect(await _await_enemy_action(croc), "opening grab must finish")
	_expect(_speed_down_stacks(victim) == 2, "opening grab must apply 2 stacks, got %d" % _speed_down_stacks(victim))
	victim.stats.health = victim.stats.max_health

	# Afterwards the grab is spent and regular hits take over.
	croc.do_action()
	_expect(croc.current_action == attack, "after the grab the croc must use regular hits")
	await _await_enemy_action(croc)
	victim.stats.health = victim.stats.max_health

	# A guaranteed grab roll adds a stack; a zero chance adds none.
	var before := _speed_down_stacks(victim)
	attack.grab_chance = 1.0
	attack.perform_action()
	await _await_enemy_action(croc)
	_expect(_speed_down_stacks(victim) == before + 1, "a successful grab roll must add 1 stack")
	victim.stats.health = victim.stats.max_health

	before = _speed_down_stacks(victim)
	attack.grab_chance = 0.0
	attack.perform_action()
	await _await_enemy_action(croc)
	_expect(_speed_down_stacks(victim) == before, "a failed grab roll must add no stacks")

	# The default roll is 15%.
	var fresh_attack: EnemyAction = load("res://enemies/croc/croc_attack_action.gd").new()
	_near(fresh_attack.grab_chance, 0.15, 0.0001, "default grab chance")
	var hits := 0
	for i in 4000:
		if fresh_attack.should_grab():
			hits += 1
	_near(hits / 4000.0, 0.15, 0.03, "observed grab frequency")
