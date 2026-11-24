class_name GainBlockAction
extends EnemyAction
## Gains block each time, never above `cap` (0 = no cap).

@export var amount := 4
@export var cap := 0
@export var duration := 0.6


func perform_action() -> void:
	if not enemy:
		return
	var gain := amount
	if cap > 0:
		gain = clampi(cap - enemy.stats.block, 0, amount)
	var block_effect := BlockEffect.new()
	block_effect.amount = gain
	block_effect.sound = sound
	var targets: Array[Node] = [enemy]
	block_effect.execute(targets)
	enemy.get_tree().create_timer(duration, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)
