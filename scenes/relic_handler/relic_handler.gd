class_name RelicHandler
extends HBoxContainer

signal relics_activated(type: Relic.Type)

const RELIC_APPLY_INTERVAL := 0.5
const RELIC_UI = preload("res://scenes/relic_handler/relic_ui.tscn")

@export var run_stats: RunStats
@export var character_stats: CharacterStats

@onready var relics_control: RelicsControl = $RelicsControl
@onready var relics: HBoxContainer = %Relics

var inventory: Array[Relic] = []
var equipped_weapon: Relic
var equipped_armor: Relic
var equipped_helmet: Relic
var equipped_trinkets: Array[Relic] = [null,null]


func _ready() -> void:
	add_to_group("relic_handler")
	relics.child_exiting_tree.connect(_on_relics_child_exiting_tree)


#-------INVENTÁRIO-------

func add_relics(relics_array: Array[Relic]) -> void:
	for relic: Relic in relics_array:
		add_relic(relic)


func add_relic(relic: Relic) -> void:
	if relic == null:
		push_error("Tentou adicionar relic NULL")
		return
		
	if has_relic(relic.id):
		return
	
	inventory.append(relic)
	
	if run_stats:
		run_stats.dda_score = clampi(run_stats.dda_score + 5, 0, 100)
		print("ADD RELIC. SCORE: ", run_stats.dda_score)
	
	#if relic.equip == Relic.Equip.TRINKET:
	#	var trinket_slot := equipped_trinkets.find(null)
	#	if trinket_slot == -1:
	#		trinket_slot = 0
	#	equip_relic(relic, trinket_slot)
	#else:
	#	equip_relic(relic)
	
	#_apply_relic_stats(relic)
	
	#var new_relic_ui := RELIC_UI.instantiate() as RelicUI
	#relics.add_child(new_relic_ui)
	#new_relic_ui.relic = relic
	#new_relic_ui.relic.initialize_relic(new_relic_ui)
	
	
func has_relic(id: String) -> bool:
	for relic: Relic in inventory:
		if relic.id == id:
			return true
	#for relic_ui: RelicUI in relics.get_children():
	#	if relic_ui.relic.id == id and is_instance_valid(relic_ui):
	#		return true

	return false


func get_all_relics() -> Array[Relic]:
	return inventory.duplicate()

func get_unequipped_relics() -> Array[Relic]:
	var result: Array[Relic] = []
	for relic: Relic in inventory:
		if not is_equipped(relic):
			result.append(relic)
	return result


#-------EQUIPAMENTOS-------

func equip_relic(relic: Relic, trinket_slot: int = -1) -> bool:
	if relic == null or not has_relic(relic.id):
		return false
	
	match relic.equip:
		Relic.Equip.WEAPON:
			unequip_relic(Relic.Equip.WEAPON)
			equipped_weapon = relic
		Relic.Equip.HELMET:
			unequip_relic(Relic.Equip.HELMET)
			equipped_helmet = relic
		Relic.Equip.ARMOR:
			unequip_relic(Relic.Equip.ARMOR)
			equipped_armor = relic
		Relic.Equip.TRINKET:
			if trinket_slot == -1:
				trinket_slot = equipped_trinkets.find(null)
			if trinket_slot < 0 or trinket_slot > 1:
				return false
			unequip_trinket(trinket_slot)
			equipped_trinkets[trinket_slot] = relic
	_initialize_equipped_relic(relic)
	return true


func unequip_relic(equip_type: Relic.Equip) -> void:
	match equip_type:
		Relic.Equip.HELMET:
			if equipped_helmet:
				_remove_equipped_relic(equipped_helmet)
				equipped_helmet = null

		Relic.Equip.ARMOR:
			if equipped_armor:
				_remove_equipped_relic(equipped_armor)
				equipped_armor = null

		Relic.Equip.WEAPON:
			if equipped_weapon:
				_remove_equipped_relic(equipped_weapon)
				equipped_weapon = null

		Relic.Equip.TRINKET:
			unequip_trinket(0)
			unequip_trinket(1)


func unequip_trinket(slot: int) -> void:
	if slot < 0 or slot > 1:
		return
	
	var relic: Relic = equipped_trinkets[slot]
	
	if relic:
		_remove_equipped_relic(relic)
		equipped_trinkets[slot] = null


func unequip_relic_instance(relic: Relic) -> bool:
	if relic == null:
		return false

	if equipped_weapon == relic:
		unequip_relic(Relic.Equip.WEAPON)
		return true

	if equipped_helmet == relic:
		unequip_relic(Relic.Equip.HELMET)
		return true

	if equipped_armor == relic:
		unequip_relic(Relic.Equip.ARMOR)
		return true

	for i in range(equipped_trinkets.size()):
		if equipped_trinkets[i] == relic:
			unequip_trinket(i)
			return true

	return false


