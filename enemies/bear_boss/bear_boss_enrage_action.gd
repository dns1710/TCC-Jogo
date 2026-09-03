extends EnemyAction

@export var hp_treshold = 23
@export var block = 6
@export var prepare_art : Texture2D
const ATTACK_STATUS = preload("res://statuses/status_attack_up.tres")
var already_used = false

func is_performable() -> bool:
	if not enemy:
		return false
	
	if already_used:
		return false
	
	if not enemy.special_state == "AWAKE":
		return false
	
	return enemy.stats.health <= hp_treshold
	
func perform_action() -> void:
	if not enemy:
		return
	
	enemy._spawn_popup("ATTACK UP", Color.CRIMSON)
	var status_effect := StatusEffect.new()
	var attack := ATTACK_STATUS.duplicate()
	attack.stacks = 4
	status_effect.status = attack
	status_effect.execute([enemy])
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])
	
	already_used = true
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
