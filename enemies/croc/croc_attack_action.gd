extends EnemyAction

@export var dice_value := 6
@export var dice_amount := 1
## Chance that a regular hit also grabs (adds Speed Down stacks) after the opening grab.
@export_range(0.0, 1.0) var grab_chance := 0.15
@export var grab_stacks := 1

const SPEED_DOWN_STATUS = preload("res://statuses/status_speed_down.tres")


func should_grab() -> bool:
	return RNG.instance.randf() < grab_chance


func perform_action() -> void:
	if not enemy or not target:
		return

	var damage = Dice.roll(dice_amount, dice_value, enemy.stats.attack)
	var grabs := should_grab()

	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.die_sides = dice_value
	damage_effect.sound = sound
	damage_effect.source = enemy

	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	if grabs:
		var status_effect := StatusEffect.new()
		var speed_down := SPEED_DOWN_STATUS.duplicate()
		speed_down.stacks = grab_stacks
		status_effect.status = speed_down
		tween.tween_callback(func():
			status_effect.execute([target])
		)
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)

	tween.finished.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
