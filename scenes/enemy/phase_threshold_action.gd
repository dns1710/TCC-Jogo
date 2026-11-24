class_name PhaseThresholdAction
extends ThresholdAction
## One-time boss phase change at a health share: raises enemy.phase, optionally
## buffs itself (or every living enemy) and grants slow immunity.

@export var phase_to := 2
@export var popup_text := "!!!"
@export var self_statuses: Array[Status] = []
@export var self_stacks: Array[int] = []
@export var all_enemies_statuses: Array[Status] = []
@export var all_enemies_stacks: Array[int] = []
@export var grants_slow_immunity := false


func _on_threshold() -> void:
	enemy.phase = maxi(enemy.phase, phase_to)
	enemy._spawn_popup(popup_text, Color.RED)
	_give(enemy, self_statuses, self_stacks)
	if not all_enemies_statuses.is_empty() and enemy.get_parent():
		for child in enemy.get_parent().get_children():
			if child is Enemy and not child.is_queued_for_deletion() and child.stats.health > 0:
				_give(child, all_enemies_statuses, all_enemies_stacks)
	if grants_slow_immunity:
		enemy.slow_immune = true
		enemy.atb_mods.clear_factor("speed_down")
		var slow: Status = enemy.status_handler._get_status("SpeedDown")
		if slow:
			slow.stacks = 0


func _give(receiver: Enemy, list: Array[Status], stacks: Array[int]) -> void:
	for i in list.size():
		var applied: Status = list[i].duplicate()
		if applied.stack_type == Status.StackType.INTENSITY:
			applied.stacks = stacks[i] if i < stacks.size() else 1
		receiver.status_handler.add_status(applied)
