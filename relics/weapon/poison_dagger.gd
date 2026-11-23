class_name PoisonDagger
extends Relic

const POISON_STATUS = preload("res://statuses/status_poison.tres")

func on_attack_hit(targets: Array[Node]) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
		var poison := StatusEffect.new()
		poison.status = POISON_STATUS.duplicate()
		poison.execute([target])
