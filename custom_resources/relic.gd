class_name Relic
extends Resource

enum Type {PASSIVE_STATS, START_OF_TURN, START_OF_COMBAT, END_OF_TURN, END_OF_COMBAT, EVENT_BASED}
enum Equip {WEAPON, HELMET, ARMOR, TRINKET}
enum Rarity {COMMON, UNCOMMON, RARE}
enum CharacterType {ALL}

@export var relic_name: String
@export var id: String
@export var type: Type
@export var equip: Equip
@export var rarity: Rarity
@export var character_type: CharacterType
@export var starter_relic: bool = false
@export var icon: Texture
@export_multiline var tooltip: String

@export var bonus_blk := 0
@export var bonus_atk := 0
@export var bonus_spd := 0
@export var weapon_dice_attack := 0
@export var weapon_dice_amount := 0


func initialize_relic(_owner: RelicUI) -> void:
	pass

func activate_relic(_owner: RelicUI) -> void:
	pass

func deactivate_relic(_owner: RelicUI) -> void:
	pass

func get_tooltip() -> String:
	return tooltip

func get_weapon_bonus_damage() -> int:
	return 0

func on_attack_hit(_targets: Array[Node]) -> void:
	pass

func get_equip() -> String:
	var relic_equip: String
	
	match equip:
		Relic.Equip.WEAPON:
			relic_equip = "Weapon"
		Relic.Equip.HELMET:
			relic_equip = "Helmet"
		Relic.Equip.ARMOR:
			relic_equip = "Armor"
		Relic.Equip.TRINKET:
			relic_equip = "Trinket"

	return relic_equip


func get_rarity() -> String:
	var relic_rarity: String
	
	match rarity:
		Relic.Rarity.COMMON:
			relic_rarity = "Common"
		Relic.Rarity.UNCOMMON:
			relic_rarity = "Uncommon"
		Relic.Rarity.RARE:
			relic_rarity = "Rare"
	
	return relic_rarity
	

func can_appear_as_reward(character: CharacterStats) -> bool:
	if starter_relic:
		return false

	if character_type == CharacterType.ALL:
		return true
		
	var relic_char_name: String = CharacterType.keys()[character_type].to_lower()
	var char_name := character.character_name.to_lower()
	
	return relic_char_name == char_name
