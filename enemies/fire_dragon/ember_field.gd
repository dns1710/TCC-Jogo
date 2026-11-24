class_name EmberField
extends EnemyAction
## Passive (never chosen as an action). From boss phase 3 on, every time the Dragon
## completes an action the player gains 1 Scorch stack.

const SCORCH := preload("res://statuses/status_scorch.tres")


func _ready() -> void:
	type = Type.CONDITIONAL
	Events.enemy_action_completed.connect(_on_enemy_action_completed)


func is_performable() -> bool:
	return false


func _on_enemy_action_completed(completed: Enemy) -> void:
	if completed != enemy or enemy.phase < 3 or not is_instance_valid(target):
		return
	var applied: Status = SCORCH.duplicate()
	applied.stacks = 1
	target.status_handler.add_status(applied)
