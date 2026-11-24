extends Node
## Headless check of the enemy-summoning spec: spawning, slot cap, fizzle rules,
## heal-allies, telegraph then strike, threshold action, summon cooldown, act background.
## Run: Godot --headless --path . res://tools/verify_enemy_summoning.tscn

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const HANDLER_SCRIPT := preload("res://scenes/enemy/enemy_handler.gd")
const ZSCOUT := preload("res://enemies/zscout/zscout.tres")
const STEP := 0.05

var _errors: Array[String] = []
var _player: Player


func _ready() -> void:
	await _run_checks()
	if _errors.is_empty():
		print("ENEMY SUMMONING CHECK OK")
		get_tree().quit(0)
	else:
		print("ENEMY SUMMONING CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 2) -> void:
	for i in count:
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _new_handler() -> EnemyHandler:
	var holder := Node2D.new()
	add_child(holder)
	var handler := EnemyHandler.new()
	holder.add_child(handler)
	return handler


func _stats(health := 20) -> EnemyStats:
	var stats: EnemyStats = ZSCOUT.duplicate()
	stats.max_health = health
	stats.max_block = 0
	return stats


func _await_completed(enemy: Enemy, timeout := 6.0) -> bool:
	var done := [false]
	var on_done := func(e: Enemy): if e == enemy: done[0] = true
	Events.enemy_action_completed.connect(on_done)
	var started := Time.get_ticks_msec()
	while not done[0] and Time.get_ticks_msec() - started < timeout * 1000.0:
		await get_tree().process_frame
	Events.enemy_action_completed.disconnect(on_done)
	return done[0]


func _run_checks() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	_player.stats = load("res://characters/player/player.tres").create_instance()
	_player.stats.max_health = 500
	_player.stats.health = 500
	await _frames()

	await _check_spawn_and_cap()
	await _check_fizzle()
	await _check_heal_allies()
	await _check_telegraph()
	await _check_threshold()
	await _check_summon_action()
	await _check_background()


func _check_spawn_and_cap() -> void:
	var handler := _new_handler()
	var summoner := handler.spawn_enemy(_stats())
	_expect(summoner != null, "spawn into an empty battle must work")
	var minion := handler.spawn_enemy(_stats(), summoner)
	await _frames()
	_expect(minion != null and handler.get_alive_enemies().size() == 2, "second spawn must add an enemy")
	if minion:
		_expect(minion.position != summoner.position, "spawned enemies must use different slots")
		_expect(minion.summoner == summoner, "spawned enemy must remember its summoner")
		_expect(minion.atb == 0.0, "spawned enemy must start with an empty bar")
		var t := 0.0
		while not minion.can_act and t < 30.0:
			minion.add_atb(STEP)
			t += STEP
		_expect(minion.can_act, "spawned enemy must fill its bar and become ready")
		_expect(minion.do_action(), "spawned enemy must have an action to perform")
		_expect(await _await_completed(minion), "spawned enemy must complete an action")
	# Fill to 5, refuse the 6th.
	for i in 3:
		handler.spawn_enemy(_stats(), summoner)
	_expect(handler.get_alive_enemies().size() == 5, "battle must hold 5 enemies, has %d" % handler.get_alive_enemies().size())
	_expect(handler.spawn_enemy(_stats(), summoner) == null, "sixth spawn must be refused")
	_expect(handler.get_alive_enemies().size() == 5, "refused spawn must not add an enemy")
	handler.get_parent().queue_free()
	await _frames()


func _kill(enemy: Enemy) -> void:
	enemy.take_damage(9999, Modifier.Type.NO_MODIFIER)


func _check_fizzle() -> void:
	# Summoner first: each minion acts once more, then dies; battle empties.
	var handler := _new_handler()
	var summoner := handler.spawn_enemy(_stats(30))
	var m1 := handler.spawn_enemy(_stats(), summoner)
	var m2 := handler.spawn_enemy(_stats(), summoner)
	await _frames()
	_kill(summoner)
	await _wait(0.5)
	_expect(is_instance_valid(m1) and m1.fizzling, "minion must be marked to fizzle when the summoner dies")
	_expect(handler.get_alive_enemies().size() == 2, "minions must survive until they act")
	m1.reset_atb()
	_expect(m1.do_action(), "fizzling minion still acts once")
	_expect(await _await_completed(m1), "fizzling minion action completes")
	await _wait(0.2)
	_expect(not is_instance_valid(m1) or m1.is_queued_for_deletion(), "minion must die after its next action")
	# m2 never acts: the 6 second fallback kills it.
	_expect(is_instance_valid(m2) and not m2.is_queued_for_deletion(), "second minion must still be alive before the fallback")
	await _wait(6.2)
	_expect(not is_instance_valid(m2) or m2.is_queued_for_deletion(), "minion must fizzle after 6 seconds without acting")
	await _frames()
	_expect(handler.get_child_count() == 0, "battle must be empty (victory) once only fizzled minions were left, has %d" % handler.get_child_count())
	handler.get_parent().queue_free()

	# Minion first: summoner unaffected and can summon again.
	handler = _new_handler()
	summoner = handler.spawn_enemy(_stats(30))
	m1 = handler.spawn_enemy(_stats(), summoner)
	await _frames()
	_kill(m1)
	await _wait(0.5)
	_expect(is_instance_valid(summoner) and not summoner.is_queued_for_deletion() and not summoner.fizzling, "summoner must be unaffected by a minion dying")
	_expect(handler.spawn_enemy(_stats(), summoner) != null, "summoner may summon again")
	handler.get_parent().queue_free()

	# Simultaneous deaths: no errors, nothing left.
	handler = _new_handler()
	summoner = handler.spawn_enemy(_stats(30))
	m1 = handler.spawn_enemy(_stats(), summoner)
	await _frames()
	_kill(summoner)
	_kill(m1)
	await _wait(0.6)
	await _frames()
	_expect(handler.get_alive_enemies().is_empty(), "simultaneous deaths must leave no enemies")
	handler.get_parent().queue_free()
	await _frames()


func _check_heal_allies() -> void:
	var handler := _new_handler()
	var healer := handler.spawn_enemy(_stats(30))
	var a := handler.spawn_enemy(_stats(8), healer)
	var b := handler.spawn_enemy(_stats(8), healer)
	await _frames()
	a.stats.health = 3
	healer.stats.health = 10
	var action := HealAlliesAction.new()
	action.amount = 6
	action.duration = 0.1
	action.enemy = healer
	healer.add_child(action)
	_expect(action.is_performable(), "heal must be performable while an ally is damaged")
	action.perform_action()
	await _await_completed(healer)
	_expect(a.stats.health == 8, "ally at 3 of 8 must be healed to 8 (clamped), is %d" % a.stats.health)
	_expect(b.stats.health == 8, "full-health ally must be unchanged")
	_expect(healer.stats.health == 10, "healer must not heal itself")
	_expect(not action.is_performable(), "heal must not be performable when nobody is damaged")
	handler.get_parent().queue_free()
	await _frames()


func _check_telegraph() -> void:
	var handler := _new_handler()
	var boss := handler.spawn_enemy(_stats(60))
	await _frames()
	var picker := EnemyActionPicker.new()
	var prepare := TelegraphAction.new()
	prepare.type = EnemyAction.Type.CHANCE_BASED
	prepare.chance_weight = 1.0
	prepare.block = 8
	prepare.duration = 0.1
	var strike := TelegraphedStrikeAction.new()
	strike.type = EnemyAction.Type.CONDITIONAL
	strike.dice_value = 4
	picker.add_child(prepare)
	picker.add_child(strike)
	boss.add_child(picker)
	picker.enemy = boss
	await _frames()
	_expect(picker.get_action() == prepare, "before preparing the prepare action is chosen")
	_expect(not strike.is_performable(), "strike must not be performable before the warning")
	prepare.perform_action()
	_expect(boss.special_state == TelegraphAction.STATE, "prepare must set the warning state")
	_expect(boss.stats.block == 8, "prepare must add its block, is %d" % boss.stats.block)
	await _await_completed(boss)
	_expect(picker.get_action() == strike, "the strike must be the next action after the warning")
	var before: int = _player.stats.health
	strike.perform_action()
	_expect(await _await_completed(boss), "strike must complete")
	_expect(_player.stats.health < before or _player.stats.block > 0, "strike must hit the player")
	_expect(boss.special_state == "", "strike must clear the warning")
	handler.get_parent().queue_free()
	await _frames()


func _check_threshold() -> void:
	var handler := _new_handler()
	var boss := handler.spawn_enemy(_stats(20))
	await _frames()
	var action := ThresholdAction.new()
	action.threshold = 0.5
	action.duration = 0.1
	action.enemy = boss
	boss.add_child(action)
	_expect(not action.is_performable(), "threshold action must wait while health is above the share")
	boss.stats.health = 10
	_expect(action.is_performable(), "threshold action must be available at 50%")
	action.perform_action()
	await _await_completed(boss)
	_expect(not action.is_performable(), "threshold action must never be used again")
	boss.stats.health = 2
	_expect(not action.is_performable(), "threshold action stays spent at lower health")
	handler.get_parent().queue_free()
	await _frames()


func _check_summon_action() -> void:
	var handler := _new_handler()
	var summoner := handler.spawn_enemy(_stats(30))
	await _frames()
	var action := SummonAction.new()
	action.minion_stats = _stats(8)
	action.max_alive = 2
	action.cooldown_actions = 2
	action.duration = 0.1
	action.enemy = summoner
	summoner.add_child(action)
	await _frames()
	_expect(action.is_performable(), "summon must be performable at the start")
	action.perform_action()
	await _await_completed(summoner)
	_expect(handler.get_minions_of(summoner).size() == 1, "first summon must add a minion")
	_expect(not action.is_performable(), "summon must wait for its cooldown in actions")
	Events.enemy_action_completed.emit(summoner)
	_expect(not action.is_performable(), "summon still on cooldown after 1 action")
	Events.enemy_action_completed.emit(summoner)
	_expect(action.is_performable(), "summon ready after 2 actions")
	action.perform_action()
	await _await_completed(summoner)
	for i in 3:
		Events.enemy_action_completed.emit(summoner)
	_expect(handler.get_minions_of(summoner).size() == 2, "second summon must add a minion")
	_expect(not action.is_performable(), "summon must stop at max_alive minions")
	handler.get_parent().queue_free()
	await _frames()


func _check_background() -> void:
	var battle := BATTLE_SCENE.instantiate() as Battle
	add_child(battle)
	await _frames()
	var forest: Texture2D = battle.background.texture
	var forest_scale: Vector2 = battle.background.scale
	battle.apply_background()
	_expect(battle.background.texture == forest and battle.background.scale == forest_scale, "forest background must stay when the act defines none")
	var texture: Texture2D = load("res://art/verdadeira arte/bg_neve_ato2.png")
	battle.battle_background = texture
	battle.apply_background()
	_expect(battle.background.texture == texture, "the act's background must be used when defined")
	var drawn := texture.get_size() * battle.background.scale
	_expect(absf(drawn.x - 256.0) < 0.5 and absf(drawn.y - 144.0) < 0.5, "background must fill 256x144, drawn %s" % str(drawn))
	battle.queue_free()
	await _frames()
