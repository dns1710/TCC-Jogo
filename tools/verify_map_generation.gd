extends Node
## Headless check of the map-generation spec.
## Run: Godot --headless --path . res://tools/verify_map_generation.tscn
## Exits 0 when every generated map satisfies the invariants, 1 otherwise.
## Must run as a scene (not --script) because the game scripts use autoloads.

const RUNS := 1000
const ACT_PATHS := [
	"res://acts/act_1_forest.tres",
	"res://acts/act_2_ice.tres",
	"res://acts/act_3_fire.tres",
]
const EXPECTED_FLOORS := 14
const EXPECTED_WIDTH := 7
const TREASURE_FLOOR := 6
const CAMPFIRE_FLOOR := 12
const BOSS_FLOOR := 13
const MIN_ROOM_DISTANCE := 14.0
const MIN_ACTIVE := 3
const MAX_ACTIVE := 5
const MIN_ROUTES := 4
const MIN_SLOT_CHANGE_SHARE := 0.35

const MAX_REPORTED := 10

var _failures: Array[String] = []


func _ready() -> void:
	var generator := MapGenerator.new()
	generator.battle_stats_pool = load("res://battles/battle_stats_pool.tres")
	generator.event_room_pool = load("res://scenes/event_rooms/event_room_pool.tres")
	add_child(generator) # _ready() sets up the battle pool weights

	for act_path in ACT_PATHS:
		var act: Act = load(act_path)
		for run in RUNS:
			var map_data: Array[Array] = generator.generate_map(act)
			_check_map(run, map_data)
			_check_act_pools(run, map_data, act)

	var share := float(_event_rooms) / maxf(1.0, _random_rooms)
	if absf(share - 0.18) > 0.02:
		_failures.append("event share %.3f is not 18%% (+-2 points)" % share)

	await _check_legacy_map()
	print("average active rooms per map: %.1f" % (float(_active_rooms_total) / float(RUNS * ACT_PATHS.size())))

	print("map layout: %d maps, generator retries %.2f per map, %d fell back after the attempt limit" % [
		RUNS * ACT_PATHS.size(), float(generator.total_attempts) / float(generator.total_maps), generator.fallbacks])
	if generator.fallbacks > 0:
		_failures.append("%d maps hit the regeneration limit" % generator.fallbacks)

	if _failures.is_empty():
		print("MAP CHECK OK: %d maps per act x %d acts, 0 violations" % [RUNS, ACT_PATHS.size()])
		get_tree().quit(0)
		return

	print("MAP CHECK FAILED: %d violations in %d maps" % [_failures.size(), RUNS])
	for i in mini(_failures.size(), MAX_REPORTED):
		print("  ", _failures[i])
	get_tree().quit(1)


func _fail(run: int, message: String) -> void:
	_failures.append("map %d: %s" % [run, message])


var _random_rooms := 0
var _event_rooms := 0
var _active_rooms_total := 0


func _count_random_rooms(map_data: Array[Array]) -> void:
	for floor_rooms in map_data:
		_active_rooms_total += _active_rooms(floor_rooms).size()
	for floor_index in range(1, BOSS_FLOOR - 1):
		if floor_index == TREASURE_FLOOR or floor_index == CAMPFIRE_FLOOR:
			continue
		for room: Room in _active_rooms(map_data[floor_index]):
			_random_rooms += 1
			if room.type == Room.Type.EVENT:
				_event_rooms += 1


