class_name AttackUpStatus
extends Status

func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed.bind(target))
	_on_status_changed(target)

func _on_status_changed(target: Node) -> void:
	assert(target.get("stats"), "No stats on %s" % target)
	target.stats.attack += stacks
