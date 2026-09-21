extends Action

@export var dice_value := 6
@export var dice_amount := 1

func apply_effects(targets: Array[Node]) -> void:
	var player = targets[0].get_tree().get_first_node_in_group("player")
	var damage = Dice.roll(dice_amount,dice_value,player.stats.attack)
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.execute(targets)
	Events.player_action_completed.emit()
	print(player.stats.attack)
