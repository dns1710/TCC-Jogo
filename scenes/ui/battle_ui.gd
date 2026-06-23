class_name BattleUI 
extends CanvasLayer 

@export var char_stats: CharacterStats : set = _set_char_stats 
@export var attack_action: Action 
@export var block_action: Action 

@onready var mana_ui: ManaUI = $ManaUI 
@onready var attack_button: Button = %AttackButton 
@onready var block_button: Button = %BlockButton 
@onready var player = get_parent().get_node("Player")
@onready var atb_manager = get_parent().get_node("ATBManager")
var pending_action: Action = null
const CURSOR_ATTACK = preload("res://art/verdadeira arte/cursor_attack.png")
const CURSOR_DEFAULT = preload("res://art/verdadeira arte/cursor_pointer.png")

func _ready() -> void: 
	Events.enemy_selected.connect(_on_enemy_selected)
	attack_button.pressed.connect(_on_attack_button_pressed) 
	block_button.pressed.connect(_on_block_button_pressed) 

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	attack_button.disabled = not player.can_act
	block_button.disabled = not player.can_act
	
func _set_char_stats(value: CharacterStats) -> void: 
	char_stats = value

func _on_attack_button_pressed() -> void: 
	pending_action = attack_action
	Input.set_custom_mouse_cursor(CURSOR_ATTACK, Input.CURSOR_ARROW)

func _on_enemy_selected(enemy: Node) -> void:
	if pending_action == null:
		return
	pending_action.use_action([enemy], char_stats)
	pending_action = null
	Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW)

func _on_block_button_pressed() -> void:
	block_action.use_action([player], char_stats)
	pending_action = null
	Input.set_custom_mouse_cursor(CURSOR_DEFAULT, Input.CURSOR_ARROW)
