class_name Rapier
extends Relic
## After you Block, your next attack deals an extra 1d6.

@export var bonus_dice := 6

var armed := false
var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	armed = false
	if not Events.action_used.is_connected(_on_action_used):
		Events.action_used.connect(_on_action_used)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.action_used.is_connected(_on_action_used):
		Events.action_used.disconnect(_on_action_used)
	armed = false


func _on_action_used(action: Action) -> void:
	if action.type == Action.Type.BLOCK:
		armed = true
		ItemFx.flash(relic_ui)


func get_weapon_bonus_damage() -> int:
	if not armed:
		return 0
	armed = false
	ItemFx.flash(relic_ui)
	return Dice.roll(1, bonus_dice)
