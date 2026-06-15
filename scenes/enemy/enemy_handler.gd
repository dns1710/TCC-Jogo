class_name EnemyHandler
extends Node2D

var acting_enemies: Array[Enemy] = []


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

	for new_enemy: Node2D in all_new_enemies.get_children():
		var new_enemy_child := new_enemy.duplicate() as Enemy
		add_child(new_enemy_child)

		new_enemy_child.status_handler.statuses_applied.connect(
			_on_enemy_statuses_applied.bind(new_enemy_child)
		)
		
	all_new_enemies.queue_free()


func reset_enemy_actions() -> void:
	for enemy: Enemy in get_children():
		enemy.current_action = null
		enemy.update_action()

func start_enemy_turn(enemy):
	await get_tree().create_timer(0.3).timeout
	
	enemy.take_action()
	enemy.reset_atb()
	
	#get_parent().atb_manager.is_waiting_for_input = false
	
func start_turn() -> void:
	if get_child_count() == 0:
		return

	acting_enemies.clear()

	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)

	_start_next_enemy_turn()

func _start_next_enemy_turn() -> void:
	#VVVVVVVVV
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
	enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()
