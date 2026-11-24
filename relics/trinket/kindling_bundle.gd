class_name KindlingBundle
extends Relic
## When you Block, 1 Scorch lands on a random enemy.

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.action_used.is_connected(_on_action_used):
		Events.action_used.connect(_on_action_used)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.action_used.is_connected(_on_action_used):
		Events.action_used.disconnect(_on_action_used)


func _on_action_used(action: Action) -> void:
	if action.type != Action.Type.BLOCK or not is_instance_valid(relic_ui):
		return
	var targets := ItemFx.enemies(relic_ui)
	if targets.is_empty():
		return
	ItemFx.apply(targets[randi() % targets.size()], ItemFx.SCORCH, 1)
	ItemFx.flash(relic_ui)
