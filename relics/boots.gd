class_name Boots
extends Relic

#@export var speed_bonus := 2
#var applied = false

#func activate_relic(owner: RelicUI) -> void:
#	var player := owner.get_tree().get_first_node_in_group("player") as Player
	
#	if applied:
#		return
		
#	if player:
#		applied = true
#		player.stats.speed += speed_bonus
#		owner.flash()


#func deactivate_relic(owner: RelicUI) -> void:
#	var player := owner.get_tree().get_first_node_in_group("player") as Player
#	if player:
#		applied = false
#		player.stats.speed -= speed_bonus
