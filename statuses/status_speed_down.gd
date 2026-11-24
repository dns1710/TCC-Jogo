class_name SpeedDownStatus
extends Status
## Percentage slow on the turn bar: each stack multiplies the owner's progress
## rate by RATE_PER_STACK (uncapped stacks, never a full stop). The owner loses
## one stack every time it completes an action, so a slow wears off.

const RATE_PER_STACK := 0.85

var _target: Node


func initialize_status(target: Node) -> void:
	assert(target.get("atb_rate_multiplier") != null, "No turn bar on %s" % target)
	_target = target
	status_changed.connect(_on_status_changed)

	if target is Enemy:
		Events.enemy_action_completed.connect(_on_enemy_action_completed)
	elif target is Player:
		Events.player_action_completed.connect(_on_player_action_completed)

	_on_status_changed()


func get_tooltip() -> String:
	var slower := roundi((1.0 - pow(RATE_PER_STACK, stacks)) * 100.0)
	return "Turn bar fills %d%% slower. %d stack%s left; loses 1 stack after each action." % [
		slower, stacks, "" if stacks == 1 else "s"
	]


func _on_status_changed() -> void:
	if is_instance_valid(_target):
		_target.atb_rate_multiplier = pow(RATE_PER_STACK, maxi(stacks, 0))

	if stacks <= 0:
		_disconnect_events()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	if enemy == _target:
		_decay()


func _on_player_action_completed() -> void:
	_decay()


func _decay() -> void:
	if not is_instance_valid(_target):
		_disconnect_events()
		return
	stacks -= 1


func _disconnect_events() -> void:
	if Events.enemy_action_completed.is_connected(_on_enemy_action_completed):
		Events.enemy_action_completed.disconnect(_on_enemy_action_completed)
	if Events.player_action_completed.is_connected(_on_player_action_completed):
		Events.player_action_completed.disconnect(_on_player_action_completed)
