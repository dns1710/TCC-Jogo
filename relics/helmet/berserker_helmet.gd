class_name BerserkerHelmet
extends Relic

const ATTACK_UP_STATUS = preload("res://statuses/status_attack_up.tres")

var relic_ui: RelicUI

func activate_relic(_owner: RelicUI) -> void:
	relic_ui = _owner
	if not Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.connect(_on_player_damaged)

func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.disconnect(_on_player_damaged)

func _on_player_damaged(_attacker: Node, _damage: int) -> void:
	if not is_instance_valid(relic_ui):
		return
	
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player or player.stats.health <= 0:
		return
		
	var attack_up := StatusEffect.new()
	attack_up.status = ATTACK_UP_STATUS.duplicate()
	attack_up.execute([player])
	relic_ui.flash()
