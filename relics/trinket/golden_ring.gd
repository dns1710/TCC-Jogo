class_name GoldenRing
extends Relic
## Start the combat with Ward.


func activate_relic(owner: RelicUI) -> void:
	var player := ItemFx.player(owner)
	if player:
		ItemFx.apply(player, ItemFx.WARD)
		ItemFx.flash(owner)
