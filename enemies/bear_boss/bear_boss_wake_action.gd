extends EnemyAction

@export var wake_art : Texture2D
var already_used := false
	
func is_performable() -> bool:
	if not enemy:
		return false
		
	if already_used:
		return false
	
	return true
	
func perform_action() -> void:
	if not enemy:
		return
		
	already_used = true
	enemy.special_state = "AWAKE"
	enemy._spawn_popup("!?", Color.DARK_GRAY)
	enemy.stats.set_block(0)
	enemy.sprite_2d.texture = wake_art
	SFXPlayer.play(sound)
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
