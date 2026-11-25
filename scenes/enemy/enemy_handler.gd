class_name EnemyHandler
extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const MAX_ENEMIES := 5
## Fixed battle slots for spawned enemies (x 148-211, y 68-98: on the ground of the Ice and Fire backgrounds).
const SLOTS: Array[Vector2] = [
	Vector2(196, 82), Vector2(166, 68), Vector2(166, 98), Vector2(210, 68), Vector2(210, 98),
]
const SLOT_TOLERANCE := 12.0
const FIZZLE_FALLBACK := 6.0

var acting_enemies: Array[Enemy] = []
## The act whose scaling applies to enemies spawned here (null = enemies as defined).
var act: Act


func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_turn_ended.connect(start_turn)

func setup_enemies(battle_stats: BattleStats) -> void:
	if not battle_stats:
		return

	for enemy: Enemy in get_children():
		enemy.queue_free()

	var all_new_enemies := battle_stats.enemies.instantiate()

	var by_name := {}
	for new_enemy: Node2D in all_new_enemies.get_children():
		var new_enemy_child := new_enemy.duplicate() as Enemy
		by_name[new_enemy.name] = new_enemy_child
		add_child(new_enemy_child)
		EnemyScaling.apply(new_enemy_child, act)
		new_enemy_child.home_position = new_enemy_child.position

		new_enemy_child.status_handler.statuses_applied.connect(
			_on_enemy_statuses_applied.bind(new_enemy_child)
		)
		
	for enemy: Enemy in by_name.values():
		if enemy.bound_to_name != "" and by_name.has(enemy.bound_to_name):
			enemy.summoner = by_name[enemy.bound_to_name]

	all_new_enemies.queue_free()

## Living enemies, ignoring those already queued for deletion.
func get_alive_enemies() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for child in get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			alive.append(child)
	return alive


func has_free_slot() -> bool:
	return get_alive_enemies().size() < MAX_ENEMIES and _free_slot() >= 0


func get_minions_of(summoner: Node) -> Array[Enemy]:
	var minions: Array[Enemy] = []
	for enemy in get_alive_enemies():
		if enemy.summoner == summoner:
			minions.append(enemy)
	return minions


## Adds an enemy mid-battle into the first free slot. Returns null when the battle
## is full (5 enemies) or no slot is free.
func spawn_enemy(stats: EnemyStats, summoner: Node = null) -> Enemy:
	if get_alive_enemies().size() >= MAX_ENEMIES:
		return null
	var slot_index := _free_slot()
	if slot_index < 0:
		return null

	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.stats = stats
	enemy.summoner = summoner
	enemy.position = SLOTS[slot_index]
	enemy.home_position = SLOTS[slot_index]
	add_child(enemy)
	EnemyScaling.apply(enemy, act)
	enemy.reset_atb()
	enemy.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(enemy))

	enemy.scale = Vector2(0.1, 0.1)
	var tween := enemy.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "scale", Vector2.ONE, 0.3)
	return enemy


func _free_slot() -> int:
	var alive := get_alive_enemies()
	for i in SLOTS.size():
		var taken := false
		for enemy in alive:
			if enemy.home_position.distance_to(SLOTS[i]) < SLOT_TOLERANCE:
				taken = true
				break
		if not taken:
			return i
	return -1


func _mark_minions_for_fizzle(summoner: Enemy) -> void:
	for minion in get_minions_of(summoner):
		if minion.fizzling:
			continue
		minion.fizzling = true
		var minion_ref: WeakRef = weakref(minion)
		get_tree().create_timer(FIZZLE_FALLBACK).timeout.connect(func(): _on_fizzle_fallback(minion_ref.get_ref()))


func _on_fizzle_fallback(minion) -> void:
	# An enemy mid-action fizzles when that action completes instead.
	if is_instance_valid(minion) and minion.fizzling and not minion.acting:
		minion.fizzle()


func start_enemy_turn(enemy):
	await get_tree().create_timer(0.3).timeout
	enemy.take_action()
	enemy.reset_atb()
	
func start_turn() -> void:
	if get_child_count() == 0:
		return

	acting_enemies.clear()

	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)

	_start_next_enemy_turn()

func _start_next_enemy_turn() -> void:
	acting_enemies = acting_enemies.filter(
		func(e): return is_instance_valid(e)
	)
	
	if acting_enemies.is_empty():
		Events.enemy_turn_ended.emit()
		return
	
	var next_enemy = acting_enemies[0]
	
	if not is_instance_valid(next_enemy):
		_start_next_enemy_turn()
		return

	acting_enemies[0].status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)


func _on_enemy_statuses_applied(type: Status.Type, enemy: Enemy) -> void:
	match type:
		Status.Type.START_OF_TURN:
			enemy.do_turn()

		Status.Type.END_OF_TURN:
			acting_enemies.erase(enemy)
			_start_next_enemy_turn()


func _on_enemy_died(enemy: Enemy) -> void:
	_mark_minions_for_fizzle(enemy)
	#var is_enemy_turn := acting_enemies.size() > 0
	var was_current_enemy := false
	
	if not acting_enemies.is_empty() and acting_enemies[0] == enemy:
		was_current_enemy = true
		
	acting_enemies.erase(enemy)
	
	if was_current_enemy:
		_start_next_enemy_turn()
	#if is_enemy_turn:
	#	_start_next_enemy_turn()

func _on_enemy_action_completed(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	enemy.acting = false
	if enemy.fizzling:
		# Deferred so the turn manager finishes handling this action first.
		enemy.fizzle.call_deferred()
		return
	enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()