func _check_act_pools(run: int, map_data: Array[Array], act: Act) -> void:
	_count_random_rooms(map_data)
	for floor_rooms in map_data:
		for room: Room in _active_rooms(floor_rooms):
			if room.battle_stats != null and not act.battle_stats_pool.pool.has(room.battle_stats):
				_fail(run, "%s: battle from outside the act pool" % act.act_name)
			if room.event_scene != null:
				_fail(run, "%s: events must be chosen on entry, not baked into rooms" % act.act_name)
			if act.event_room_pool == null or act.event_room_pool.events.is_empty():
				_fail(run, "%s: act has no event pool" % act.act_name)


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

	_check_layout(run, map_data, start)

	# Fixed room types on key floors
	if start.type != Room.Type.MONSTER or start.battle_stats == null or start.battle_stats.battle_tier != 0:
		_fail(run, "start room must be a tier-0 monster battle")
	for room: Room in _active_rooms(map_data[CAMPFIRE_FLOOR]):
		if room.type != Room.Type.CAMPFIRE:
			_fail(run, "floor %d room is not a campfire" % CAMPFIRE_FLOOR)
	for room: Room in _active_rooms(map_data[TREASURE_FLOOR]):
		if room.type != Room.Type.TREASURE:
			_fail(run, "floor %d room is not a treasure room" % TREASURE_FLOOR)


