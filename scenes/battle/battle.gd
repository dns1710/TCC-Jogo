class_name Battle
extends Node2D 

@export var battle_stats: BattleStats 
@export var char_stats: CharacterStats
## Set by the run from the current act; null keeps the forest background.
@export var battle_background: Texture2D
@export var music: AudioStream
@export var map_music: AudioStream
@export var relics: RelicHandler 
@onready var battle_ui: BattleUI = $BattleUI 
@onready var player_handler: PlayerHandler = $PlayerHandler 
@onready var enemy_handler: EnemyHandler = $EnemyHandler 
@onready var player: Player = $Player 
@onready var atb_manager: ATBManager = $ATBManager
@onready var background: Sprite2D = $Background

const SCREEN_SIZE := Vector2(256, 144)

const BATTLE_OVER_DELAY := 1.0
var player_lost := false
var panel_shown := false

func _ready() -> void: 
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.player_atb_ready.connect(_on_player_atb_ready)
	Events.player_action_completed.connect(_on_player_action_completed)
	Events.player_died.connect(_on_player_died) 
	
## Draws the act's background over the full screen; the forest stays when null.
func apply_background() -> void:
	if not battle_background:
		return
	background.texture = battle_background
	background.scale = SCREEN_SIZE / battle_background.get_size()


func start_battle() -> void:
	apply_background()
	Events.battle_start.emit()
	get_tree().paused = false 
	MusicPlayer.play(music, true) 
	battle_ui.char_stats = char_stats
	char_stats.reset_stats()
	player.stats = char_stats 
	player_handler.relics = relics 
	enemy_handler.setup_enemies(battle_stats)
	relics.relics_activated.connect(_on_relics_activated) 
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)
	relics.activate_relics_by_type(Relic.Type.EVENT_BASED)
	atb_manager.start_battle(player,enemy_handler)

func _on_enemies_child_order_changed() -> void: 
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics): 
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT) 

func _on_player_atb_ready() -> void:
	player_handler.player_atb_ready()

func _on_player_action_completed() -> void:
	player_handler.player_action_finished()
	
func _on_player_died() -> void:
	player_lost = true
	#Events.battle_over_screen_requested.emit("Game Over!", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data() 
	_show_battle_over("GAME OVER!", BattleOverPanel.Type.LOSE)
	
func _on_relics_activated(type: Relic.Type) -> void: 
	match type: 
		Relic.Type.START_OF_COMBAT: 
			player_handler.start_battle(char_stats) 
		Relic.Type.END_OF_COMBAT:
			char_stats.set_block(0)
			MusicPlayer.play(map_music, true)
			#Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)
			_show_battle_over("BATTLE WON!", BattleOverPanel.Type.WIN)
			
	
func _show_battle_over(text: String, type: BattleOverPanel.Type) -> void:
	atb_manager.battle_running = false
	if is_instance_valid(player):
		player.can_act = false
	
	await get_tree().create_timer(BATTLE_OVER_DELAY,false).timeout
	
	if not is_inside_tree():
		return
	
	if type == BattleOverPanel.Type.WIN and (player_lost or panel_shown):
		return
	
	panel_shown = true
	Events.battle_over_screen_requested.emit(text,type)
