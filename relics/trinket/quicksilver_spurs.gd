class_name QuicksilverSpurs
extends Relic
## Hitting a Slowed or Frozen enemy makes your next turn bar start at 25%.

@export var carry_over := 0.25

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.connect(_on_player_attacked)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.disconnect(_on_player_attacked)


func _on_player_attacked(targets: Array, _damage: int) -> void:
	var player := ItemFx.player(relic_ui)
	if player == null:
		return
	for target in targets:
		if ItemFx.is_alive(target) and (ItemFx.has_status(target, "SpeedDown") or target.atb_mods.is_frozen()):
			player.request_atb_start(carry_over)
			ItemFx.flash(relic_ui)
			return
