class_name MapGenerator
extends Node

const X_DIST := 50
const Y_DIST := 35
const PLACEMENT_RANDOMNESS := 0
const FLOORS := 11
const MAP_WIDTH := 3

@export var battle_stats_pool: BattleStatsPool
@export var event_room_pool: EventRoomPool

var map_data: Array[Array]


func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()

	battle_stats_pool.setup()

	var mid := int(MAP_WIDTH / 2)

	# Sala inicial
	var start_room: Room = map_data[0][mid]
	start_room.active = true

	_set_room_type(
		start_room,
		Room.Type.MONSTER,
		battle_stats_pool.get_random_battle_for_tier(0)
	)

	var top_room: Room = map_data[1][0]
	var middle_room: Room = map_data[1][1]
	var bottom_room: Room = map_data[1][2]

	start_room.add_connection(top_room)
	start_room.add_connection(middle_room)
	start_room.add_connection(bottom_room)

	top_room.active = true
	middle_room.active = true
	bottom_room.active = true

	var current_rooms: Array[Room] = [
		top_room,
		middle_room,
		bottom_room
	]


	for floor in range(1, FLOORS - 2):

		var next_rooms: Array[Room] = []
		var floor_connections := []

		for room in current_rooms:

			var possible_columns: Array[int] = [room.column]

			# chance de abrir caminho para cima
			if room.column > 0 and randf() < 0.35:
				possible_columns.append(room.column - 1)

			# chance de abrir caminho para baixo
			if room.column < MAP_WIDTH - 1 and randf() < 0.35:
				possible_columns.append(room.column + 1)

			for col in possible_columns:

				var target: Room = map_data[floor + 1][col]

				var new_from := room.column
				var new_to := target.column

				var would_cross := false

				for connection in floor_connections:

					var existing_from = connection["from"]
					var existing_to = connection["to"]

					if (
						(new_from < existing_from and new_to > existing_to)
						or
						(new_from > existing_from and new_to < existing_to)
					):
						would_cross = true
						break

				if would_cross:
					continue

				room.add_connection(target)

				floor_connections.append({
					"from": new_from,
					"to": new_to
				})

				target.active = true

				if not next_rooms.has(target):
					next_rooms.append(target)

		# Limita a no máximo 3 caminhos simultâneos
		while next_rooms.size() > 3:
			next_rooms.remove_at(randi() % next_rooms.size())

		current_rooms = next_rooms


	var treasure_floor := int(FLOORS / 2)

	for floor in range(1, FLOORS - 1):

		for room in map_data[floor]:

			if not room.active:
				continue

			# Sala do meio sempre é tesouro
			if floor == treasure_floor:
				_set_room_type(room, Room.Type.TREASURE)
				continue

			_assign_random_type(room)

	var boss_room: Room = map_data[FLOORS - 1][mid]

	boss_room.active = true

	_set_room_type(
		boss_room,
		Room.Type.BOSS,
		battle_stats_pool.get_random_battle_for_tier(2)
	)

	for room in current_rooms:
		room.add_connection(boss_room)

	return map_data

func _assign_random_type(room: Room) -> void:
	var roll := randf()

	if roll < 0.50:
		_set_room_type(
			room,
			Room.Type.MONSTER,
			battle_stats_pool.get_random_battle_for_tier(1)
		)

	elif roll < 0.75:
		_set_room_type(
			room,
			Room.Type.EVENT,
			event_room_pool.get_random()
		)

	elif roll < 0.83:
		_set_room_type(room, Room.Type.CAMPFIRE)

	elif roll < 0.93:
		_set_room_type(room, Room.Type.SHOP)

	else:
		_set_room_type(room, Room.Type.TREASURE)

func _set_room_type(room: Room, type: Room.Type, extra_data: Variant = null) -> void:
	room.type = type
	room.original_type = type

	match type:
		Room.Type.MONSTER, Room.Type.BOSS:
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
