class_name RimeBead
extends Relic
## Hitting an enemy that has Speed Down also makes it Brittle.

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.connect(_on_player_attacked)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.disconnect(_on_player_attacked)


func _on_player_attacked(targets: Array, _damage: int) -> void:
	for target in targets:
		if ItemFx.is_alive(target) and ItemFx.has_status(target, "SpeedDown"):
			ItemFx.apply(target, ItemFx.BRITTLE)
			ItemFx.flash(relic_ui)
