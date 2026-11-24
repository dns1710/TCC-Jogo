class_name GlassHeart
extends Relic
## You are always Brittle: it comes back 3 of your actions after a hit consumes it.

@export var recover_after := 3

var relic_ui: RelicUI
var countdown := -1


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	countdown = -1
	var player := ItemFx.player(owner)
	if player:
		ItemFx.apply(player, ItemFx.BRITTLE)
	if not Events.status_removed.is_connected(_on_status_gone):
		Events.status_removed.connect(_on_status_gone)
	if not Events.status_absorbed.is_connected(_on_status_gone):
		Events.status_absorbed.connect(_on_status_gone)
	if not Events.player_action_completed.is_connected(_on_player_action_completed):
		Events.player_action_completed.connect(_on_player_action_completed)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.status_removed.is_connected(_on_status_gone):
		Events.status_removed.disconnect(_on_status_gone)
	if Events.status_absorbed.is_connected(_on_status_gone):
		Events.status_absorbed.disconnect(_on_status_gone)
	if Events.player_action_completed.is_connected(_on_player_action_completed):
		Events.player_action_completed.disconnect(_on_player_action_completed)


## Brittle was consumed or negated by Ward: start the wait for the next one.
func _on_status_gone(owner: Node, status: Status) -> void:
	if owner is Player and status.id == "Brittle" and countdown < 0:
		countdown = recover_after


func _on_player_action_completed() -> void:
	if countdown < 0:
		return
	countdown -= 1
	if countdown > 0:
		return
	countdown = -1
	var player := ItemFx.player(relic_ui)
	if player:
		ItemFx.apply(player, ItemFx.BRITTLE)
		ItemFx.flash(relic_ui)
