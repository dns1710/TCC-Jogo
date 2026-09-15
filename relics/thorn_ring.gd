class_name ThornRing
extends Relic

const THORN_STATUS = preload("res://statuses/status_thorns.tres")
		
func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player._spawn_popup("THORNS UP", Color.DARK_GOLDENROD)
		var status_effect := StatusEffect.new()
		var thorns := THORN_STATUS.duplicate()
		status_effect.status = thorns
		status_effect.execute([player])
	owner.flash()
