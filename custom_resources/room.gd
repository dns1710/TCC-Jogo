class_name Room
extends Resource

enum Type {NOT_ASSIGNED, MONSTER, TREASURE, CAMPFIRE, SHOP, BOSS, EVENT}

@export var type: Type = Type.NOT_ASSIGNED
@export var row: int = 0
@export var column: int = 0
@export var position: Vector2 = Vector2.ZERO

@export var next_rooms: Array[Room] = []

@export var selected := false

# This is only used by the MONSTER and BOSS types
@export var battle_stats: BattleStats

# This is only used by the EVENT room type
@export var event_scene: PackedScene


func _init():
	next_rooms = []


# 🔥 HELPER AQUI
func connect_to(rooms: Array) -> void:
	next_rooms.clear()
	for r in rooms:
		next_rooms.append(r)


func _to_string() -> String:
	return "%s (%s)" % [column, Type.keys()[type]]
