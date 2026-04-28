extends Action
	
func apply_effects(targets: Array[Node]) -> void:
	var player = targets[0].get_tree().get_first_node_in_group("player")
	var damage_effect := DamageEffect.new()
	damage_effect.amount = player.stats.attack
	damage_effect.execute(targets)
	print("ATTACK:", player.stats.attack)
