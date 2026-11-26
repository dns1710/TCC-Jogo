class_name WinterCap
extends Relic
## The player is immune to Speed Down for the whole combat.


func activate_relic(owner: RelicUI) -> void:
	var player := ItemFx.player(owner)
	if player:
		player.slow_immune = true
		ItemFx.flash(owner)
