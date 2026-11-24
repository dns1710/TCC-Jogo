class_name ScorchStatus
extends Status
## Stacking burn. At the end of each of its owner's actions it deals damage equal
## to its stacks, then loses one stack.

func apply_status(target: Node) -> void:
	if is_instance_valid(target) and stacks > 0:
		target.take_damage(stacks, Modifier.Type.NO_MODIFIER)
	stacks -= 1
	status_applied.emit(self)


func get_tooltip() -> String:
	return "Takes %d damage at the end of each action, then loses 1 stack." % stacks
