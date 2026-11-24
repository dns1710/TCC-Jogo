class_name SentinelsAegis
extends Relic
## Start the combat with Ward, and regain it (if you have none) after every third Block.

@export var blocks_per_ward := 3

var blocks := 0
var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	blocks = 0
	var player := ItemFx.player(owner)
	if player:
		ItemFx.apply(player, ItemFx.WARD)
	if not Events.action_used.is_connected(_on_action_used):
		Events.action_used.connect(_on_action_used)
	ItemFx.flash(owner)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.action_used.is_connected(_on_action_used):
		Events.action_used.disconnect(_on_action_used)


func _on_action_used(action: Action) -> void:
	if action.type != Action.Type.BLOCK:
		return
	blocks += 1
	if blocks % blocks_per_ward != 0:
		return
	var player := ItemFx.player(relic_ui)
	if player and not ItemFx.has_status(player, "Ward"):
		ItemFx.apply(player, ItemFx.WARD)
		ItemFx.flash(relic_ui)
