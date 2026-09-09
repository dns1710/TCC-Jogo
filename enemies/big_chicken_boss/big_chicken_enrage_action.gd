extends EnemyAction

@export var enemy_threshold := 1
@export var enrage_art : Texture2D

const SPEED_STATUS = preload("res://statuses/status_speed_up.tres")

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
	var status_effect := StatusEffect.new()
	var speed := SPEED_STATUS.duplicate()
	speed.stacks = 5
	status_effect.status = speed
	status_effect.execute([enemy])
	
	already_used = true
	enemy.sprite_2d.texture = enrage_art
	SFXPlayer.play(sound)
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
