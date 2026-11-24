class_name ShatterglassHammer
extends Relic
## Every third attack Freezes the target. Hitting a Frozen target shatters it: +1d8 and Brittle.
## Targets that cannot be frozen (bosses, immunity window) get Brittle on the third attack instead.

@export var shatter_dice := 8

var attacks := 0
var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	attacks = 0


func on_attack_hit(targets: Array[Node]) -> void:
	attacks += 1
	var third := attacks % 3 == 0
	for target in targets:
		if not ItemFx.is_alive(target):
			continue
		if target.atb_mods.is_frozen():
			ItemFx.hit(target, Dice.roll(1, shatter_dice))
			ItemFx.apply(target, ItemFx.BRITTLE)
			ItemFx.flash(relic_ui)
		elif third:
			if target.atb_mods.can_freeze():
				ItemFx.apply(target, ItemFx.FREEZE)
			else:
				ItemFx.apply(target, ItemFx.BRITTLE)
			ItemFx.flash(relic_ui)
