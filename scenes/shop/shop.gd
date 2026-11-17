class_name Shop
extends Control

const SHOP_CARD = preload("res://scenes/shop/shop_card.tscn")
const SHOP_RELIC = preload("res://scenes/shop/shop_relic.tscn")

@export var shop_relics: Array[Relic]
@export var char_stats: CharacterStats
@export var run_stats: RunStats
@export var relic_handler: RelicHandler

@onready var cards: HBoxContainer = %Cards
@onready var relics_row_1: HBoxContainer = %Row1
@onready var relics_row_2: HBoxContainer = %Row2
@onready var shop_keeper_animation: AnimationPlayer = %ShopkeeperAnimation
@onready var blink_timer: Timer = %BlinkTimer
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var tier = RNG.instance.randi_range(1,3)

var row_1_range: int
var row_2_range: int

func _ready() -> void:
	if tier == 1:
		row_1_range = 2
		row_2_range = 1
	elif tier == 2:
		row_1_range = 2
		row_2_range = 2
	elif tier == 3:
		row_1_range = 3
		row_2_range = 2
		
	for shop_card: ShopCard in cards.get_children():
		shop_card.queue_free()
		
	for shop_relic: ShopRelic in relics_row_1.get_children():
		shop_relic.queue_free()
	
	for shop_relic: ShopRelic in relics_row_2.get_children():
		shop_relic.queue_free()
		
	Events.shop_relic_bought.connect(_on_shop_relic_bought)

	_blink_timer_setup()
	blink_timer.timeout.connect(_on_blink_timer_timeout)



func populate_shop() -> void:
	_clear_relic_rows()
	_generate_shop_relics()


func _blink_timer_setup() -> void:
	blink_timer.wait_time = randf_range(1.0, 5.0)
	blink_timer.start()


func _clear_relic_rows() -> void:
	for child in relics_row_1.get_children():
		relics_row_1.remove_child(child)
		child.queue_free()

	for child in relics_row_2.get_children():
		relics_row_2.remove_child(child)
		child.queue_free()
		
		
func _generate_shop_relics() -> void:
	var available_relics: Dictionary = {
		Relic.Rarity.COMMON: [],
		Relic.Rarity.UNCOMMON: [],
		Relic.Rarity.RARE: []
	}
	
	for relic: Relic in shop_relics:
		if relic == null:
			continue
		if not relic.can_appear_as_reward(char_stats):
			continue
		if relic_handler.has_relic(relic.id):
			continue
		available_relics[relic.rarity].append(relic)
	
	var rarity_weights: Dictionary = {
		Relic.Rarity.COMMON: 50,
		Relic.Rarity.UNCOMMON: 35,
		Relic.Rarity.RARE: 15
	}
	
	var shop_relics_array: Array[Relic] = []
	
	for i in range(row_1_range + row_2_range):
		var total_weight := 0
		var available_rarities: Array[int] = []
		for rarity: int in rarity_weights:
			if not available_relics[rarity].is_empty():
				available_rarities.append(rarity)
				total_weight += rarity_weights[rarity]
		if available_rarities.is_empty():
			break
		var roll := RNG.pick_random(1,total_weight)
		var selected_rarity := -1
		for rarity: int in available_rarities:
			roll -= rarity_weights[rarity]
			if roll <= 0:
				selected_rarity = rarity
				break
		var selected_relic: Relic = RNG.array_pick_random(
			available_relics[selected_rarity]
		)
		
		shop_relics_array.append(selected_relic)
		available_relics[selected_rarity].erase(selected_relic)
	
	var row_1_count := 0
	var row_2_count := 0
	
	for relic: Relic in shop_relics_array:
		var new_shop_relic := SHOP_RELIC.instantiate() as ShopRelic
		print("ROW 1 LIMIT:", row_1_range)
		print("ROW 2 LIMIT:", row_2_range)
		print("ROW 1:", relics_row_1.get_child_count())
		print("ROW 2:", relics_row_2.get_child_count())
		
		if row_1_count < row_1_range:
			relics_row_1.add_child(new_shop_relic)
			row_1_count += 1
		else:
			relics_row_2.add_child(new_shop_relic)
		new_shop_relic.relic = relic
		new_shop_relic.gold_cost = _get_updated_shop_cost(new_shop_relic.gold_cost)
		new_shop_relic.update(run_stats)
	
	#var shop_relics_array: Array[Relic] = []
	#var available_relics := shop_relics.filter(
	#	func(relic: Relic):
	#		var can_appear := relic.can_appear_as_reward(char_stats)
	#		var already_had_it := relic_handler.has_relic(relic.id)
	#		return can_appear and not already_had_it
	#)
	
	#RNG.array_shuffle(available_relics)
	#shop_relics_array = available_relics.slice(0, 3)
	
	#for relic: Relic in shop_relics_array:
	#	var new_shop_relic := SHOP_RELIC.instantiate() as ShopRelic
	#	relics.add_child(new_shop_relic)
	#	new_shop_relic.relic = relic
	#	new_shop_relic.gold_cost = _get_updated_shop_cost(new_shop_relic.gold_cost)
	#	new_shop_relic.update(run_stats)


func _update_items() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics_row_1.get_children():
		shop_relic.update(run_stats)
	
	for shop_relic: ShopRelic in relics_row_2.get_children():
		shop_relic.update(run_stats)


func _update_item_costs() -> void:
	for shop_card: ShopCard in cards.get_children():
		shop_card.gold_cost = _get_updated_shop_cost(shop_card.gold_cost)
		shop_card.update(run_stats)

	for shop_relic: ShopRelic in relics_row_1.get_children():
		shop_relic.gold_cost = _get_updated_shop_cost(shop_relic.gold_cost)
		shop_relic.update(run_stats)
	
	for shop_relic: ShopRelic in relics_row_2.get_children():
		shop_relic.gold_cost = _get_updated_shop_cost(shop_relic.gold_cost)
		shop_relic.update(run_stats)


func _get_updated_shop_cost(original_cost: int) -> int:
	return modifier_handler.get_modified_value(original_cost, Modifier.Type.SHOP_COST)


func _on_back_button_pressed() -> void:
	Events.shop_exited.emit()

func _on_shop_relic_bought(relic: Relic, gold_cost: int) -> void:
	relic_handler.add_relic(relic)
	run_stats.gold -= gold_cost

	if relic is CouponsRelic:
		var coupons_relic := relic as CouponsRelic
		coupons_relic.add_shop_modifier(self)
		_update_item_costs()
	else:
		_update_items()


func _on_blink_timer_timeout() -> void:
	shop_keeper_animation.play("blink")
	_blink_timer_setup()