func is_equipped(relic: Relic) -> bool:
	if relic == null:
		return false
	
	return(
		equipped_weapon == relic
		or equipped_helmet == relic
		or equipped_armor == relic
		or equipped_trinkets.has(relic)
	)


func get_equipped_relics() -> Array[Relic]:
	var result: Array[Relic] = []

	if equipped_helmet:
		result.append(equipped_helmet)

	if equipped_armor:
		result.append(equipped_armor)

	if equipped_weapon:
		result.append(equipped_weapon)

	for relic: Relic in equipped_trinkets:
		if relic:
			result.append(relic)

	return result


func _initialize_equipped_relic(relic: Relic) -> void:
	_apply_relic_stats(relic)
	var new_relic_ui := RELIC_UI.instantiate() as RelicUI
	relics.add_child(new_relic_ui)
	new_relic_ui.relic = relic
	relic.initialize_relic(new_relic_ui)


func _remove_equipped_relic(relic: Relic) -> void:
	_remove_relic_stats(relic)
	for relic_ui: RelicUI in _get_all_relic_ui_nodes():
		if relic_ui.relic == relic:
			relic_ui.queue_free()
			break
			

func get_weapon_damage() -> int:
	if equipped_weapon:
		return Dice.roll(equipped_weapon.weapon_dice_amount, equipped_weapon.weapon_dice_attack, character_stats.attack)
	return Dice.roll(1,4,character_stats.attack)


func get_relic_by_id(id: String) -> Relic:
	if id.is_empty():
		return null
	for relic: Relic in inventory:
		if relic.id == id:
			return relic
	return null


func restore_equipment(weapon_id: String, helmet_id: String, armor_id: String, trinket_1_id: String, trinket_2_id: String) -> void:
	
	var weapon := get_relic_by_id(weapon_id)
	var helmet := get_relic_by_id(helmet_id)
	var armor := get_relic_by_id(armor_id)
	var trinket1 := get_relic_by_id(trinket_1_id)
	var trinket2 := get_relic_by_id(trinket_2_id)
	
	if weapon:
		equip_relic(weapon)
	if helmet:
		equip_relic(helmet)
	if armor:
		equip_relic(armor)
	if trinket1:
		equip_relic(trinket1,0)
	if trinket2:
		equip_relic(trinket2,1)
	return
#-------STATS-------

func _apply_relic_stats(relic: Relic) -> void:
	if not character_stats:
		return

	character_stats.max_block += relic.bonus_blk
	character_stats.max_attack += relic.bonus_atk
	character_stats.max_speed += relic.bonus_spd
	character_stats.stats_changed.emit()
	

func _remove_relic_stats(relic: Relic) -> void:
	if not character_stats:
		return
	
	character_stats.max_block -= relic.bonus_blk
	character_stats.max_attack -= relic.bonus_atk
	character_stats.max_speed -= relic.bonus_spd
	character_stats.stats_changed.emit()


#-------EFEITOS-------

func activate_relics_by_type(type: Relic.Type) -> void:
	if type == Relic.Type.PASSIVE_STATS:
		return
		
	var relic_queue: Array[RelicUI] = _get_all_relic_ui_nodes().filter(
		func(relic_ui: RelicUI):
			return relic_ui.relic.type == type
	)
	
	if relic_queue.is_empty():
		relics_activated.emit(type)
		return
	
	var tween := create_tween()
	for relic_ui: RelicUI in relic_queue:
		tween.tween_callback(relic_ui.relic.activate_relic.bind(relic_ui))
		tween.tween_interval(RELIC_APPLY_INTERVAL)
	
	tween.finished.connect(func(): relics_activated.emit(type))
	

func _get_all_relic_ui_nodes() -> Array[RelicUI]:
	var all_relics: Array[RelicUI] = []
	for relic_ui: RelicUI in relics.get_children():
		all_relics.append(relic_ui)
		
	return all_relics
	
	
#func get_all_relics() -> Array[Relic]:
#	var relic_ui_nodes := _get_all_relic_ui_nodes()
#	var relics_array: Array[Relic] = []
	
#	for relic_ui: RelicUI in relic_ui_nodes:
#		relics_array.append(relic_ui.relic)
	
#	return relics_array


func _on_relics_child_exiting_tree(relic_ui: RelicUI) -> void:
	if not relic_ui or not relic_ui.relic:
		return
	relic_ui.relic.deactivate_relic(relic_ui)
	#if relic_ui.relic:
	#	relic_ui.relic.deactivate_relic(relic_ui)
