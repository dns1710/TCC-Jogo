class_name Inventory
extends Control

@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var close_button: Button = %CloseButton

@onready var weapon_slot: Button = %WeaponSlot
@onready var helmet_slot: Button = %HelmetSlot
@onready var armor_slot: Button = %ArmorSlot

@onready var health_icon: TextureRect = %HealthIcon
@onready var block_icon: TextureRect = %BlockIcon
@onready var attack_icon: TextureRect = %AttackIcon
@onready var speed_icon: TextureRect = %SpeedIcon
	
@onready var health_label: Label = %HealthLabel
@onready var block_label: Label = %BlockLabel
@onready var attack_label: Label = %AttackLabel
@onready var speed_label: Label = %SpeedLabel

@onready var trinket_slot_1: Button = %TrinketSlot1
@onready var trinket_slot_2: Button = %TrinketSlot2

var relic_handler: RelicHandler
var hover_tooltip: HoverTooltip
var empty_slot_icons: Dictionary = {}
var empty_slot_tooltips: Dictionary = {}
var animation_lock: bool = false
var battle_lock: bool = false


func _ready() -> void:
	hover_tooltip = get_tree().get_first_node_in_group("global_tooltip") as HoverTooltip
	
	Events.animation_dda_lock.connect(_animation_lock_check)
	Events.battle_start.connect(_on_battle_start)
	Events.battle_over_screen_requested.connect(_on_battle_over)
	
	close_button.pressed.connect(close_inventory)
	weapon_slot.pressed.connect(_on_equipment_slot_pressed.bind(weapon_slot))
	helmet_slot.pressed.connect(_on_equipment_slot_pressed.bind(helmet_slot))
	armor_slot.pressed.connect(_on_equipment_slot_pressed.bind(armor_slot))
	trinket_slot_1.pressed.connect(_on_equipment_slot_pressed.bind(trinket_slot_1))
	trinket_slot_2.pressed.connect(_on_equipment_slot_pressed.bind(trinket_slot_2))
	
	empty_slot_icons[weapon_slot] = weapon_slot.icon
	empty_slot_icons[helmet_slot] = helmet_slot.icon
	empty_slot_icons[armor_slot] = armor_slot.icon
	empty_slot_icons[trinket_slot_1] = trinket_slot_1.icon
	empty_slot_icons[trinket_slot_2] = trinket_slot_2.icon
	
	empty_slot_tooltips[weapon_slot] = {
		"title": "Weapon Slot",
		"description": "Empty\n\n1d4 weapon damage",
	}
	empty_slot_tooltips[helmet_slot] = {
		"title": "Helmet Slot",
		"description": "Empty"
	}
	empty_slot_tooltips[armor_slot] = {
		"title": "Armor Slot",
		"description": "Empty"
	}
	for trinket_slot in [trinket_slot_1, trinket_slot_2]:
		empty_slot_tooltips[trinket_slot] = {
			"title": "Trinket Slot",
			"description": "Empty"
		}
	
	_setup_stat_tooltip(
		health_icon,
		"Health",
		"Your health. Don't let it reach 0!"
	)
	_setup_stat_tooltip(
		block_icon,
		"Block",
		"How much block you start a combat
		\nBlock prevents incoming damage"
	)
	_setup_stat_tooltip(
		attack_icon,
		"Attack",
		"The higher your attack, the stronger your strikes"
	)
	_setup_stat_tooltip(
		speed_icon,
		"Speed",
		"The faster you are, the more you act in battle"
	)
	
	weapon_slot.mouse_entered.connect(_on_equipment_mouse_entered.bind(weapon_slot))
	helmet_slot.mouse_entered.connect(_on_equipment_mouse_entered.bind(helmet_slot))
	armor_slot.mouse_entered.connect(_on_equipment_mouse_entered.bind(armor_slot))
	trinket_slot_1.mouse_entered.connect(_on_equipment_mouse_entered.bind(trinket_slot_1))
	trinket_slot_2.mouse_entered.connect(_on_equipment_mouse_entered.bind(trinket_slot_2))

	weapon_slot.mouse_exited.connect(_on_relic_mouse_exited)
	helmet_slot.mouse_exited.connect(_on_relic_mouse_exited)
	armor_slot.mouse_exited.connect(_on_relic_mouse_exited)
	trinket_slot_1.mouse_exited.connect(_on_relic_mouse_exited)
	trinket_slot_2.mouse_exited.connect(_on_relic_mouse_exited)

func _animation_lock_check(value: bool) -> void:
	animation_lock = value

func _on_battle_start() -> void:
	battle_lock = true

func _on_battle_over(_string = null, _type = null) -> void:
	battle_lock = false
	
func open_inventory(handler: RelicHandler) -> void:
	if animation_lock:
		return
		
	relic_handler = handler
	show()
	update_inventory()
	update_equipment_slots()
	update_player_stats()
	await get_tree().process_frame

func close_inventory() -> void:
	if hover_tooltip:
		hover_tooltip.hide_tooltip()
	hide()
	

