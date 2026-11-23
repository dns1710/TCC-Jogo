class_name Lighter
extends Relic

const BURN_STATUS = preload("res://statuses/status_burn.tres")

var first_attack := true

func activate_relic(_owner: RelicUI) -> void:
	first_attack = true
	_owner.flash()

func on_attack_hit(targets: Array[Node]) -> void:
	if !first_attack:
		return
		
	for target in targets:
		if not is_instance_valid(target):
			continue
		var burn:= StatusEffect.new()
		burn.status = BURN_STATUS.duplicate()
		burn.execute([target])
	
	first_attack = false
