class_name SunderStatus
extends Status
## The next hit the owner takes ignores its block, then Sunder ends. The actor's
## take_damage reads and clears the flag; this status only sets it and ends on the hit.

var _target: Node


func initialize_status(target: Node) -> void:
	_target = target
	target.ignore_block_next_hit = true
	target.damage_received.connect(_on_damage_received)


func get_tooltip() -> String:
	return "The next hit taken ignores block."


func _on_damage_received(_amount: int, which_modifier: Modifier.Type) -> void:
	if which_modifier != Modifier.Type.DMG_TAKEN:
		return
	if is_instance_valid(_target):
		_target.damage_received.disconnect(_on_damage_received)
	can_expire = true
	duration = 0
