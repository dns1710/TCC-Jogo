class_name Barbarian
extends Relic

const ATTACK_UP_STATUS = preload("res://statuses/status_attack_up.tres")

var relic_ui: RelicUI

func activate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		var attack_up := StatusEffect.new()
		attack_up.status = ATTACK_UP_STATUS.duplicate()
		attack_up.execute([player])
	owner.flash()
