class_name StatusAction
extends CooldownAction
## Applies statuses without damage: to the player, itself, or its allies. With a
## cooldown, a target filter or a requirement it is used as a CONDITIONAL action
## (set `conditional`); otherwise it is a plain weighted action.

enum Targets {PLAYER, SELF, ALLIES, ALLIES_AND_SELF}

@export var targets_kind := Targets.PLAYER
@export var statuses: Array[Status] = []
## Stacks per status (parallel to `statuses`; missing entries mean 1).
@export var stack_counts: Array[int] = []
@export var warning_text := ""
## Only usable when the player has this status id (empty = always).
@export var requires_player_status := ""
## Only usable while the player could be frozen right now.
@export var requires_freezable := false
## Only usable when the actor has at least one living ally (of `ally_tag` if set).
@export var requires_ally := false
@export var ally_tag := ""
@export var conditional := false


func is_performable() -> bool:
	return conditional and super.is_performable()


func _can_use() -> bool:
	if requires_player_status != "":
		if not is_instance_valid(target) or not target.status_handler._has_status(requires_player_status):
			return false
	if requires_freezable and (not is_instance_valid(target) or not target.atb_mods.can_freeze()):
		return false
	if requires_ally and get_allies(false, ally_tag).is_empty():
		return false
	return true


func perform_action() -> void:
	if not enemy:
		return
	_mark_used()
	if warning_text != "":
		enemy._spawn_popup(warning_text, Color.WHITE)
	for receiver in _receivers():
		for i in statuses.size():
			var applied: Status = statuses[i].duplicate()
			if applied.stack_type == Status.StackType.INTENSITY:
				applied.stacks = stack_counts[i] if i < stack_counts.size() else 1
			var effect := StatusEffect.new()
			effect.status = applied
			var list: Array[Node] = [receiver]
			effect.execute(list)
	if sound:
		SFXPlayer.play(sound)
	_finish_later()


func _receivers() -> Array[Node]:
	var result: Array[Node] = []
	match targets_kind:
		Targets.PLAYER:
			if is_instance_valid(target):
				result.append(target)
		Targets.SELF:
			result.append(enemy)
		Targets.ALLIES:
			for ally in get_allies(false, ally_tag):
				result.append(ally)
		Targets.ALLIES_AND_SELF:
			for ally in get_allies(true, ally_tag):
				result.append(ally)
	return result
