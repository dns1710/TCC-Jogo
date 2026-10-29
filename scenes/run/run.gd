class_name Run
extends Node

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const BATTLE_REWARD_SCENE := preload("res://scenes/battle_reward/battle_reward.tscn")
const CAMPFIRE_SCENE := preload("res://scenes/campfire/campfire.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop.tscn")
const TREASURE_SCENE := preload("res://scenes/treasure/treasure.tscn")
const WIN_SCREEN_SCENE := preload("res://scenes/win_screen/win_screen.tscn")
const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"

@export var run_startup: RunStartup
@export var music: AudioStream
@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var health_ui: HealthUI = %HealthUI
@onready var gold_ui: GoldUI = %GoldUI
@onready var relic_handler: RelicHandler = %RelicHandler
@onready var relic_tooltip: RelicTooltip = %RelicTooltip
@onready var pause_menu: PauseMenu = $PauseMenu

@onready var battle_button: Button = %BattleButton
@onready var campfire_button: Button = %CampfireButton
@onready var map_button: Button = %MapButton
@onready var rewards_button: Button = %RewardsButton
@onready var shop_button: Button = %ShopButton
@onready var treasure_button: Button = %TreasureButton

var stats: RunStats
var character: CharacterStats
var save_data: SaveGame
var dda := DDA.new()

var shop_entered_items: int
var dda_shop_changed := false
var dda_treasure_spawned := false
var dda_treasure_pending := false

func _ready() -> void:
	if not run_startup:
		return
		
	MusicPlayer.play(music, true)
	
	_connect_ui_signals()
	_connect_global_signals()

	pause_menu.save_and_quit.connect(_go_to_main_menu)

	match run_startup.type:
		RunStartup.Type.NEW_RUN:
			_start_new_run()
		RunStartup.Type.CONTINUED_RUN:
			_load_run()

func _start_new_run() -> void:
	stats = RunStats.new()
	character = run_startup.picked_character.create_instance()

	relic_handler.run_stats = stats
	relic_handler.character_stats = character

	map.run_stats = stats
	
	_setup_top_bar()

	map.generate_new_map()
	map.unlock_floor(0)
	map.show_map()
	
	save_data = SaveGame.new()
	_save_run(true)

func _save_run(was_on_map: bool) -> void:
	save_data.run_stats = stats
	save_data.char_stats = character
	save_data.relics = relic_handler.get_all_relics()
	save_data.last_room = map.last_room
	save_data.map_data = map.map_data.duplicate()
	save_data.floors_climbed = map.floors_climbed
	save_data.was_on_map = was_on_map
	
	save_data.rng_seed = RNG.instance.seed
	save_data.rng_state = RNG.instance.state
	
	save_data.save_data()

func _load_run() -> void:
	save_data = SaveGame.load_data()
	
	RNG.set_from_save_data(save_data.rng_seed, save_data.rng_state)
	stats = save_data.run_stats
	character = save_data.char_stats
	map.run_stats = stats
	relic_handler.add_relics(save_data.relics)
	relic_handler.run_stats = stats
	relic_handler.character_stats = character
	_setup_top_bar()
	
	map.load_map(save_data.map_data, save_data.floors_climbed, save_data.last_room)
	if save_data.was_on_map:
		map.show_map()
	elif save_data.last_room:
		_on_map_exited(save_data.last_room)
	
func _setup_top_bar() -> void:
	_connect_character_signals()
	health_ui.update_stats(character)
	gold_ui.run_stats = stats


func _connect_ui_signals() -> void:
	_safe_connect(battle_button.pressed, func(): _change_view(BATTLE_SCENE))
	_safe_connect(campfire_button.pressed, func(): _change_view(CAMPFIRE_SCENE))
	_safe_connect(map_button.pressed, _show_map)
	_safe_connect(rewards_button.pressed, func(): _change_view(BATTLE_REWARD_SCENE))
	_safe_connect(shop_button.pressed, func(): _change_view(SHOP_SCENE))
	_safe_connect(treasure_button.pressed, func(): _change_view(TREASURE_SCENE))


