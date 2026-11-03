class_name ThornsStatus
extends Status

func initialize_status(target: Node) -> void:
	if not Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.connect(_on_player_damaged)

func _on_player_damaged(attacker: Node, _damage: int) -> void:
	if not attacker:
		return
	
	if attacker is Enemy:
		var thorn_damage := stacks
		attacker.take_damage(thorn_damage, Modifier.Type.DMG_TAKEN)
