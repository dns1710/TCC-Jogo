
class_name MapGenerator
extends Node

const X_DIST := 50
const Y_DIST := 35
const PLACEMENT_RANDOMNESS := 0

# Configuração das regiões
const FLOORS_PER_REGION := 13
const REGION_COUNT := 2
const FLOORS := FLOORS_PER_REGION * REGION_COUNT

const MAP_WIDTH := 3

@export var battle_stats_pool: BattleStatsPool
@export var event_room_pool: EventRoomPool

var map_data: Array[Array]


func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()

	battle_stats_pool.setup()

	# Primeira região: andares 0 até 12
	_generate_region(
		0,
		FLOORS_PER_REGION - 1
	)

	# Segunda região: andares 13 até 25
	# O primeiro Boss conecta à entrada da segunda região.
	var first_boss: Room = map_data[FLOORS_PER_REGION - 1][int(MAP_WIDTH / 2)]

	_generate_region(
		FLOORS_PER_REGION,
		FLOORS - 1,
		first_boss
	)

	return map_data


func _generate_region(
	start_floor: int,
	boss_floor: int,
	previous_boss: Room = null
) -> void:

	var mid := int(MAP_WIDTH / 2)

	# Sala inicial da região
	var start_room: Room = map_data[start_floor][mid]
	start_room.active = true

	_set_room_type(
		start_room,
		Room.Type.MONSTER,
		battle_stats_pool.get_random_battle_for_tier(0)
	)

	# Conecta a região anterior à nova região
	if previous_boss != null:
		previous_boss.add_connection(start_room)

	# Cria os três caminhos iniciais
	var initial_floor := start_floor + 1
	var current_rooms: Array[Room] = []

	for column in range(MAP_WIDTH):
		var room: Room = map_data[initial_floor][column]

		start_room.add_connection(room)
		room.active = true

		current_rooms.append(room)

	# Geração das ramificações
	for floor in range(initial_floor, boss_floor - 1):
		var next_rooms: Array[Room] = []
		var floor_connections := []

		for room in current_rooms:

			var possible_columns: Array[int] = [room.column]

			# Chance de abrir caminho para cima
			if room.column > 0 and randf() < 0.35:
				possible_columns.append(room.column - 1)

			# Chance de abrir caminho para baixo
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

	# Distribuição dos tipos de sala
	# Cada região possui seu próprio andar de tesouro.
	var treasure_floor := start_floor + int(FLOORS_PER_REGION / 2)

	for floor in range(initial_floor, boss_floor):
		for room in map_data[floor]:

			if not room.active:
				continue

			if floor == treasure_floor:
				_set_room_type(room, Room.Type.TREASURE)
				continue

			_assign_random_type(room)

	# Boss da região
	var boss_room: Room = map_data[boss_floor][mid]

	boss_room.active = true

	_set_room_type(
		boss_room,
		Room.Type.BOSS,
		battle_stats_pool.get_random_battle_for_tier(2)
	)

	# Conecta os últimos caminhos ao Boss
	for room in current_rooms:
		room.add_connection(boss_room)


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


func _set_room_type(
	room: Room,
	type: Room.Type,
	extra_data: Variant = null
) -> void:
	room.type = type
	room.original_type = type

	match type:
		Room.Type.MONSTER, Room.Type.BOSS:
			room.battle_stats = extra_data

		Room.Type.EVENT:
			room.event_scene = extra_data


func _generate_initial_grid() -> Array[Array]:
	var result: Array[Array] = []

	for i in range(FLOORS):
		var row: Array[Room] = []

		for j in range(MAP_WIDTH):
			var room := Room.new()

			room.row = i
			room.column = j

			var offset := Vector2(randf(), randf()) * PLACEMENT_RANDOMNESS
			room.position = Vector2(i * X_DIST, j * Y_DIST) + offset

			row.append(room)

		result.append(row)

	return result