func _connect_global_signals() -> void:
	_safe_connect(Events.battle_won, _on_battle_won)
	_safe_connect(Events.battle_reward_exited, _show_map)
	_safe_connect(Events.campfire_exited, _on_campfire_exited)
	_safe_connect(Events.map_exited, _on_map_exited)
	_safe_connect(Events.shop_exited, _on_shop_exited)
	_safe_connect(Events.treasure_room_exited, _on_treasure_room_exited)
	_safe_connect(Events.event_room_exited, _show_map)
	_safe_connect(Events.relic_tooltip_requested, relic_tooltip.show_tooltip)


func _connect_character_signals() -> void:
	if character:
		_safe_connect(character.stats_changed, func(): health_ui.update_stats(character))


func _safe_connect(signal_ref: Signal, callable: Callable) -> void:
	if not signal_ref.is_connected(callable):
		signal_ref.connect(callable)


func _change_view(scene: PackedScene) -> Node:
	for child in current_view.get_children():
		child.queue_free()

	get_tree().paused = false

	var new_view := scene.instantiate()
	current_view.add_child(new_view)

	map.hide_map()
	return new_view


func _show_map() -> void:
	if dda_treasure_pending:
		var score: int = stats.dda_score
		var relic_count: int = relic_handler.get_all_relics().size()
		var hp_percentage: float = (float(character.health)/float(character.max_health) if character.max_health > 0 else 0.0)
		
		if !dda_shop_changed and score >= 55 and relic_count > shop_entered_items and relic_count >= 4:
			map.change_room(Room.Type.SHOP, Room.Type.MONSTER)
			dda_shop_changed = true
		elif score >= 70:
			if hp_percentage > 0.5:
				map.change_room(Room.Type.CAMPFIRE, Room.Type.MONSTER)
			else:
				map.change_room(Room.Type.EVENT, Room.Type.MONSTER)
			
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	map.show_map()
	map.unlock_next_rooms()
	
	_save_run(true)


func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _show_regular_battle_rewards() -> void:
	var reward := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward.run_stats = stats
	reward.character_stats = character
	reward.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())

func _on_battle_room_entered(room: Room) -> void:
	var battle := _change_view(BATTLE_SCENE) as Battle
	battle.char_stats = character
	battle.battle_stats = room.battle_stats
	battle.relics = relic_handler
	battle.start_battle()

func _on_treasure_room_entered() -> void:
	var treasure := _change_view(TREASURE_SCENE) as Treasure
	treasure.relic_handler = relic_handler
	treasure.char_stats = character
	treasure.generate_relic()
	shop_entered_items = relic_handler.get_all_relics().size()

func _on_treasure_room_exited(relic: Relic) -> void:
	var reward := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	var gold_reward_min = 40
	var gold_reward_max = 50
	reward.run_stats = stats
	reward.character_stats = character
	reward.relic_handler = relic_handler
	reward.add_gold_reward(RNG.pick_random(gold_reward_min,gold_reward_max))
	reward.add_relic_reward(relic)
	dda_treasure_pending = true

func _on_campfire_entered() -> void:
	var campfire := _change_view(CAMPFIRE_SCENE) as Campfire
	campfire.char_stats = character

func _on_campfire_exited() -> void:
	dda.update_score_campfire(character.health, character.max_health,stats)
	var score: int = stats.dda_score
	var hp_percentage: float = (float(character.health)/float(character.max_health) if character.max_health > 0 else 0.0)
	
	#SCORE ALTO: Se hp está alto, troca cura por combate. Se hp está baixo, troca evento por combate
	if score >= 70:
		if hp_percentage >= 0.5:
			map.change_room(Room.Type.CAMPFIRE, Room.Type.MONSTER)
		else:
			map.change_room(Room.Type.EVENT, Room.Type.MONSTER)
	
	#SCORE BAIXO: Se hp está alto, troca evento por cura. Se hp estiver baixo, troca combate por cura
	if score <= 30:
		if hp_percentage >= 0.5:
			map.change_room(Room.Type.EVENT, Room.Type.CAMPFIRE)
		else:
			map.change_room(Room.Type.MONSTER, Room.Type.CAMPFIRE)
		
	_show_map()

