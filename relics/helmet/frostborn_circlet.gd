class_name FrostbornCirclet
extends Relic
## When Freeze ends on you, gain 1 Attack Up for the rest of the combat.

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	var player := ItemFx.player(owner)
	if player and not player.atb_mods.freeze_ended.is_connected(_on_thaw):
		player.atb_mods.freeze_ended.connect(_on_thaw)


func _on_thaw() -> void:
	var player := ItemFx.player(relic_ui)
	if player:
		ItemFx.apply(player, ItemFx.ATTACK_UP, 1)
		ItemFx.flash(relic_ui)
