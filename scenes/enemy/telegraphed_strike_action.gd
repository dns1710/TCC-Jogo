class_name TelegraphedStrikeAction
extends EnemyAction
## Heavy hit that is only available right after a TelegraphAction, and takes priority
## over ordinary actions (set type to CONDITIONAL in the AI scene). Optionally applies
## a status to the target.

@export var dice_value := 8
@export var dice_amount := 2
@export var status: Status


func is_performable() -> bool:
	return enemy != null and enemy.special_state == TelegraphAction.STATE


func perform_action() -> void:
	if not enemy or not target:
		return
	enemy.special_state = ""
	var damage := Dice.roll(dice_amount, dice_value, enemy.stats.attack)
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.sound = sound
	damage_effect.source = enemy
	var targets: Array[Node] = [target]

	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(targets))
	if status:
		tween.tween_callback(func():
			var status_effect := StatusEffect.new()
			status_effect.status = status
			status_effect.execute(targets)
		)
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	tween.finished.connect(func(): Events.enemy_action_completed.emit(enemy))
