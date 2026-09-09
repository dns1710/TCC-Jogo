class_name Smore
extends Relic

const ATTACK_STATUS = preload("res://statuses/status_attack_up.tres")
const ATTACK_BONUS := 2

var bonus_active := false
var player: Node


func initialize_relic(owner: RelicUI) -> void:
	player = owner.get_tree().get_first_node_in_group("player")

	if not player:
		return

	if not player.stats.stats_changed.is_connected(_on_stats_changed):
		player.stats.stats_changed.connect(_on_stats_changed)

	_check_health()


func deactivate_relic(owner: RelicUI) -> void:
	if not player:
		return

	if player.stats.stats_changed.is_connected(_on_stats_changed):
		player.stats.stats_changed.disconnect(_on_stats_changed)

	_remove_bonus()


func _on_stats_changed() -> void:
	_check_health()


func _check_health() -> void:
	if not player:
		return

	var half_hp = player.stats.max_health/2

	if player.stats.health <= half_hp:
		_add_bonus()
	else:
		_remove_bonus()


func _add_bonus() -> void:
	if bonus_active:
		return

	var attack := ATTACK_STATUS.duplicate()
	attack.stacks = ATTACK_BONUS

	var status_effect := StatusEffect.new()
	status_effect.status = attack
	status_effect.execute([player])

	bonus_active = true


func _remove_bonus() -> void:
	if not bonus_active:
		return

	var attack_up = player.status_handler._get_status("attack_up")

	if not attack_up:
		bonus_active = false
		return

	attack_up.stacks -= ATTACK_BONUS

	if attack_up.stacks <= 0:
		player.stats.attack = player.stats.max_attack
		player.status_handler._remove_status("attack_up")

	bonus_active = false
