class_name Run
extends Node

const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const BATTLE_REWARD_SCENE := preload("res://scenes/battle_reward/battle_reward.tscn")
const CAMPFIRE_SCENE := preload("res://scenes/campfire/campfire.tscn")
const SHOP_SCENE := preload("res://scenes/shop/shop.tscn")
const TREASURE_SCENE := preload("res://scenes/treasure/treasure.tscn")
const WIN_SCREEN_SCENE := preload("res://scenes/win_screen/win_screen.tscn")
const CHOICE_EVENT_SCENE := preload("res://scenes/event_rooms/choice_event.tscn")
const ACT_TRANSITION_SCENE := preload("res://scenes/act_transition/act_transition.tscn")
const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const ACTS := [
	preload("res://acts/act_1_forest.tres"),
	preload("res://acts/act_2_ice.tres"),
	preload("res://acts/act_3_fire.tres"),
]

@export var run_startup: RunStartup
@export var music: AudioStream
@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var health_ui: HealthUI = %HealthUI
@onready var gold_ui: GoldUI = %GoldUI
@onready var relic_handler: RelicHandler = %RelicHandler
@onready var relic_tooltip: RelicTooltip = %RelicTooltip
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var inventory_button: Button = %InventoryButton
@onready var inventory: Inventory = $InventoryLayer/Inventory

@onready var battle_button: Button = %BattleButton
@onready var campfire_button: Button = %CampfireButton
@onready var map_button: Button = %MapButton
@onready var rewards_button: Button = %RewardsButton
@onready var shop_button: Button = %ShopButton
@onready var treasure_button: Button = %TreasureButton

@export var battle_relic_pool: Array[Relic]

var stats: RunStats
var character: CharacterStats
var save_data: SaveGame
var dda := DDA.new()
var act_index := 0

#var inventory_open := false

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
	
	var starter_relic := preload("res://relics/armor/slow.tres")
	relic_handler.add_relic(starter_relic,false)
	relic_handler.equip_relic(starter_relic)
	
	map.run_stats = stats
	
	_setup_top_bar()

	act_index = 0
	map.set_act(ACTS[act_index])
	map.generate_new_map()
	map.unlock_floor(0)
	map.show_map()
	
	save_data = SaveGame.new()
	_save_run(true)

func _save_run(was_on_map: bool) -> void:
	save_data.run_stats = stats
	
	var saved_character: CharacterStats = character.duplicate(true)
	
	for relic: Relic in relic_handler.get_equipped_relics():
		saved_character.max_block -= relic.bonus_blk
		saved_character.max_attack -= relic.bonus_atk
		saved_character.max_speed -= relic.bonus_spd
	
	save_data.char_stats = saved_character
	
	save_data.relics = relic_handler.get_all_relics()
	save_data.equipped_weapon_id = relic_handler.equipped_weapon.id if relic_handler.equipped_weapon else ""
	save_data.equipped_helmet_id = relic_handler.equipped_helmet.id if relic_handler.equipped_helmet else ""
	save_data.equipped_armor_id = relic_handler.equipped_armor.id if relic_handler.equipped_armor else ""
	save_data.equipped_trinket_1_id = relic_handler.equipped_trinkets[0].id if relic_handler.equipped_trinkets[0] else ""
	save_data.equipped_trinket_2_id = relic_handler.equipped_trinkets[1].id if relic_handler.equipped_trinkets[1] else ""
	
	save_data.dda_shop_changed = dda_shop_changed
	save_data.dda_treasure_spawned = dda_treasure_spawned
	save_data.dda_treasure_pending = dda_treasure_pending
	save_data.shop_entered_items = shop_entered_items
	
	save_data.act_index = act_index
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
	
	relic_handler.run_stats = stats
	relic_handler.character_stats = character
	
	relic_handler.add_relics(save_data.relics, false)
	
	relic_handler.restore_equipment(
		save_data.equipped_weapon_id,
		save_data.equipped_helmet_id,
		save_data.equipped_armor_id,
		save_data.equipped_trinket_1_id,
		save_data.equipped_trinket_2_id
	)
	#relic_handler.add_relics(save_data.relics)
	#relic_handler.run_stats = stats
	#relic_handler.character_stats = character
	_setup_top_bar()
	
	act_index = clampi(save_data.act_index, 0, ACTS.size() - 1)
	map.set_act(ACTS[act_index])
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
	_safe_connect(inventory_button.pressed, _on_inventory_button_pressed)
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
	_safe_connect(Events.act_transition_finished, _start_next_act)
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


func _start_next_act() -> void:
	act_index = mini(act_index + 1, ACTS.size() - 1)
	character.heal(character.max_health)
	stats.seen_events.clear()

	for child in current_view.get_children():
		child.queue_free()

	map.set_act(ACTS[act_index])
	map.generate_new_map()
	map.unlock_floor(0)
	map.show_map()

	_save_run(true)


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
		dda_treasure_pending = false
			
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	map.show_map()
	map.unlock_next_rooms()
	
	_save_run(true)


func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_inventory_button_pressed() -> void:
	if inventory.visible:
		inventory.close_inventory()
	else:
		inventory.open_inventory(relic_handler)

func _show_regular_battle_rewards() -> void:
	var reward := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward.run_stats = stats
	reward.character_stats = character
	reward.relic_handler = relic_handler
	reward.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())
	
	#var relic_reward := _get_random_relic_reward()
	var tier := map.last_room.battle_stats.battle_tier
	var relic_reward := _get_random_relic_reward(-1, false, _get_battle_reward_weights(tier))
	if relic_reward:
		reward.add_relic_reward(relic_reward)


