extends EnemyAction

@export var hp_treshold = 23
@export var block = 5
@export var prepare_art : Texture2D
	
func is_performable() -> bool:
	if not enemy:
		return false
	
	if not enemy.special_state == "AWAKE":
		return false
	
	return enemy.stats.health <= hp_treshold
	
func perform_action() -> void:
	if not enemy:
		return
	
	enemy.special_state = "PREPARE"
	enemy._spawn_popup("!!!", Color.RED)
	#enemy.sprite_2d.texture = prepare_art
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound = sound
	block_effect.execute([enemy])
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
