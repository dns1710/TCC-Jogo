class_name CooldownAction
extends EnemyAction
## Base for conditional actions limited to once per N of the actor's own actions.
## (Weighted picks never call is_performable, so gated actions must be CONDITIONAL.)

@export var cooldown_actions := 0
@export var duration := 0.6

var _actions_since_use := 999


func _ready() -> void:
	Events.enemy_action_completed.connect(_on_enemy_action_completed)


func is_performable() -> bool:
	return enemy != null and _actions_since_use >= cooldown_actions and _can_use()


## Override with extra conditions.
func _can_use() -> bool:
	return true


func _mark_used() -> void:
	_actions_since_use = -1 # the completion of this very action brings it to 0


## Ends the action after `duration` seconds.
func _finish_later() -> void:
	enemy.get_tree().create_timer(duration, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)


func _on_enemy_action_completed(completed: Enemy) -> void:
	if completed == enemy:
		_actions_since_use += 1


func get_allies(include_self := false, tag := "") -> Array[Enemy]:
	var allies: Array[Enemy] = []
	if not enemy or not enemy.get_parent():
		return allies
	for child in enemy.get_parent().get_children():
		if not child is Enemy or child.is_queued_for_deletion() or child.stats.health <= 0:
			continue
		if child == enemy and not include_self:
			continue
		if tag != "" and child.stats.tag != tag:
			continue
		allies.append(child)
	return allies