func _check_layout(run: int, map_data: Array[Array], start: Room) -> void:
	# The start fans out to 3 or 4 rooms.
	if start.next_rooms.size() < 3 or start.next_rooms.size() > 4:
		_fail(run, "start has %d connections, expected 3 or 4" % start.next_rooms.size())

	# Floors 1 to 12 are partly filled.
	for floor_index in range(1, CAMPFIRE_FLOOR + 1):
		var count := _active_rooms(map_data[floor_index]).size()
		if count < MIN_ACTIVE or count > MAX_ACTIVE:
			_fail(run, "floor %d has %d active rooms, expected %d to %d" % [floor_index, count, MIN_ACTIVE, MAX_ACTIVE])

	# No straight-lane route, and enough slot changes. Edges between floors 1 and 12 only.
	var edges := 0
	var changing := 0
	for floor_index in range(1, CAMPFIRE_FLOOR):
		for room: Room in _active_rooms(map_data[floor_index]):
			for next_room: Room in room.next_rooms:
				edges += 1
				if next_room.column != room.column:
					changing += 1
	if edges > 0 and float(changing) / float(edges) < MIN_SLOT_CHANGE_SHARE:
		_fail(run, "only %d of %d connections change slot" % [changing, edges])
	for slot in EXPECTED_WIDTH:
		var straight := true
		for floor_index in range(1, CAMPFIRE_FLOOR):
			var room: Room = map_data[floor_index][slot]
			var next_room: Room = map_data[floor_index + 1][slot]
			if not room.active or not next_room.active or not room.next_rooms.has(next_room):
				straight = false
				break
		if straight:
			_fail(run, "slot %d is a straight route from floor 1 to floor 12" % slot)

	# At least MIN_ROUTES distinct routes from the start to the boss (path counts per room).
	var paths := {}
	paths[start] = 1
	for floor_index in range(0, BOSS_FLOOR):
		for room: Room in _active_rooms(map_data[floor_index]):
			var here: int = paths.get(room, 0)
			for next_room: Room in room.next_rooms:
				paths[next_room] = paths.get(next_room, 0) + here
	var boss: Room = map_data[BOSS_FLOOR][EXPECTED_WIDTH / 2]
	if paths.get(boss, 0) < MIN_ROUTES:
		_fail(run, "only %d routes reach the boss" % paths.get(boss, 0))

	# Lines: none crosses another, none passes close to a room that is not one of its ends, and
	# the start and the pre-boss floor stay off the outer lanes (shallow lines).
	for floor_index in range(0, BOSS_FLOOR):
		var segs: Array = []
		for room: Room in _active_rooms(map_data[floor_index]):
			for next_room: Room in room.next_rooms:
				segs.append([room, next_room])
		for i in segs.size():
			var a: Room = segs[i][0]
			var b: Room = segs[i][1]
			for fl in [floor_index, floor_index + 1]:
				for other: Room in _active_rooms(map_data[fl]):
					if other == a or other == b:
						continue
					var cp := Geometry2D.get_closest_point_to_segment(other.position, a.position, b.position)
					if cp.distance_to(other.position) < MapGenerator.LINE_CLEARANCE - 0.001:
						_fail(run, "line %d/%d to %d/%d passes %.1f px from room %d/%d" % [a.row, a.column, b.row, b.column, cp.distance_to(other.position), other.row, other.column])
			for j in range(i + 1, segs.size()):
				var c: Room = segs[j][0]
				var d: Room = segs[j][1]
				if a == c or b == d:
					# Lines that share a room may only touch there: they must fan apart.
					var first := b.position - a.position
					var second := d.position - c.position
					if b == d:
						first = a.position - b.position
						second = c.position - d.position
					var angle := rad_to_deg(absf(first.angle_to(second)))
					if angle < MapGenerator.MIN_BRANCH_ANGLE - 0.001:
						_fail(run, "lines sharing a room overlap (%.1f degrees apart) on floor %d: %d->%d and %d->%d" % [angle, floor_index, a.column, b.column, c.column, d.column])
					continue
				if Geometry2D.segment_intersects_segment(a.position, b.position, c.position, d.position) != null:
					_fail(run, "lines cross visually on floor %d: %d->%d and %d->%d" % [floor_index, a.column, b.column, c.column, d.column])
	for room: Room in start.next_rooms:
		if room.column < MapGenerator.FRAME_LANE_MARGIN or room.column > EXPECTED_WIDTH - 1 - MapGenerator.FRAME_LANE_MARGIN:
			_fail(run, "start connects to outer lane %d" % room.column)
	for room: Room in _active_rooms(map_data[CAMPFIRE_FLOOR]):
		if room.column < MapGenerator.FRAME_LANE_MARGIN or room.column > EXPECTED_WIDTH - 1 - MapGenerator.FRAME_LANE_MARGIN:
			_fail(run, "pre-boss floor uses outer lane %d" % room.column)

	# Organic placement: offsets inside the allowed range, active rooms never touching.
	var half := MapGenerator.PLACEMENT_RANDOMNESS / 2.0
	var active: Array[Room] = []
	for floor_index in map_data.size():
		for room: Room in map_data[floor_index]:
			var grid := Vector2(floor_index * MapGenerator.X_DIST, room.column * MapGenerator.Y_DIST)
			if floor_index == 0:
				grid.x -= MapGenerator.FRAME_GAP
			elif floor_index == BOSS_FLOOR:
				grid.x += MapGenerator.FRAME_GAP
			var offset := room.position - grid
			if absf(offset.x) > half.x + 0.001 or absf(offset.y) > half.y + 0.001:
				_fail(run, "room %d/%d is offset by %s, beyond %s" % [floor_index, room.column, offset, half])
			if room.active:
				active.append(room)
	for a in active.size():
		for b in range(a + 1, active.size()):
			if active[a].position.distance_to(active[b].position) < MIN_ROOM_DISTANCE:
				_fail(run, "rooms %d/%d and %d/%d are closer than %d px" % [active[a].row, active[a].column, active[b].row, active[b].column, int(MIN_ROOM_DISTANCE)])


## A run saved with an older 3-slot map must still open (continued runs keep their map).
func _check_legacy_map() -> void:
	var legacy: Array[Array] = []
	for floor_index in 5:
		var row: Array[Room] = []
		for slot in 3:
			var room := Room.new()
			room.row = floor_index
			room.column = slot
			room.position = Vector2(floor_index * 50, slot * 35)
			room.active = floor_index == 0 and slot == 1 or floor_index > 0
			room.type = Room.Type.MONSTER
			row.append(room)
		legacy.append(row)
	for floor_index in 4:
		for room: Room in legacy[floor_index]:
			room.add_connection(legacy[floor_index + 1][room.column])
	var map: Map = load("res://scenes/map/map.tscn").instantiate()
	add_child(map)
	await get_tree().process_frame
	map.set_act(load(ACT_PATHS[0]))
	map.load_map(legacy, 0, null)
	await get_tree().process_frame
	if map.map_camera_start_position != legacy[0][1].position:
		_failures.append("a saved 3-slot map must still open and centre on its start room")
	map.queue_free()
