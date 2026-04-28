class_name PocaoCura
extends Relic

@export var heal_amount := 4


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player.stats.heal(heal_amount)
		owner.flash()
