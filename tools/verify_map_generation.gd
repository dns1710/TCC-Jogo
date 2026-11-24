extends Node
## Headless check of the map-generation spec.
## Run: Godot --headless --path . res://tools/verify_map_generation.tscn
## Exits 0 when every generated map satisfies the invariants, 1 otherwise.
## Must run as a scene (not --script) because the game scripts use autoloads.

const RUNS := 1000
const EXPECTED_FLOORS := 14
const EXPECTED_WIDTH := 3
const TREASURE_FLOOR := 6
const CAMPFIRE_FLOOR := 12
const BOSS_FLOOR := 13

const MAX_REPORTED := 10

var _failures: Array[String] = []


func _ready() -> void:
	var generator := MapGenerator.new()
	generator.battle_stats_pool = load("res://battles/battle_stats_pool.tres")
	generator.event_room_pool = load("res://scenes/event_rooms/event_room_pool.tres")
	add_child(generator) # _ready() sets up the battle pool weights

	for run in RUNS:
		var map_data: Array[Array] = generator.generate_map()
		_check_map(run, map_data)

	if _failures.is_empty():
		print("MAP CHECK OK: %d maps, 0 violations" % RUNS)
		get_tree().quit(0)
		return

	print("MAP CHECK FAILED: %d violations in %d maps" % [_failures.size(), RUNS])
	for i in mini(_failures.size(), MAX_REPORTED):
		print("  ", _failures[i])
	get_tree().quit(1)


func _fail(run: int, message: String) -> void:
	_failures.append("map %d: %s" % [run, message])


func _active_rooms(floor_rooms: Array) -> Array[Room]:
	var result: Array[Room] = []
	for room: Room in floor_rooms:
		if room.active:
			result.append(room)
	return result


func _check_map(run: int, map_data: Array[Array]) -> void:
	# Layout
	if map_data.size() != EXPECTED_FLOORS:
		_fail(run, "expected %d floors, got %d" % [EXPECTED_FLOORS, map_data.size()])
		return
	for floor_index in map_data.size():
		if map_data[floor_index].size() != EXPECTED_WIDTH:
			_fail(run, "floor %d has %d slots" % [floor_index, map_data[floor_index].size()])
			return

	var start_rooms := _active_rooms(map_data[0])
	if start_rooms.size() != 1 or start_rooms[0].column != EXPECTED_WIDTH / 2:
		_fail(run, "floor 0 must have exactly one active room in the middle slot")
		return
	var start: Room = start_rooms[0]

	# Reachability from the start room
	var reached: Dictionary = {start: true}
	var queue: Array[Room] = [start]
	while not queue.is_empty():
		var current: Room = queue.pop_front()
		for next_room: Room in current.next_rooms:
			if not reached.has(next_room):
				reached[next_room] = true
				queue.append(next_room)

	var boss_count := 0
	for floor_index in map_data.size():
		for room: Room in _active_rooms(map_data[floor_index]):
			if not reached.has(room):
				_fail(run, "unreachable active room at floor %d slot %d" % [floor_index, room.column])

			if room.type == Room.Type.BOSS:
				boss_count += 1
				if floor_index != BOSS_FLOOR or room.column != EXPECTED_WIDTH / 2:
					_fail(run, "boss at floor %d slot %d" % [floor_index, room.column])
				if room.battle_stats == null or room.battle_stats.battle_tier != 3:
					_fail(run, "boss without a tier-3 battle")
			elif floor_index < BOSS_FLOOR:
				# Dead ends: must connect forward to an active room on the next floor
				var has_forward := false
				for next_room: Room in room.next_rooms:
					if next_room.active and next_room.row == room.row + 1:
						has_forward = true
				if not has_forward:
					_fail(run, "dead end at floor %d slot %d" % [floor_index, room.column])

			# Connections only go to active rooms on the next floor
			for next_room: Room in room.next_rooms:
				if not next_room.active or next_room.row != room.row + 1:
					_fail(run, "bad connection from floor %d slot %d" % [floor_index, room.column])

	if boss_count != 1:
		_fail(run, "expected exactly 1 boss, got %d" % boss_count)

	# Paths never cross between consecutive floors
	for floor_index in range(map_data.size() - 1):
		var edges: Array[Vector2i] = []
		for room: Room in _active_rooms(map_data[floor_index]):
			for next_room: Room in room.next_rooms:
				edges.append(Vector2i(room.column, next_room.column))
		for a in edges.size():
			for b in range(a + 1, edges.size()):
				var e1 := edges[a]
				var e2 := edges[b]
				if (e1.x < e2.x and e1.y > e2.y) or (e1.x > e2.x and e1.y < e2.y):
					_fail(run, "crossing paths on floor %d: %s x %s" % [floor_index, e1, e2])

	# Fixed room types on key floors
	if start.type != Room.Type.MONSTER or start.battle_stats == null or start.battle_stats.battle_tier != 0:
		_fail(run, "start room must be a tier-0 monster battle")
	for room: Room in _active_rooms(map_data[CAMPFIRE_FLOOR]):
		if room.type != Room.Type.CAMPFIRE:
			_fail(run, "floor %d room is not a campfire" % CAMPFIRE_FLOOR)
	for room: Room in _active_rooms(map_data[TREASURE_FLOOR]):
		if room.type != Room.Type.TREASURE:
			_fail(run, "floor %d room is not a treasure room" % TREASURE_FLOOR)
