class_name ThresholdAction
extends EnemyAction
## Performable once, as soon as the actor's health is at or below `threshold` of its
## maximum; CONDITIONAL, so it takes priority over ordinary actions. Subclasses
## override _on_threshold() (and may call _finish() later; the default finishes at once).

@export_range(0.0, 1.0) var threshold := 0.5
@export var duration := 0.6

var used := false


func is_performable() -> bool:
	if used or not enemy:
		return false
	return enemy.stats.health <= enemy.stats.max_health * threshold


func perform_action() -> void:
	if not enemy:
		return
	used = true
	_on_threshold()
	enemy.get_tree().create_timer(duration, false).timeout.connect(_finish)


func _on_threshold() -> void:
	enemy._spawn_popup("!!!", Color.RED)


func _finish() -> void:
	if is_instance_valid(enemy):
		Events.enemy_action_completed.emit(enemy)
