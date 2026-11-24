class_name Cinderbrand
extends Relic
## Each hit adds 1 Scorch. Hitting a target that already holds 3 or more stacks detonates
## them for stacks x 3 damage and clears the Scorch.

@export var detonate_at := 3
@export var damage_per_stack := 3

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner


func on_attack_hit(targets: Array[Node]) -> void:
	for target in targets:
		if not ItemFx.is_alive(target):
			continue
		var scorch := ItemFx.get_status(target, "Scorch")
		if scorch and scorch.stacks >= detonate_at:
			var stacks := scorch.stacks
			target.status_handler.remove_status("Scorch")
			ItemFx.hit(target, stacks * damage_per_stack)
		else:
			ItemFx.apply(target, ItemFx.SCORCH, 1)
		ItemFx.flash(relic_ui)