func update_inventory() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	
	for relic: Relic in relic_handler.get_unequipped_relics():
		var item_button := Button.new()
		item_button.custom_minimum_size = Vector2(24,24)
		item_button.icon = relic.icon
		item_button.expand_icon = true
		item_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inventory_grid.add_child(item_button)
		item_button.pressed.connect(_on_relic_button_pressed.bind(relic))
		item_button.mouse_entered.connect(_on_relic_mouse_entered.bind(relic))
		item_button.mouse_exited.connect(_on_relic_mouse_exited)


func update_player_stats() -> void:
	var stats: CharacterStats = relic_handler.character_stats
	
	if not stats:
		return
		
	health_label.text = "%d/%d" % [stats.health, stats.max_health]
	block_label.text = "%d" % stats.max_block
	attack_label.text = "%d" % stats.max_attack
	speed_label.text = "%d" % stats.max_speed

func _on_relic_button_pressed(relic: Relic) -> void:
	if battle_lock:
		print("Can't change items on battle!")
		return
		
	if relic_handler.equip_relic(relic):
		update_inventory()
		update_equipment_slots()
		update_player_stats()


func update_equipment_slots() -> void:
	_update_slot(weapon_slot, relic_handler.equipped_weapon)
	_update_slot(helmet_slot, relic_handler.equipped_helmet)
	_update_slot(armor_slot, relic_handler.equipped_armor)
	_update_slot(trinket_slot_1, relic_handler.equipped_trinkets[0])
	_update_slot(trinket_slot_2, relic_handler.equipped_trinkets[1])

func _update_slot(slot: Button, relic: Relic) -> void:
	if relic:
		slot.icon = relic.icon
	else:
		slot.icon = empty_slot_icons[slot]
	
	slot.expand_icon = true
	slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _on_equipment_slot_pressed(slot: Button) -> void:
	if battle_lock:
		print("Can't change items on battle!")
		return
		
	#var relic: Relic

	#if slot == weapon_slot:
	#	relic = relic_handler.equipped_weapon
	#elif slot == helmet_slot:
	#	relic = relic_handler.equipped_helmet
	#elif slot == armor_slot:
	#	relic = relic_handler.equipped_armor
	#elif slot == trinket_slot_1:
	#	relic = relic_handler.equipped_trinkets[0]
	#elif slot == trinket_slot_2:
	#	relic = relic_handler.equipped_trinkets[1]
	var relic := _get_slot_relic(slot)
	if relic == null:
		return

	if relic_handler.unequip_relic_instance(relic):
		update_inventory()
		update_equipment_slots()
		update_player_stats()
		_on_relic_mouse_exited()
		_on_equipment_mouse_entered(slot)
	
	
func _on_relic_mouse_entered(relic: Relic) -> void:
	if not relic or not hover_tooltip:
		return
		
	hover_tooltip.show_tooltip(relic.relic_name, relic.get_tooltip(), relic.get_rarity(), relic.get_equip())


func _get_slot_relic(slot: Button) -> Relic:
	if slot == weapon_slot:
		return relic_handler.equipped_weapon
	if slot == helmet_slot:
		return relic_handler.equipped_helmet
	if slot == armor_slot:
		return relic_handler.equipped_armor
	if slot == trinket_slot_1:
		return relic_handler.equipped_trinkets[0]
	if slot == trinket_slot_2:
		return relic_handler.equipped_trinkets[1]
	return null


func _show_empty_slot_tooltip(slot: Button) -> void:
	if not hover_tooltip or not empty_slot_tooltips.has(slot):
		return
	var data: Dictionary = empty_slot_tooltips[slot]
	hover_tooltip.show_tooltip(data["title"], data["description"])


func _on_equipment_mouse_entered(slot: Button) -> void:
	var relic := _get_slot_relic(slot)
	if relic:
		_on_relic_mouse_entered(relic)
	else:
		_show_empty_slot_tooltip(slot)
	#var relic: Relic
	
	#if slot == weapon_slot:
	#	relic = relic_handler.equipped_weapon
	#elif slot == helmet_slot:
	#	relic = relic_handler.equipped_helmet
	#elif slot == armor_slot:
	#	relic = relic_handler.equipped_armor
	#elif slot == trinket_slot_1:
	#	relic = relic_handler.equipped_trinkets[0]
	#elif slot == trinket_slot_2:
	#	relic = relic_handler.equipped_trinkets[1]
	
	#if relic:
	#	_on_relic_mouse_entered(relic)


func _on_relic_mouse_exited() -> void:
	if hover_tooltip:
		hover_tooltip.hide_tooltip()


func _setup_stat_tooltip(icon: Control, title: String, description: String) -> void:
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_entered.connect(_on_stat_mouse_entered.bind(title, description))
	icon.mouse_exited.connect(_on_relic_mouse_exited)


func _on_stat_mouse_entered(title: String, description: String) -> void:
	if hover_tooltip:
		hover_tooltip.show_tooltip(title, description)
	
