class_name MirrorArmor
extends Relic
## Start with Ward. When Ward absorbs a debuff, that debuff is applied to every enemy instead
## (an enemy that cannot receive it, like a frozen-immune boss, refuses it as usual).
## Ward returns after 2 of your actions.

@export var regain_after := 2

var relic_ui: RelicUI
var countdown := -1


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	countdown = -1
	var player := ItemFx.player(owner)
	if player:
		ItemFx.apply(player, ItemFx.WARD)
	if not Events.status_absorbed.is_connected(_on_status_absorbed):
		Events.status_absorbed.connect(_on_status_absorbed)
	if not Events.player_action_completed.is_connected(_on_player_action_completed):
		Events.player_action_completed.connect(_on_player_action_completed)
	ItemFx.flash(owner)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.status_absorbed.is_connected(_on_status_absorbed):
		Events.status_absorbed.disconnect(_on_status_absorbed)
	if Events.player_action_completed.is_connected(_on_player_action_completed):
		Events.player_action_completed.disconnect(_on_player_action_completed)


func _on_status_absorbed(owner: Node, status: Status) -> void:
	if not owner is Player or not is_instance_valid(relic_ui):
		return
	for enemy in ItemFx.enemies(relic_ui):
		enemy.status_handler.add_status(status.duplicate())
	countdown = regain_after
	ItemFx.flash(relic_ui)


func _on_player_action_completed() -> void:
	if countdown < 0:
		return
	countdown -= 1
	if countdown > 0:
		return
	countdown = -1
	var player := ItemFx.player(relic_ui)
	if player and not ItemFx.has_status(player, "Ward"):
		ItemFx.apply(player, ItemFx.WARD)
		ItemFx.flash(relic_ui)
