class_name AttackUpStatus
extends Status

var applied_stacks := 0

func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)

func _on_status_changed(target: Node) -> void:
	assert(target.get("stats"), "No stats on %s" % target)
	var stack_difference := stacks - applied_stacks
	target.stats.attack += stack_difference
	applied_stacks = stacks
