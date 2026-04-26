class_name CharacterStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture

@export_group("Gameplay Data")

@export var max_mana: int
@export var starting_relic: Relic

var mana: int : set = set_mana

func set_mana(value: int) -> void:
	mana = value
	stats_changed.emit()


func reset_mana() -> void:
	mana = max_mana


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()

func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.speed = 5
	return instance
