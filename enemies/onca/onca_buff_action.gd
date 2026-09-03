extends EnemyAction

const ATTACK_STATUS = preload("res://statuses/status_attack_up.tres")

func is_performable() -> bool:
	if not enemy:
		return false
	
	return enemy.special_state == "ATTACKED"
	
func perform_action() -> void:
	if not enemy:
		return
	
	enemy._spawn_popup("ATTACK UP", Color.CRIMSON)
	var status_effect := StatusEffect.new()
	var attack := ATTACK_STATUS.duplicate()
	status_effect.status = attack
	status_effect.execute([enemy])
	
	SFXPlayer.play(sound)
	
	enemy.special_state = ""
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
