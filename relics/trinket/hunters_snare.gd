class_name HuntersSnare
extends Relic
## Every enemy starts the combat with 2 Speed Down.

@export var stacks := 2


func activate_relic(owner: RelicUI) -> void:
	for enemy in ItemFx.enemies(owner):
		ItemFx.apply(enemy, ItemFx.SPEED_DOWN, stacks)
	ItemFx.flash(owner)
