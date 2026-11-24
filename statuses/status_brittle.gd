class_name BrittleStatus
extends Status
## The next hit the owner takes deals 50% more damage, then Brittle ends.

const SOURCE := "brittle"
const BONUS := 0.5

var _target: Node


func initialize_status(target: Node) -> void:
	_target = target
	var modifier: Modifier = target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
	var value := ModifierValue.create_new_modifier(SOURCE, ModifierValue.Type.PERCENT_BASED)
	value.percent_value = BONUS
	modifier.add_new_value(value)
	target.damage_received.connect(_on_damage_received)


func get_tooltip() -> String:
	return "The next hit taken deals 50% more damage."


func _on_damage_received(_amount: int, which_modifier: Modifier.Type) -> void:
	if which_modifier != Modifier.Type.DMG_TAKEN:
		return
	if is_instance_valid(_target):
		_target.damage_received.disconnect(_on_damage_received)
		var modifier: Modifier = _target.modifier_handler.get_modifier(Modifier.Type.DMG_TAKEN)
		var value := modifier.get_value(SOURCE)
		if value:
			modifier.remove_child(value)
			value.queue_free()
	can_expire = true
	duration = 0