func _on_shop_entered() -> void:
	shop_entered_items = relic_handler.get_all_relics().size()
	print("ITENS ATUAIS: ", shop_entered_items)
	
	var shop := _change_view(SHOP_SCENE) as Shop
	shop.char_stats = character
	shop.run_stats = stats
	shop.relic_handler = relic_handler
	Events.shop_entered.emit(shop)
	shop.populate_shop()
	
func _on_shop_exited() -> void:
	_show_map()
	
	var score: int = stats.dda_score
	var relic_count: int = relic_handler.get_all_relics().size()
	
	#SE COMPRA TODOS OS ITENS DA LOJA E POSSUI +4 ITENS: Troca shop por combate
	if !dda_shop_changed and score >= 55 and relic_count == (shop_entered_items+3) and relic_count >= 4:
		map.change_room(Room.Type.SHOP, Room.Type.MONSTER)
		dda_shop_changed = true
	
	#SE NÃO COMPRAR NENHUM ITEM DA LOJA POR FALTA DE DINHEIRO
	if !dda_shop_changed and relic_count == shop_entered_items and stats.gold < 90:
		#SCORE MUITO BAIXO: Muda combate para um tesouro
		if score <= 15:
			map.change_room(Room.Type.MONSTER, Room.Type.TREASURE)
		#SCORE BAIXO: Muda evento para um tesouro
		elif score <= 35:
			map.change_room(Room.Type.EVENT, Room.Type.TREASURE)
		dda_treasure_spawned = true
		dda_shop_changed = true

func _on_event_room_entered(room: Room) -> void:
	var event_room := _change_view(room.event_scene) as EventRoom
	event_room.character_stats = character
	event_room.run_stats = stats
	event_room.setup()

func _on_battle_won() -> void:
	dda.update_score_battle(character.health, character.max_health,stats)
	
	var hp_percentage: float = (float(character.health)/float(character.max_health) if character.max_health > 0 else 0.0)
	var score: int = stats.dda_score
	
	#SCORE ALTO: Se tiver muitos itens, torca shop por combate. Se hp estiver alto, troca cura por combate. Se hp estiver baixo, troca evento por combate
	if score >= 65:
		var relic_count: int = relic_handler.get_all_relics().size()
		
		if relic_count >= 4 and dda_shop_changed == false:
			map.change_room(Room.Type.SHOP, Room.Type.MONSTER)
			dda_shop_changed = true
		elif hp_percentage >= 0.5:
			map.change_room(Room.Type.CAMPFIRE, Room.Type.MONSTER)
		elif hp_percentage < 0.5:
			map.change_room(Room.Type.EVENT, Room.Type.MONSTER)
	
	#SCORE BAIXO: Se gold e hp estiverem altos, troca combate por shop. Caso contrário, troca combate por cura
	if score <= 35:
		if stats.gold >= 150 and hp_percentage > 0.5:
			map.change_room(Room.Type.MONSTER, Room.Type.SHOP)
		else:
			map.change_room(Room.Type.MONSTER, Room.Type.CAMPFIRE)
		
	if map.floors_climbed == MapGenerator.FLOORS:
		var win_screen := _change_view(WIN_SCREEN_SCENE) as WinScreen
		win_screen.character = character
	else:
		_show_regular_battle_rewards()

func _on_map_exited(room: Room) -> void:
	_save_run(false)
	
	match room.type:
		Room.Type.MONSTER, Room.Type.BOSS:
			_on_battle_room_entered(room)
		Room.Type.TREASURE:
			_on_treasure_room_entered()
		Room.Type.CAMPFIRE:
			_on_campfire_entered()
		Room.Type.SHOP:
			_on_shop_entered()
		Room.Type.EVENT:
			_on_event_room_entered(room)
