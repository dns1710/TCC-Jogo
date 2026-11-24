class_name ImpFrenzy
extends EnemyAction
## Passive (never chosen as an action). Each time another imp dies, this imp gains
## 1 Speed Up stack, up to MAX_STACKS.

const SPEED_UP := preload("res://statuses/status_speed_up.tres")
const MAX_STACKS := 3

var _stacks_given := 0


func _ready() -> void:
	type = Type.CONDITIONAL
	Events.enemy_died.connect(_on_enemy_died)


func is_performable() -> bool:
	return false


func _on_enemy_died(dead: Enemy) -> void:
	if not is_instance_valid(enemy) or dead == enemy or enemy.is_queued_for_deletion():
		return
	if dead.stats.tag != enemy.stats.tag or _stacks_given >= MAX_STACKS:
		return
	_stacks_given += 1
	var applied: Status = SPEED_UP.duplicate()
	applied.stacks = 1
	enemy.status_handler.add_status(applied)
