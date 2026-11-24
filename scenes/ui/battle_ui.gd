class_name BattleUI 
extends CanvasLayer 

@export var char_stats: CharacterStats : set = _set_char_stats 
@export var attack_action: Action 
@export var block_action: Action 

@onready var mana_ui: ManaUI = $ManaUI 
@onready var attack_button: Button = %AttackButton 
@onready var block_button: Button = %BlockButton 
@onready var armed_hint: Label = %ArmedHint
@onready var player = get_parent().get_node("Player")
@onready var atb_manager = get_parent().get_node("ATBManager")
var pending_action: Action = null
const CURSOR_ATTACK = preload("res://art/verdadeira arte/cursor_attack.png")
const CURSOR_DEFAULT = preload("res://art/verdadeira arte/cursor_pointer.png")
const ARMED_STYLE := preload("res://scenes/ui/hud_styles/button_armed.tres")
var _attack_normal_style: StyleBox
var _attack_hover_style: StyleBox

func _ready() -> void: 
	Events.enemy_selected.connect(_on_enemy_selected)
	attack_button.pressed.connect(_on_attack_button_pressed) 
	block_button.pressed.connect(_on_block_button_pressed) 
	_attack_normal_style = attack_button.get_theme_stylebox("normal")
	_attack_hover_style = attack_button.get_theme_stylebox("hover")

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	attack_button.disabled = not player.can_act
	block_button.disabled = not player.can_act
	
## Right mouse button cancels an armed attack (nothing is used, the turn is kept).
func _input(event: InputEvent) -> void:
	if pending_action != null and event.is_action_pressed("right_mouse"):
		pending_action = null
		Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW)
		_update_armed_visuals()
		get_viewport().set_input_as_handled()


## Presentation only: highlights ATTACK and shows the hint while an attack is armed.
func _update_armed_visuals() -> void:
	var armed := pending_action != null
	armed_hint.visible = armed
	attack_button.add_theme_stylebox_override("normal", ARMED_STYLE if armed else _attack_normal_style)
	attack_button.add_theme_stylebox_override("hover", ARMED_STYLE if armed else _attack_hover_style)


func _set_char_stats(value: CharacterStats) -> void: 
	char_stats = value

func _on_attack_button_pressed() -> void: 
	pending_action = attack_action
	Input.set_custom_mouse_cursor(CURSOR_ATTACK, Input.CURSOR_ARROW)
	_update_armed_visuals()

func _on_enemy_selected(enemy: Node) -> void:
	if pending_action == null:
		return
	pending_action.use_action([enemy], char_stats)
	pending_action = null
	Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW)
	_update_armed_visuals()

func _on_block_button_pressed() -> void:
	block_action.use_action([player], char_stats)
	pending_action = null
	Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW)
	_update_armed_visuals()
