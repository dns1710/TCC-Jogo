class_name WardenVisage
extends Relic
## Every stacking debuff applied to an enemy (Scorch, Speed Down, Attack Down) gets +1 stack.

@export var extra_stacks := 1

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.status_added.is_connected(_on_status_added):
		Events.status_added.connect(_on_status_added)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.status_added.is_connected(_on_status_added):
		Events.status_added.disconnect(_on_status_added)


func _on_status_added(owner: Node, status: Status) -> void:
	if not owner is Enemy or not status.id in ItemFx.STACKING_DEBUFFS:
		return
	var current := ItemFx.get_status(owner, status.id)
	if current:
		current.stacks += extra_stacks
		ItemFx.flash(relic_ui)
