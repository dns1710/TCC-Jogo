class_name Stats
extends Resource
signal stats_changed

@export var max_health : int : set = set_max_health
@export var max_speed: int
@export var max_block: int
@export var art: Texture
const cap_speed := 20

@export var health: int : set = set_health
@export var block: int : set = set_block
@export var speed: int : set = set_speed

func set_health(value : int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()

func set_block(value : int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()

func set_speed(value : int) -> void:
	speed = clampi(value, 0, cap_speed)
	stats_changed.emit()

func set_max_health(value : int) -> void:
	var diff := value - max_health
	max_health = value
	
	if diff > 0:
		health += diff
	elif health > max_health:
		health = max_health
	
	stats_changed.emit()

func take_damage(damage : int) -> void:
	if damage <= 0:
		return
	var initial_damage = damage
	damage = clampi(damage - block, 0, damage)
	block = clampi(block - initial_damage, 0, block)
	health -= damage

func heal(amount : int) -> void:
	health += amount

func create_instance() -> Resource:
	var instance: Stats = self.duplicate()
	instance.health = max_health
	instance.block = max_block
	instance.speed = max_speed
	return instance
