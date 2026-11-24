class_name IdleAction
extends EnemyAction
## Does nothing for a moment (a stationary enemy's filler action).

@export var popup_text := "..."
@export var duration := 0.8


func perform_action() -> void:
	if not enemy:
		return
	if popup_text != "":
		enemy._spawn_popup(popup_text, Color.GRAY)
	enemy.get_tree().create_timer(duration, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)
