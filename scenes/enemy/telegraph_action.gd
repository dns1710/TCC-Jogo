class_name TelegraphAction
extends EnemyAction
## Prepare step of a telegraphed attack: shows a warning, optionally gains block, and
## makes the actor's next action the TelegraphedStrikeAction (via special_state).

const STATE := "PREPARE"

@export var warning_text := "!!!!"
@export var block := 0
@export var duration := 0.6
## Optional warning pose, restored by the strike.
@export var prepare_art: Texture2D
## When above 0 this is a CONDITIONAL action: usable from `min_phase` on, after this
## many ordinary actions since the last warning (0 = used as a weighted action).
@export var normal_actions_between := 0
@export var min_phase := 1

var _since := 999


func _ready() -> void:
	Events.enemy_action_completed.connect(_on_enemy_action_completed)


func is_performable() -> bool:
	if normal_actions_between <= 0 or not enemy:
		return false
	return enemy.phase >= min_phase and enemy.special_state != STATE and _since >= normal_actions_between


func perform_action() -> void:
	if not enemy:
		return
	enemy.special_state = STATE
	_since = -2 # the warning and its strike are not ordinary actions
	if prepare_art:
		enemy.sprite_2d.texture = prepare_art
	enemy._spawn_popup(warning_text, Color.RED)
	if block > 0:
		var block_effect := BlockEffect.new()
		block_effect.amount = block
		block_effect.sound = sound
		var targets: Array[Node] = [enemy]
		block_effect.execute(targets)
	enemy.get_tree().create_timer(duration, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)


func _on_enemy_action_completed(completed: Enemy) -> void:
	if completed == enemy:
		_since += 1
