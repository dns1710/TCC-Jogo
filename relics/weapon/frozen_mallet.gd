class_name FrozenMallet
extends Relic
## Every fourth attack Freezes the target. Hitting a Frozen target shatters the freeze: +1d8 and
## Brittle, and the Freeze ends (so each freeze shatters once).
## Targets that cannot be frozen (bosses, immunity window) get Brittle on the fourth attack instead.

@export var shatter_dice := 8
@export var attacks_per_freeze := 3

var attacks := 0
var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	attacks = 0


func on_attack_hit(targets: Array[Node]) -> void:
	attacks += 1
	var freeze_turn := attacks % attacks_per_freeze == 0
	for target in targets:
		if not ItemFx.is_alive(target):
			continue
		#if target.atb_mods.is_frozen():
		#	ItemFx.hit(target, Dice.roll(1, shatter_dice), null, shatter_dice)
		#	ItemFx.apply(target, ItemFx.BRITTLE)
		#	target.atb_mods.break_freeze()
		#	ItemFx.flash(relic_ui)
		if freeze_turn:
			if target.atb_mods.can_freeze():
				ItemFx.apply(target, ItemFx.FREEZE)
			#else:
				#ItemFx.apply(target, ItemFx.BRITTLE)
			ItemFx.flash(relic_ui)
