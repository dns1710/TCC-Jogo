class_name SummonAction
extends EnemyAction
## Spawns a minion through the EnemyHandler. Performable while the actor has fewer
## than `max_alive` minions, a battle slot is free, and `cooldown_actions` of its own
## actions have passed since the last summon.

@export var minion_stats: EnemyStats
@export var max_alive := 2
@export var cooldown_actions := 2
@export var duration := 0.6

var _actions_since_summon := 999


func _ready() -> void:
	Events.enemy_action_completed.connect(_on_enemy_action_completed)


func is_performable() -> bool:
	if not enemy or not minion_stats:
		return false
	var handler := enemy.get_parent() as EnemyHandler
	if not handler:
		return false
	return _actions_since_summon >= cooldown_actions \
		and handler.get_minions_of(enemy).size() < max_alive \
		and handler.has_free_slot()


func perform_action() -> void:
	if not enemy:
		return
	var handler := enemy.get_parent() as EnemyHandler
	if handler and minion_stats:
		handler.spawn_enemy(minion_stats, enemy)
	_actions_since_summon = -1 # the completion of this action brings it to 0
	if sound:
		SFXPlayer.play(sound)
	enemy.get_tree().create_timer(duration, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)


func _on_enemy_action_completed(completed: Enemy) -> void:
	if completed == enemy:
		_actions_since_summon += 1
