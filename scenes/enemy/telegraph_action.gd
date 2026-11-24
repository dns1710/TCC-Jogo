class_name TelegraphAction
extends EnemyAction
## Prepare step of a telegraphed attack: shows a warning, optionally gains block, and
## makes the actor's next action the TelegraphedStrikeAction (via special_state).

const STATE := "PREPARE"

@export var warning_text := "!!!!"
@export var block := 0
@export var duration := 0.6


func perform_action() -> void:
	if not enemy:
		return
	enemy.special_state = STATE
	enemy._spawn_popup(warning_text, Color.RED)
	if block > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = block
		block_effect.sound = sound
		block_effect.execute([enemy])
	enemy.get_tree().create_timer(duration, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)
