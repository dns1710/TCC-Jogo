class_name Battle
extends Node2D 

@export var battle_stats: BattleStats 
@export var char_stats: CharacterStats
@export var music: AudioStream
@export var map_music: AudioStream
@export var relics: RelicHandler 
@onready var battle_ui: BattleUI = $BattleUI 
@onready var player_handler: PlayerHandler = $PlayerHandler 
@onready var enemy_handler: EnemyHandler = $EnemyHandler 
@onready var player: Player = $Player 
@onready var atb_manager: ATBManager = $ATBManager

func _ready() -> void: 
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed) 
	#Events.enemy_turn_ended.connect(_on_enemy_turn_ended) 
	#Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_atb_ready.connect(_on_player_atb_ready)
	Events.player_action_completed.connect(_on_player_action_completed)
	Events.player_died.connect(_on_player_died) 
	
func start_battle() -> void: 
	get_tree().paused = false 
	MusicPlayer.play(music, true) 
	battle_ui.char_stats = char_stats
	char_stats.reset_stats()
	player.stats = char_stats 
	player_handler.relics = relics 
	enemy_handler.setup_enemies(battle_stats) 
	#enemy_handler.reset_enemy_actions() 
	relics.relics_activated.connect(_on_relics_activated) 
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)
	atb_manager.start_battle(player,enemy_handler)

func _on_enemies_child_order_changed() -> void: 
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics): 
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT) 

func _on_player_atb_ready() -> void:
	player_handler.player_atb_ready()

func _on_player_action_completed() -> void:
	player_handler.player_action_finished()
	
func _on_player_died() -> void: 
	Events.battle_over_screen_requested.emit("Game Over!", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data() 

func _on_relics_activated(type: Relic.Type) -> void: 
	match type: 
		Relic.Type.START_OF_COMBAT: 
			player_handler.start_battle(char_stats) 
		Relic.Type.END_OF_COMBAT:
			char_stats.set_block(0)
			MusicPlayer.play(map_music, true)
			Score.add_room_clear()
			Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)
