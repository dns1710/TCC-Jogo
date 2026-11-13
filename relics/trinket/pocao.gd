class_name HealingPotion
extends Relic

@export var dice_value := 4
@export var dice_amount := 2
@export var dice_bonus := 2

func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	var half_hp := player.stats.max_health / 2.0
	var low_hp := player.stats.health <= half_hp
	
	if player and low_hp:
		var heal_amount = Dice.roll(dice_amount, dice_value, dice_bonus)
		player.heal(heal_amount)
		owner.flash()
