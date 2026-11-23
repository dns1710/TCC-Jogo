extends Relic

@export var attack_bonus := 2


func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	
	if player:
		player.stats.attack += attack_bonus
		owner.flash()


func deactivate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	
	if player:
		player.stats.attack -= attack_bonus
