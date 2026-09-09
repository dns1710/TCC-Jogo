class_name ThornRing
extends Relic

@export var thorn_damage := 1


func initialize_relic(_owner: RelicUI) -> void:
	if not Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.connect(_on_player_damaged)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.disconnect(_on_player_damaged)


func _on_player_damaged(attacker: Node, _damage: int) -> void:
	if not attacker:
		return

	if attacker is Enemy:
		attacker.take_damage(thorn_damage, Modifier.Type.DMG_TAKEN)
