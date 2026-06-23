extends EnemyAction

@export var wake_art : Texture2D

var already_used := false
	
func is_performable() -> bool:
	if not enemy:
		return false
		
	if already_used:
		return false
		
	if not enemy.special_state == "PREPARE":
		return false
	
	return true
	
func perform_action() -> void:
	if not enemy or not target:
		return
	
	var damage = randi_range((enemy.stats.attack-1)*2, (enemy.stats.attack+1)*2) + 4
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound = sound
	damage_effect.source = enemy
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	
	enemy.sprite_2d.texture = wake_art
	already_used = true
	
	tween.finished.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
