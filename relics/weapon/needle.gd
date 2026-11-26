class_name Needle
extends Relic

var relic_ui: RelicUI

func activate_relic(_owner: RelicUI) -> void:
	relic_ui = _owner

func get_weapon_bonus_damage() -> int:
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	var bonus_dice = floor(player.stats.speed/3)
	if bonus_dice >= 1:
		return Dice.roll(bonus_dice,4)
	else:
		return 0
