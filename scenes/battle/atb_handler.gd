extends Node
class_name ATBManager

signal unit_ready(unit)

var actors: Array = []
var active_unit = null
var is_waiting_for_input := false

func _process(delta: float) -> void:
	if is_waiting_for_input:
		return
	
	for actor in actors:
		if not is_instance_valid(actor):
			continue
		
		actor.update_atb(delta)
		
		if actor.atb >= actor.max_atb:
			active_unit = actor
			is_waiting_for_input = true
			unit_ready.emit(actor)
			break
