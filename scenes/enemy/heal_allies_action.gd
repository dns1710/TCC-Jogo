class_name HealAlliesAction
extends EnemyAction
## Restores health to every living ally of the actor (never itself), up to their maximum.
## As a CONDITIONAL action it is only performable while some ally is damaged.

@export var amount := 6
## Seconds the action takes, so the heal reads before the next turn.
@export var duration := 0.6


func is_performable() -> bool:
	for ally in _get_allies():
		if ally.stats.health < ally.stats.max_health:
			return true
	return false


func perform_action() -> void:
	if not enemy:
		return
	for ally in _get_allies():
		if ally.stats.health < ally.stats.max_health:
			ally.heal(mini(amount, ally.stats.max_health - ally.stats.health))
	if sound:
		SFXPlayer.play(sound)
	enemy.get_tree().create_timer(duration, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)


func _get_allies() -> Array[Enemy]:
	var allies: Array[Enemy] = []
	if not enemy or not enemy.get_parent():
		return allies
	for child in enemy.get_parent().get_children():
		if child is Enemy and child != enemy and not child.is_queued_for_deletion() and child.stats.health > 0:
			allies.append(child)
	return allies
