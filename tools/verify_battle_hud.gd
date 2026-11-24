extends Node
## Headless check of the battle-hud spec: button states, armed-attack highlight and hint,
## right mouse button cancel, and that attack/block still work as before.
## Run: Godot --headless --path . res://tools/verify_battle_hud.tscn

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const RELICS_SCENE := preload("res://scenes/relic_handler/relic_handler.tscn")

var _errors: Array[String] = []
var _completed := 0


func _ready() -> void:
	await _run_checks()
	if _errors.is_empty():
		print("BATTLE HUD CHECK OK")
		get_tree().quit(0)
	else:
		print("BATTLE HUD CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


func _right_click() -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(100, 70)
	Input.parse_input_event(press)
	await _frames(2)


func _run_checks() -> void:
	TutorialManager.disable_auto_show()
	Events.player_action_completed.connect(func(): _completed += 1)

	var relics := RELICS_SCENE.instantiate()
	add_child(relics)
	var battle := BATTLE_SCENE.instantiate() as Battle
	add_child(battle)
	var stats: CharacterStats = load("res://characters/player/player.tres").duplicate()
	stats.max_health = 500
	battle.char_stats = stats
	relics.character_stats = stats
	battle.battle_stats = load("res://battles/map1/tier0/tier_0_zscout.tres")
	battle.relics = relics
	battle.start_battle()
	await _frames()
	battle.atb_manager.battle_running = false # no turn bars or enemy actions during the test
	var ui: BattleUI = battle.battle_ui
	var player: Player = battle.player
	var enemy: Enemy = battle.enemy_handler.get_child(0)

	# Names that other code and scenes rely on are unchanged.
	_expect(ui.get_node_or_null("%AttackButton") != null and ui.get_node_or_null("%BlockButton") != null, "button unique names must be unchanged")

	# Buttons look and act disabled when the player cannot act, enabled when it can.
	player.can_act = false
	await _frames()
	_expect(ui.attack_button.disabled and ui.block_button.disabled, "buttons must be disabled when the player cannot act")
	player.can_act = true
	await _frames()
	_expect(not ui.attack_button.disabled and not ui.block_button.disabled, "buttons must be enabled when the player can act")
	for state in ["normal", "hover", "pressed", "disabled"]:
		_expect(ui.attack_button.has_theme_stylebox_override(state) and ui.block_button.has_theme_stylebox_override(state), "buttons need their own %s look" % state)

	# Not armed: no highlight, no hint.
	_expect(not ui.armed_hint.visible, "no hint before arming")
	_expect(ui.attack_button.get_theme_stylebox("normal") != BattleUI.ARMED_STYLE, "no highlight before arming")

	# Armed, then used on an enemy: highlight and hint show, then clear; the attack lands.
	ui.attack_button.pressed.emit()
	await _frames()
	_expect(ui.pending_action != null, "ATTACK must arm the attack")
	_expect(ui.armed_hint.visible, "the hint must show while armed")
	_expect(ui.attack_button.get_theme_stylebox("normal") == BattleUI.ARMED_STYLE, "ATTACK must be highlighted while armed")
	var health_before: int = enemy.stats.health + enemy.stats.block
	Events.enemy_selected.emit(enemy)
	await get_tree().create_timer(1.5).timeout
	_expect(ui.pending_action == null, "the attack must be consumed by the target click")
	_expect(not ui.armed_hint.visible, "the hint must clear once used")
	_expect(ui.attack_button.get_theme_stylebox("normal") != BattleUI.ARMED_STYLE, "the highlight must clear once used")
	_expect(enemy.stats.health + enemy.stats.block < health_before, "the attack must still hit the enemy")
	_expect(_completed >= 1, "using the attack must still complete the player's action")

	# Block still works and clears an armed attack.
	player.can_act = true
	await _frames()
	var block_before: int = player.stats.block
	ui.attack_button.pressed.emit()
	await _frames()
	_expect(ui.armed_hint.visible, "armed again")
	ui.block_button.pressed.emit()
	await _frames()
	_expect(player.stats.block > block_before, "BLOCK must still add block")
	_expect(ui.pending_action == null and not ui.armed_hint.visible, "BLOCK must clear the armed attack and its hint")
	_expect(ui.attack_button.get_theme_stylebox("normal") != BattleUI.ARMED_STYLE, "BLOCK must clear the highlight")

	# Right mouse button cancels an armed attack and keeps the turn.
	player.can_act = true
	await _frames()
	var completed_before := _completed
	var enemy_health: int = enemy.stats.health
	ui.attack_button.pressed.emit()
	await _frames()
	_expect(ui.armed_hint.visible, "armed before the cancel")
	await _right_click()
	_expect(ui.pending_action == null, "right click must cancel the armed attack")
	_expect(not ui.armed_hint.visible, "right click must clear the hint")
	_expect(ui.attack_button.get_theme_stylebox("normal") != BattleUI.ARMED_STYLE, "right click must clear the highlight")
	_expect(player.can_act, "the player must keep their turn after cancelling")
	_expect(_completed == completed_before, "cancelling must not complete an action")
	_expect(enemy.stats.health == enemy_health, "cancelling must not hit anything")
	_expect(not ui.attack_button.disabled, "ATTACK must still be usable after cancelling")

	# A right click on an enemy while armed cancels instead of attacking.
	ui.attack_button.pressed.emit()
	await _frames()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	enemy._input_event(null, press, 0)
	_expect(ui.pending_action != null, "a right click delivered to an enemy must not use the attack")
	await _right_click()
	_expect(ui.pending_action == null, "and the right click still cancels")

	# Right click with nothing armed does nothing.
	var block_now: int = player.stats.block
	await _right_click()
	_expect(ui.pending_action == null and not ui.armed_hint.visible and player.can_act and player.stats.block == block_now, "right click with nothing armed must do nothing")
	_expect(_completed == completed_before, "no action may complete from a stray right click")

	battle.enemy_handler.child_order_changed.disconnect(battle._on_enemies_child_order_changed)
	battle.queue_free()
	relics.queue_free()
	await _frames()
