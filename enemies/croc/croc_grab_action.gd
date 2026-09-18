extends EnemyAction

@export var dice_value := 4
@export var dice_amount := 1

const SPEED_DOWN_STATUS = preload("res://statuses/status_speed_down.tres")
var already_used = false

func is_performable() -> bool:
	return already_used == false

func perform_action() -> void:
	if not enemy or not target:
		return
	
	var damage = Dice.roll(dice_amount, dice_value, enemy.stats.attack)
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound = sound
	damage_effect.source = enemy
	
	var status_effect := StatusEffect.new()
	var speed_down := SPEED_DOWN_STATUS.duplicate()
	status_effect.status = speed_down
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_callback(func():
		status_effect.execute([target])
	)
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	
	already_used = true
	
	tween.finished.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
