class_name SummonAction
extends EnemyAction
## Spawns minions through the EnemyHandler. Performable while the actor has fewer
## than `max_alive` minions, a battle slot is free, `cooldown_actions` of its own
## actions have passed since the last summon, and its boss phase is high enough.

@export var minion_stats: EnemyStats
@export var max_alive := 2
@export var cooldown_actions := 2
@export var duration := 0.6
## Minions spawned per summon (limited by max_alive and free slots).
@export var summon_count := 1
## Only usable from this boss phase on.
@export var min_phase := 1

var _actions_since_summon := 999


func _ready() -> void:
	Events.enemy_action_completed.connect(_on_enemy_action_completed)


func is_performable() -> bool:
	if not enemy or not minion_stats:
		return false
	var handler := enemy.get_parent() as EnemyHandler
	if not handler:
		return false
	return enemy.phase >= min_phase \
		and _actions_since_summon >= cooldown_actions \
		and handler.get_minions_of(enemy).size() < max_alive \
		and handler.has_free_slot()


func perform_action() -> void:
	if not enemy:
		return
	var handler := enemy.get_parent() as EnemyHandler
	if handler and minion_stats:
		for i in summon_count:
			if handler.get_minions_of(enemy).size() >= max_alive:
				break
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
