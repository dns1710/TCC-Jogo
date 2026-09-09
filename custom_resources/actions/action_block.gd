extends Action

func apply_effects(targets: Array[Node]) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = 5
	block_effect.execute(targets)
	Events.player_action_completed.emit()
