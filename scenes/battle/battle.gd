class_name Battle
extends Node2D 

@export var battle_stats: BattleStats 
@export var char_stats: CharacterStats 
@export var music: AudioStream 
@export var relics: RelicHandler 
@onready var battle_ui: BattleUI = $BattleUI 
@onready var player_handler: PlayerHandler = $PlayerHandler 
@onready var enemy_handler: EnemyHandler = $EnemyHandler 
@onready var player: Player = $Player 

func _ready() -> void: 
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed) 
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended) 
	Events.player_turn_ended.connect(player_handler.end_turn) 
	Events.player_died.connect(_on_player_died) 
	
func start_battle() -> void:
	get_tree().paused = false
	MusicPlayer.play(music, true)

	print("=== START BATTLE ===")

	battle_ui.char_stats = char_stats
	player.stats = char_stats
	player_handler.relics = relics

	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()

	# 🔥 IMPORTANTE: garantir estado limpo antes de ativar relíquias
	char_stats.block = 0

	# 🔥 debug pra ver se está duplicando
	print("BLOCK ANTES RELIC:", char_stats.block)

	relics.relics_activated.connect(_on_relics_activated)

	# 💥 aqui é o ponto correto do START_OF_COMBAT
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)

	print("BLOCK DEPOIS RELIC:", char_stats.block)

func _on_enemies_child_order_changed() -> void: 
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics): 
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT) 

func _on_enemy_turn_ended() -> void: 
	player_handler.start_turn() 
	enemy_handler.reset_enemy_actions() 

func _on_player_died() -> void: 
	Events.battle_over_screen_requested.emit("Game Over!", BattleOverPanel.Type.LOSE) 
	SaveGame.delete_data() 

func _on_relics_activated(type: Relic.Type) -> void: 
	match type: 
		Relic.Type.START_OF_COMBAT: 
			player_handler.start_battle(char_stats) 
		Relic.Type.END_OF_COMBAT: Events.battle_over_screen_requested.emit("Victorious!", BattleOverPanel.Type.WIN)
