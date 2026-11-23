class_name Icy
extends Relic

const SPEED_DOWN_STATUS = preload("res://statuses/status_speed_down.tres")

func on_attack_hit(targets: Array[Node]) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		var speedDown := StatusEffect.new()
		speedDown.status = SPEED_DOWN_STATUS.duplicate()
		speedDown.execute([target])
