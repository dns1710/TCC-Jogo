class_name Smore
extends Relic

@export var stack_amount := 2

const ATTACK_UP_STATUS = preload("res://statuses/status_attack_up.tres")
var attack_up_active := false

func activate_relic(owner: RelicUI) -> void:
	attack_up_active = false
	
	if not Events.player_health_changed.is_connected(_on_player_health_changed):
		Events.player_health_changed.connect(_on_player_health_changed)

	var player := owner.get_tree().get_first_node_in_group("player") as Player

	if player:
		_on_player_health_changed(player)

func _on_player_health_changed(player: Player) -> void:
	var half_hp := player.stats.max_health / 2.0
	var low_hp := player.stats.health <= half_hp

	if low_hp and not attack_up_active:
		_apply_attack_up(player)

	elif not low_hp and attack_up_active:
		_remove_attack_up(player)


func _apply_attack_up(player: Player) -> void:
	attack_up_active = true

	var status_effect := StatusEffect.new()
	var attack_up := ATTACK_UP_STATUS.duplicate()

	attack_up.stacks = stack_amount

	status_effect.status = attack_up
	status_effect.execute([player])


func _remove_attack_up(player: Player) -> void:
	attack_up_active = false

	var status := player.status_handler._get_status("attackup")

	if status:
		player.stats.attack -= 3
		status.stacks -= 3

		if status.stacks <= 0:
			for status_ui in player.status_handler.get_children():
				if status_ui.status == status:
					status_ui.queue_free()
					break
