class_name EmberweaveTunic
extends Relic
## When you gain Scorch, gain 2 block per stack gained.

@export var block_per_stack := 2

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.status_added.is_connected(_on_status_added):
		Events.status_added.connect(_on_status_added)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.status_added.is_connected(_on_status_added):
		Events.status_added.disconnect(_on_status_added)


func _on_status_added(owner: Node, status: Status) -> void:
	if not owner is Player or status.id != "Scorch":
		return
	ItemFx.block(owner, maxi(status.stacks, 1) * block_per_stack)
	ItemFx.flash(relic_ui)
