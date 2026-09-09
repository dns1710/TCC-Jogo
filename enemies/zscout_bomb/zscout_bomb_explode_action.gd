extends EnemyAction

func is_performable() -> bool:
	if not enemy:
		return false
		
	if not enemy.special_state == "PREPARE":
		return false
	
	return true
	
func perform_action() -> void:
	if not enemy or not target:
		return
	
	var damage = enemy.stats.attack + 7
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound = sound
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	
	tween.finished.connect(
		func():
			enemy._spawn_popup("BOOOMM!!", Color.BLUE_VIOLET)
			Events.enemy_action_completed.emit(enemy)
			enemy.queue_free()
	)
