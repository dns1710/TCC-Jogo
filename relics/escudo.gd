class_name ShieldRelic
extends Relic

@export var block_bonus := 2

var applied := false


func initialize_relic(owner: RelicUI) -> void:
	Events.battle_won.connect(_on_battle_ended)
	Events.player_died.connect(_on_battle_ended)


func activate_relic(owner: RelicUI) -> void:
	if applied:
		return

	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player.stats.block += block_bonus
		owner.flash()
		applied = true


func deactivate_relic(owner: RelicUI) -> void:
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player.stats.block -= block_bonus


func _on_battle_ended(_arg = null) -> void:
	applied = false
