class_name BeanCan
extends Relic

@export var dice_value := 6
@export var dice_amount := 2

const POISON_STATUS = preload("res://statuses/status_poison.tres")

func activate_relic(_owner: RelicUI) -> void:
	var player := _owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		var poison := StatusEffect.new()
		poison.status = POISON_STATUS.duplicate()
		poison.execute([player])
		var heal_amount = Dice.roll(dice_amount, dice_value)
		player.heal(heal_amount)
	_owner.flash()
