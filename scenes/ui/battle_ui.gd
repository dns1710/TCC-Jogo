class_name BattleUI 
extends CanvasLayer 

@export var char_stats: CharacterStats : set = _set_char_stats 
@export var attack_action: Action 
@export var block_action: Action 

@onready var mana_ui: ManaUI = $ManaUI 
@onready var attack_button: Button = %AttackButton 
@onready var block_button: Button = %BlockButton 
@onready var player = get_parent().get_node("Player") 
#@onready var enemy = get_parent().get_node("EnemyHandler").get_child(0) 

var pending_action: Action = null 

func _ready() -> void: 
	Events.enemy_selected.connect(_on_enemy_selected) 
	Events.player_turn_ended.connect(_on_player_turn_ended) 
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended) 
	attack_button.pressed.connect(_on_attack_button_pressed) 
	block_button.pressed.connect(_on_block_button_pressed) 

func _set_char_stats(value: CharacterStats) -> void: 
	char_stats = value 
	mana_ui.char_stats = char_stats 

func _on_attack_button_pressed() -> void: 
	pending_action = attack_action

func _on_enemy_selected(enemy: Node) -> void: 
	if pending_action == null: 
		return 
	pending_action.use_action([enemy], char_stats)
	pending_action = null 
	await get_tree().process_frame 
	await get_tree().process_frame 
	Events.player_turn_ended.emit() 

func _on_block_button_pressed() -> void: 
	block_action.use_action([player], char_stats)
	Events.player_turn_ended.emit() 

func _on_player_turn_ended() -> void: 
	attack_button.disabled = true 
	block_button.disabled = true 

func _on_enemy_turn_ended() -> void: 
	attack_button.disabled = false 
	block_button.disabled = false
