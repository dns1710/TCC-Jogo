class_name Inventory
extends Control

@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var close_button: Button = %CloseButton

@onready var weapon_slot: Button = %WeaponSlot
@onready var helmet_slot: Button = %HelmetSlot
@onready var armor_slot: Button = %ArmorSlot

@onready var health_label: Label = %HealthLabel
@onready var block_label: Label = %BlockLabel
@onready var attack_label: Label = %AttackLabel
@onready var speed_label: Label = %SpeedLabel

@onready var trinket_slot_1: Button = %TrinketSlot1
@onready var trinket_slot_2: Button = %TrinketSlot2

var relic_handler: RelicHandler

var empty_slot_icons: Dictionary = {}

func _ready() -> void:
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
	
func open_inventory(handler: RelicHandler) -> void:
	relic_handler = handler
	print("INVENTÁRIO ABERTO")
	print("Quantidade de itens: ", relic_handler.get_all_relics().size())
	show()
	update_inventory()
	update_equipment_slots()
	update_player_stats()
	await get_tree().process_frame

func close_inventory() -> void:
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
		#var item_icon := TextureRect.new()
		#item_icon.texture = relic.icon
		#item_icon.custom_minimum_size = Vector2(16, 16)
		#item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		#item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		#inventory_grid.add_child(item_icon)


func update_player_stats() -> void:
	var stats: CharacterStats = relic_handler.character_stats
	
	if not stats:
		return
		
	health_label.text = "%d/%d" % [stats.health, stats.max_health]
	block_label.text = "%d" % stats.max_block
	attack_label.text = "%d" % stats.max_attack
	speed_label.text = "%d" % stats.max_speed

func _on_relic_button_pressed(relic: Relic) -> void:
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
	var relic: Relic

	if slot == weapon_slot:
		relic = relic_handler.equipped_weapon
	elif slot == helmet_slot:
		relic = relic_handler.equipped_helmet
	elif slot == armor_slot:
		relic = relic_handler.equipped_armor
	elif slot == trinket_slot_1:
		relic = relic_handler.equipped_trinkets[0]
	elif slot == trinket_slot_2:
		relic = relic_handler.equipped_trinkets[1]

	if relic == null:
		return

	if relic_handler.unequip_relic_instance(relic):
		update_inventory()
		update_equipment_slots()
		update_player_stats()
