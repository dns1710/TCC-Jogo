class_name Armor
extends Relic

@export var block_bonus := 1
var block_turn = false


func activate_relic(owner: RelicUI) -> void:
	if not block_turn:
		block_turn = true
	elif block_turn:
		var player := owner.get_tree().get_nodes_in_group("player")
		var block_effect := BlockEffect.new()
		block_effect.amount = block_bonus
		block_effect.execute(player)
		block_turn = false
		owner.flash()
