class_name PineTarGloves
extends Relic
## Attacks against a Poisoned or Burning target deal 2 extra damage.

@export var bonus_damage := 2

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
		if ItemFx.is_alive(target) and (ItemFx.has_status(target, "Poison") or ItemFx.has_status(target, "Burn")):
			ItemFx.hit(target, bonus_damage)
			ItemFx.flash(relic_ui)
