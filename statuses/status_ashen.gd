class_name AshenStatus
extends Status
## Block the owner gains is halved (rounded down) for its next actions.

const MULTIPLIER := 0.5

var _target: Node


func initialize_status(target: Node) -> void:
	_target = target
	target.block_gain_multiplier = MULTIPLIER
	if target is Enemy:
		Events.enemy_action_completed.connect(_on_enemy_action_completed)
	elif target is Player:
		Events.player_action_completed.connect(_on_player_action_completed)


func get_tooltip() -> String:
	return "Block gained is halved for %d more action%s." % [duration, "" if duration == 1 else "s"]


func _on_enemy_action_completed(enemy: Enemy) -> void:
	if enemy == _target:
		_tick()


func _on_player_action_completed() -> void:
	_tick()


func _tick() -> void:
	duration -= 1
	if duration > 0:
		return
	if is_instance_valid(_target):
		_target.block_gain_multiplier = 1.0
	if Events.enemy_action_completed.is_connected(_on_enemy_action_completed):
		Events.enemy_action_completed.disconnect(_on_enemy_action_completed)
	if Events.player_action_completed.is_connected(_on_player_action_completed):
		Events.player_action_completed.disconnect(_on_player_action_completed)
