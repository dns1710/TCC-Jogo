class_name BiggerStick
extends Relic

var first_attack := true

func activate_relic(_owner: RelicUI) -> void:
	first_attack = true
	_owner.flash()

func get_weapon_bonus_damage() -> int:
	if !first_attack:
		return 0
	first_attack = false
	return Dice.roll(1,10)
