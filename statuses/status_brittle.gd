class_name BrittleStatus
extends Status
## The next hit the owner takes that was rolled with dice gains one extra die of the same
## size (a 1d6 hit becomes 2d6), then Brittle ends. Flat hits (Thorns, item bonuses) neither
## use nor spend it. The actor's take_damage reads and clears the flag; this status only sets
## it and ends once the flag is spent.

var _target: Node


func initialize_status(target: Node) -> void:
	_target = target
	target.brittle_next_hit = true
	target.damage_received.connect(_on_damage_received)


func get_tooltip() -> String:
	return "The next hit taken rolls one extra die of its own size."


func _on_damage_received(_amount: int, which_modifier: Modifier.Type) -> void:
	if which_modifier != Modifier.Type.DMG_TAKEN:
		return
	if not is_instance_valid(_target) or _target.brittle_next_hit:
		return
	_target.damage_received.disconnect(_on_damage_received)
	can_expire = true
	duration = 0
