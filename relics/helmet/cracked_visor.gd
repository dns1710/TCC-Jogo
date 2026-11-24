class_name CrackedVisor
extends Relic
## While you are Brittle, your attacks deal an extra 1d8.

@export var bonus_dice := 8

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
	if player == null or not ItemFx.has_status(player, "Brittle"):
		return
	for target in targets:
		ItemFx.hit(target, Dice.roll(1, bonus_dice))
	ItemFx.flash(relic_ui)
