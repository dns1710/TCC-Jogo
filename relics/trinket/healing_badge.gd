class_name HealingBadge
extends Relic

@export var dice_value := 4
@export var dice_amount := 2

func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player

	if player:
		var heal_amount = Dice.roll(dice_amount, dice_value)
		player.heal(heal_amount)
		owner.flash()
