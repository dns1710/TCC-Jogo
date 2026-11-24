class_name FrostfirePike
extends Relic
## Hits alternate between 2 Scorch and 2 Speed Down. A target holding both suffers thermal
## shock: it becomes Brittle and Sundered.

@export var stacks := 2

var hits := 0
var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	hits = 0


func on_attack_hit(targets: Array[Node]) -> void:
	var fire_turn := hits % 2 == 0
	hits += 1
	for target in targets:
		if not ItemFx.is_alive(target):
			continue
		ItemFx.apply(target, ItemFx.SCORCH if fire_turn else ItemFx.SPEED_DOWN, stacks)
		if ItemFx.has_status(target, "Scorch") and ItemFx.has_status(target, "SpeedDown"):
			ItemFx.apply(target, ItemFx.BRITTLE)
			ItemFx.apply(target, ItemFx.SUNDER)
		ItemFx.flash(relic_ui)
