class_name BreakerPick
extends Relic
## A hit that leaves the target with block applies Sunder, so the next hit ignores it.
## The hit's damage resolves a frame later, so the block is read after it.

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner


func on_attack_hit(targets: Array[Node]) -> void:
	if not is_instance_valid(relic_ui) or not relic_ui.is_inside_tree():
		return
	var tree := relic_ui.get_tree()
	for i in 3:
		await tree.process_frame
	for target in targets:
		if ItemFx.is_alive(target) and target.stats.block > 0:
			ItemFx.apply(target, ItemFx.SUNDER)
			ItemFx.flash(relic_ui)
