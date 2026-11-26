class_name FrostfirePike
extends Relic
## Hits alternate between 1 Scorch and 1 Speed Down. The hit that leaves a target holding both
## causes thermal shock: it becomes Brittle and Sundered. The shock fires once, and can fire again
## only after Scorch or Speed Down has worn off the target.

@export var stacks := 1

var hits := 0
var relic_ui: RelicUI
var _shocked: Array[Node] = []


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	hits = 0
	_shocked.clear()


func on_attack_hit(targets: Array[Node]) -> void:
	var fire_turn := hits % 2 == 0
	hits += 1
	_shocked = _shocked.filter(func(t): return is_instance_valid(t))
	for target in targets:
		if not ItemFx.is_alive(target):
			continue
		if not _holds_both(target):
			_shocked.erase(target)
		ItemFx.apply(target, ItemFx.SCORCH if fire_turn else ItemFx.SLOWNESS, stacks)
		if _holds_both(target) and not _shocked.has(target):
			_shocked.append(target)
			ItemFx.apply(target, ItemFx.BRITTLE)
			ItemFx.apply(target, ItemFx.SUNDER)
		ItemFx.flash(relic_ui)


func _holds_both(target: Node) -> bool:
	return ItemFx.has_status(target, "Scorch") and ItemFx.has_status(target, "Slowness")
