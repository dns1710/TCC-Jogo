extends EnemyAction

@export var block = 3
var already_used := false
	
func perform_action() -> void:
	if not enemy:
		return
		
	already_used = true
	enemy.special_state = "PREPARE"
	enemy._spawn_popup("!!!", Color.RED)
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
