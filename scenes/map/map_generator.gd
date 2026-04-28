class_name MapGenerator
extends Node

const X_DIST := 120
const Y_DIST := 80
const PLACEMENT_RANDOMNESS := 0
const FLOORS := 7
const MAP_WIDTH := 7

@export var battle_stats_pool: BattleStatsPool
@export var event_room_pool: EventRoomPool

var map_data: Array[Array]


func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()

	var mid := int(MAP_WIDTH / 2)

	battle_stats_pool.setup()

	
	# FLOOR 0 → START
	
	var start = map_data[0][mid]
	_set_room_type(
		start,
		Room.Type.MONSTER,
		battle_stats_pool.get_random_battle_for_tier(0)
	)


	# FLOOR 1 → bifurcação

	var left1 = map_data[1][mid - 1]
	var right1 = map_data[1][mid + 1]

	_set_room_type(left1, Room.Type.EVENT, event_room_pool.get_random())
	_set_room_type(right1, Room.Type.EVENT, event_room_pool.get_random())

	start.connect_to([left1, right1])

	
	# FLOOR 2 → combate
	
	var combat2 = map_data[2][mid]
	_set_room_type(
		combat2,
		Room.Type.MONSTER,
		battle_stats_pool.get_random_battle_for_tier(1)
	)

	left1.connect_to([combat2])
	right1.connect_to([combat2])


	# FLOOR 3 → treasure
	
	var treasure = map_data[3][mid]
	_set_room_type(treasure, Room.Type.TREASURE)

	combat2.connect_to([treasure])


	# FLOOR 4 → bifurcação
	
	var left2 = map_data[4][mid - 1]
	var right2 = map_data[4][mid + 1]

	_set_room_type(left2, Room.Type.EVENT, event_room_pool.get_random())
	_set_room_type(right2, Room.Type.CAMPFIRE)

	treasure.connect_to([left2, right2])


	# FLOOR 5 → rest
	
	var rest = map_data[5][mid]
	_set_room_type(rest, Room.Type.CAMPFIRE)

	left2.connect_to([rest])
	right2.connect_to([rest])

	
	# FLOOR 6 → boss

	var boss = map_data[6][mid]
	_set_room_type(
		boss,
		Room.Type.MONSTER,
		battle_stats_pool.get_random_battle_for_tier(2)
	)

	rest.connect_to([boss])

	return map_data



func _set_room_type(room: Room, type: Room.Type, extra_data: Variant = null) -> void:
	room.type = type
	room.original_type = type

	match type:
		Room.Type.MONSTER:
			room.battle_stats = extra_data

		Room.Type.EVENT:
			room.event_scene = extra_data


func _generate_initial_grid() -> Array[Array]:
	var result: Array[Array] = []

	for i in FLOORS:
		var row: Array[Room] = []

		for j in MAP_WIDTH:
			var room := Room.new()

			room.row = i
			room.column = j

			var offset := Vector2(randf(), randf()) * PLACEMENT_RANDOMNESS
			room.position = Vector2(i * X_DIST, j * Y_DIST) + offset

			row.append(room)

		result.append(row)

	return result
