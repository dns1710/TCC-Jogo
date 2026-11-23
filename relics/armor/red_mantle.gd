extends Relic

func activate_relic(_owner: RelicUI) -> void:
	var player := _owner.get_tree().get_first_node_in_group("player") as Player
	var bonus_block = floor(player.stats.speed/2)
	if bonus_block >= 1:
		var block_effect := BlockEffect.new()
		block_effect.amount = bonus_block
		block_effect.execute([player])
		_owner.flash()
	else:
		return
