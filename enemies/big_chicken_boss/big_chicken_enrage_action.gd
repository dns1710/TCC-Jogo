extends EnemyAction

@export var speed_buff := 3
@export var enemy_threshold := 1
@export var enrage_art : Texture2D
var already_used := false
	
func is_performable() -> bool:
	if not enemy:
		return false
		
	if already_used:
		return false
	
	var enemy_handler = enemy.get_parent()	
	return enemy_handler.get_child_count() == enemy_threshold
	
func perform_action() -> void:
	if not enemy:
		return
	
	enemy._spawn_popup("SPEED UP", Color.DARK_ORANGE)
	enemy.stats.speed += speed_buff
	already_used = true
	enemy.sprite_2d.texture = enrage_art
	SFXPlayer.play(sound)
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
