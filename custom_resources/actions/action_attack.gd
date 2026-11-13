extends Action

func apply_effects(targets: Array[Node]) -> void:
	var player = targets[0].get_tree().get_first_node_in_group("player")
	var relic_handler := player.get_tree().get_first_node_in_group("relic_handler")
	
	var damage = relic_handler.get_weapon_damage()
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	#await player.attack_animation()
	damage_effect.execute(targets)
	
	Events.player_action_completed.emit()
