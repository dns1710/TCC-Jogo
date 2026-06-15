class_name ATBManager
extends Node

var player: Player
var enemy_handler: EnemyHandler

var battle_running := false

var waiting_for_player := false
var enemy_acting := false
var enemy_queue: Array[Enemy] = []

func _ready() -> void:
	Events.player_action_completed.connect(_on_player_action_completed)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.enemy_died.connect(_on_enemy_died)
	
func start_battle(p_player: Player, p_enemy_handler: EnemyHandler) -> void:
	player = p_player
	enemy_handler = p_enemy_handler
	player.atb = player.ATB_MAX * 0.5
	battle_running = true

func _process(delta: float) -> void:
	if not battle_running:
		return

	if waiting_for_player:
		return
	
	if enemy_acting:
		return

	if is_instance_valid(player):
		player.add_atb(delta)

		if player.can_act:
			if not waiting_for_player:
				Events.player_atb_ready.emit()
			waiting_for_player = true
			enemy_queue.clear()
			return

	for enemy: Enemy in enemy_handler.get_children():
		if waiting_for_player:
			break
		if not is_instance_valid(enemy):
			continue

		enemy.add_atb(delta)

		if enemy.can_act:
			if not enemy_queue.has(enemy):
				enemy_queue.append(enemy)
	
	if not enemy_acting and not enemy_queue.is_empty():
		_start_next_enemy_action()

func _start_next_enemy_action() -> void:
	if enemy_queue.is_empty():
		return

	var enemy = enemy_queue.pop_front()

	if not is_instance_valid(enemy):
		_start_next_enemy_action()
		return

	enemy_acting = true

	enemy.can_act = false
	enemy.reset_atb()

	enemy.do_action()

func _on_player_action_completed() -> void:
	player.reset_atb()
	waiting_for_player = false
	
func _on_enemy_action_completed(enemy: Enemy) -> void:
	enemy_acting = false
	if not enemy_queue.is_empty():
		_start_next_enemy_action()

func _on_enemy_died(enemy: Enemy) -> void:
	enemy_queue.erase(enemy)

	if enemy_acting:
		enemy_acting = false

		if not enemy_queue.is_empty():
			_start_next_enemy_action()
