class_name ShieldRelic
extends Relic

@export var block_bonus := 2

var applied := false


func activate_relic(owner: RelicUI) -> void:
	if applied:
		return

	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player.stats.max_block += block_bonus
		owner.flash()
		applied = true


func deactivate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player.stats.max_block -= block_bonus

	applied = false