func _show_first_battle_reward()-> void:
	var reward := _change_view(BATTLE_REWARD_SCENE) as BattleReward
	reward.run_stats = stats
	reward.character_stats = character
	reward.relic_handler = relic_handler
	reward.add_gold_reward(map.last_room.battle_stats.roll_gold_reward())

	# Arma: 65% comum, 35% incomum
	var weapon_reward := _get_random_relic_reward(Relic.Equip.WEAPON, false, {Relic.Rarity.COMMON: 65, Relic.Rarity.UNCOMMON: 35})

	# Outro equipamento: 100% comum, excluindo armas
	var secondary_reward := _get_random_relic_reward(-1, true, {Relic.Rarity.COMMON: 100})

	if weapon_reward:
		reward.add_relic_reward(weapon_reward)

	if secondary_reward:
		reward.add_relic_reward(secondary_reward)

func _get_random_relic_reward(
	required_equip: int = -1,
	exclude_weapon: bool = false,
	rarity_weights: Dictionary = {}) -> Relic:
	if rarity_weights.is_empty():
		rarity_weights = _get_battle_reward_weights(1)
		#rarity_weights = {
		#	Relic.Rarity.COMMON:50,
		#	Relic.Rarity.UNCOMMON: 35,
		#	Relic.Rarity.RARE: 15
		#}
	var available_relics: Dictionary = {
		Relic.Rarity.COMMON: [],
		Relic.Rarity.UNCOMMON: [],
		Relic.Rarity.RARE: [],
		Relic.Rarity.MYTHIC: []
	}
	
	for relic: Relic in battle_relic_pool:
		if relic == null:
			continue
		if not relic.can_appear_as_reward(character):
			continue
		if relic_handler.has_relic(relic.id):
			continue
		if required_equip != -1 and relic.equip != required_equip:
			continue
		if exclude_weapon and relic.equip == Relic.Equip.WEAPON:
			continue
		available_relics[relic.rarity].append(relic)
	
	var total_weight := 0
	var available_rarities: Array[int] = []
	
	for rarity: int in rarity_weights:
		if not available_relics[rarity].is_empty():
			available_rarities.append(rarity)
			total_weight += rarity_weights[rarity]
	
	if available_rarities.is_empty():
		return null
	
	var roll := RNG.pick_random(1,total_weight)
	
	for rarity: int in available_rarities:
		roll -= rarity_weights[rarity]
		if roll <= 0:
			return RNG.array_pick_random(available_relics[rarity])
	
	return null
	

func _get_battle_reward_weights(tier: int) -> Dictionary:
	if tier == 2:
		return {
			Relic.Rarity.UNCOMMON: 55,
			Relic.Rarity.RARE: 35,
			Relic.Rarity.MYTHIC: 10
		}
	return {
		Relic.Rarity.COMMON: 50,
		Relic.Rarity.UNCOMMON: 35,
		Relic.Rarity.RARE: 15
	}
	
	
func _on_battle_room_entered(room: Room) -> void:
	var battle := _change_view(BATTLE_SCENE) as Battle
	battle.char_stats = character
	battle.battle_stats = room.battle_stats
	battle.relics = relic_handler
	battle.start_battle()
	

func _prepare_battle(room:Room) -> void:
	if room.type != Room.Type.MONSTER or not room.battle_stats:
		return
	
	if room.battle_stats.battle_tier != 1:
		return
	
	if stats.dda_score >= 75:
		var tier_2 := map.get_battle_pool().get_random_battle_for_tier(2)
		if tier_2:
			room.battle_stats = tier_2

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
	
	#SE COMPRA TODOS OS ITENS DA LOJA E POSSUI 6+ ITENS: Troca shop por combate
	if !dda_shop_changed and score >= 55 and relic_count == (shop_entered_items+3) and relic_count >= 6:
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

func _on_event_room_entered(_room: Room) -> void:
	var pool := map.get_event_pool()
	var definition := pool.pick(stats.seen_events) if pool else null
	if definition == null:
		push_warning("No event available; skipping the room.")
		Events.event_room_exited.emit()
		return

	if not stats.seen_events.has(definition.resource_path):
		stats.seen_events.append(definition.resource_path)

	var scene := definition.custom_scene if definition.custom_scene else CHOICE_EVENT_SCENE
	var event_room := _change_view(scene) as EventRoom
	event_room.definition = definition
	event_room.character_stats = character
	event_room.run_stats = stats
	event_room.relic_handler = relic_handler
	event_room.map = map
	event_room.relic_pool = battle_relic_pool
	event_room.setup()

func _on_battle_won() -> void:
	dda.update_score_battle(character.health, character.max_health,stats)
	
	var hp_percentage: float = (float(character.health)/float(character.max_health) if character.max_health > 0 else 0.0)
	var score: int = stats.dda_score
	
	#SCORE ALTO: Se tiver muitos itens, torca shop por combate. Se hp estiver alto, troca cura por combate. Se hp estiver baixo, troca evento por combate
	if score >= 65:
		var relic_count: int = relic_handler.get_all_relics().size()
		
		if relic_count >= 6 and dda_shop_changed == false:
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
		if act_index < ACTS.size() - 1:
			var transition := _change_view(ACT_TRANSITION_SCENE) as ActTransition
			transition.setup(ACTS[act_index], ACTS[act_index + 1])
		else:
			var win_screen := _change_view(WIN_SCREEN_SCENE) as WinScreen
			win_screen.character = character
	elif act_index == 0 and map.last_room.row == 0:
		_show_first_battle_reward()
	else:
		_show_regular_battle_rewards()

func _on_map_exited(room: Room) -> void:
	_prepare_battle(room)
	
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
