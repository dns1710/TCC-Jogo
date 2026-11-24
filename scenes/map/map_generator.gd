class_name MapGenerator
extends Node

const X_DIST := 50
const Y_DIST := 20
## Full jitter range per axis: a room is offset by up to half of it each way. X runs along the
## map (floors), Y across the lanes.
const PLACEMENT_RANDOMNESS := Vector2(20, 10)
const FLOORS := 14
const MAP_WIDTH := 7

## Rooms are never placed closer than this (room icons are 16 px).
const MIN_ROOM_DISTANCE := 14.0
## A connection line never passes closer than this to a room that is not one of its ends.
const LINE_CLEARANCE := 8.0
## Two lines that share a room must leave it at least this many degrees apart, so they never
## run on top of each other (dashed lines drawn over each other look like one broken line).
const MIN_BRANCH_ANGLE := 12.0
## Extra distance between the start and floor 1, and between the last campfire floor and the
## boss, so the lines that fan out of the start and into the boss are shallow, not steep.
const FRAME_GAP := 30.0
## The start fans out to, and the boss is fed from, only the lanes this far from the edges.
const FRAME_LANE_MARGIN := 1

# Layout rules (see the map-generation spec).
const START_BRANCHES := [3, 4]
const ROUTES_MIN := 4
const ROUTES_MAX := 6
const SPLIT_FLOORS_MAX := 8
const MIN_ACTIVE := 3
const MAX_ACTIVE := 5
const MIN_DISTINCT_ROUTES := 4
const MIN_SLOT_CHANGE_SHARE := 0.35
const MAX_ATTEMPTS := 60

# Step weights: diagonal, straight, diagonal; merging into an active room is favored.
const WEIGHT_DIAGONAL := 0.35
const WEIGHT_STRAIGHT := 0.30
const MERGE_BONUS := 1.6
const KNOWN_TARGET_PENALTY := 0.1

@export var battle_stats_pool: BattleStatsPool
@export var event_room_pool: EventRoomPool

var map_data: Array[Array]

## Statistics for tests: maps generated, total attempts, maps that kept an invalid layout.
var total_maps := 0
var total_attempts := 0
var fallbacks := 0


func _ready() -> void:
	battle_stats_pool.setup()

func generate_map(act: Act = null) -> Array[Array]:
	if act:
		battle_stats_pool = act.battle_stats_pool
		event_room_pool = act.event_room_pool
		battle_stats_pool.setup()

	var mid := int(MAP_WIDTH / 2)

	# Routes: regenerate until the layout rules hold (bounded).
	var attempts := 0
	var valid := false
	while not valid and attempts < MAX_ATTEMPTS:
		attempts += 1
		map_data = _generate_initial_grid()
		_build_routes()
		valid = _layout_is_valid()
	total_maps += 1
	total_attempts += attempts
	if not valid:
		fallbacks += 1
		push_warning("MapGenerator: kept a map that breaks the layout rules after %d attempts" % MAX_ATTEMPTS)

	_apply_positions()

	# Sala inicial
	var start_room: Room = map_data[0][mid]
	_set_room_type(
		start_room,
		Room.Type.MONSTER,
		battle_stats_pool.get_random_battle_for_tier(0)
	)

	var treasure_floor := int((FLOORS / 2)-1)
	var boss_campfire_floor := FLOORS - 2

	for floor in range(1, FLOORS - 1):
		for room in map_data[floor]:

			if not room.active:
				continue

			# Sala do meio sempre é tesouro
			if floor == treasure_floor:
				_set_room_type(room, Room.Type.TREASURE)
				continue

			# Sala antes do boss é sempre cura
			if floor == boss_campfire_floor:
				_set_room_type(room, Room.Type.CAMPFIRE)
				continue

			_assign_random_type(room)

	var boss_room: Room = map_data[FLOORS - 1][mid]

	_set_room_type(
		boss_room,
		Room.Type.BOSS,
		battle_stats_pool.get_random_battle_for_tier(3)
	)

	return map_data


# ---------------------------------------------------------------- routes

func _build_routes() -> void:
	var mid := int(MAP_WIDTH / 2)
	var last_floor := FLOORS - 2 # the pre-boss campfire floor; its rooms all connect to the boss

	var start_room: Room = map_data[0][mid]
	start_room.active = true

	# The start fans out to 3 or 4 distinct floor-1 slots.
	var lanes: Array[int] = []
	for i in range(FRAME_LANE_MARGIN, MAP_WIDTH - FRAME_LANE_MARGIN):
		lanes.append(i)
	lanes.shuffle()
	var branches: int = START_BRANCHES[randi() % START_BRANCHES.size()]
	var first_rooms: Array[Room] = []
	for i in branches:
		var room: Room = map_data[1][lanes[i]]
		room.active = true
		start_room.add_connection(room)
		first_rooms.append(room)

	# One walk from each branch, then extra walks that split off existing rooms.
	for room in first_rooms:
		_walk(room, last_floor, false)
	var routes := randi_range(ROUTES_MIN, ROUTES_MAX)
	for i in maxi(0, routes - branches):
		var origin := _random_active_room(1, SPLIT_FLOORS_MAX)
		if origin:
			_walk(origin, last_floor, true)

	var boss_room: Room = map_data[FLOORS - 1][mid]
	boss_room.active = true
	for room in map_data[last_floor]:
		if room.active:
			room.add_connection(boss_room)


## Walks from `room` to the last route floor, one connection per floor.
func _walk(room: Room, last_floor: int, prefer_new: bool) -> void:
	var current := room
	var first_step := true
	while current.row < last_floor:
		var column := _choose_column(current, prefer_new and first_step)
		var target: Room = map_data[current.row + 1][column]
		current.add_connection(target)
		target.active = true
		current = target
		first_step = false


## Picks the next slot for `room`: a neighboring slot (or the nearest allowed one) that cannot
## cross an existing connection between the same two floors.
func _choose_column(room: Room, prefer_new: bool) -> int:
	# Connections of rooms to the left must end at or before our target, rooms to the right
	# at or after it. This interval is never empty.
	var low := 0
	var high := MAP_WIDTH - 1
	# The floor that feeds the boss stays away from the outer lanes (shallow lines into the boss).
	if room.row + 1 == FLOORS - 2:
		low = FRAME_LANE_MARGIN
		high = MAP_WIDTH - 1 - FRAME_LANE_MARGIN
	for other: Room in map_data[room.row]:
		if not other.active or other == room:
			continue
		for target: Room in other.next_rooms:
			if other.column < room.column:
				low = maxi(low, target.column)
			else:
				high = mini(high, target.column)

	var options: Array[int] = []
	var weights: Array[float] = []
	for delta in [-1, 0, 1]:
		var column: int = room.column + delta
		if column < low or column > high or column < 0 or column >= MAP_WIDTH:
			continue
		var weight := WEIGHT_STRAIGHT if delta == 0 else WEIGHT_DIAGONAL
		var target: Room = map_data[room.row + 1][column]
		if target.active:
			weight *= MERGE_BONUS
		if prefer_new and room.next_rooms.has(target):
			weight *= KNOWN_TARGET_PENALTY
		options.append(column)
		weights.append(weight)

	if options.is_empty():
		return clampi(room.column, low, high)

	var total := 0.0
	for weight in weights:
		total += weight
	var roll := randf() * total
	for i in options.size():
		roll -= weights[i]
		if roll <= 0.0:
			return options[i]
	return options[options.size() - 1]


func _random_active_room(from_floor: int, to_floor: int) -> Room:
	var candidates: Array[Room] = []
	for floor in range(from_floor, to_floor + 1):
		for room: Room in map_data[floor]:
			if room.active:
				candidates.append(room)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]


# ---------------------------------------------------------------- validation

func _layout_is_valid() -> bool:
	var last_floor := FLOORS - 2
	var mid := int(MAP_WIDTH / 2)

	# Floors 1 to 12 are partly filled.
	for floor in range(1, last_floor + 1):
		var count := 0
		for room: Room in map_data[floor]:
			if room.active:
				count += 1
		if count < MIN_ACTIVE or count > MAX_ACTIVE:
			return false

	# Enough connections change slot, and no slot is a straight route from floor 1 to 12.
	var edges := 0
	var changing := 0
	for floor in range(1, last_floor):
		for room: Room in map_data[floor]:
			if not room.active:
				continue
			for target: Room in room.next_rooms:
				edges += 1
				if target.column != room.column:
					changing += 1
	if edges == 0 or float(changing) / float(edges) < MIN_SLOT_CHANGE_SHARE:
		return false
	for slot in MAP_WIDTH:
		var straight := true
		for floor in range(1, last_floor):
			var room: Room = map_data[floor][slot]
			var next_room: Room = map_data[floor + 1][slot]
			if not room.active or not next_room.active or not room.next_rooms.has(next_room):
				straight = false
				break
		if straight:
			return false

	# At least MIN_DISTINCT_ROUTES distinct routes from the start to the boss.
	var paths := {}
	paths[map_data[0][mid]] = 1
	for floor in range(0, FLOORS - 1):
		for room: Room in map_data[floor]:
			if not room.active:
				continue
			var here: int = paths.get(room, 0)
			for target: Room in room.next_rooms:
				paths[target] = paths.get(target, 0) + here
	return paths.get(map_data[FLOORS - 1][mid], 0) >= MIN_DISTINCT_ROUTES


# ---------------------------------------------------------------- placement

## Offsets every room from its grid position. Several layouts are tried, from full amplitude to
## none; the first one where no line crosses another or passes close to a room is kept. With no
## offset the grid always qualifies (lines are shallow and neighbors 20 px apart).
func _apply_positions() -> void:
	for amplitude: float in [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.8, 0.8, 0.8, 0.6, 0.6, 0.4, 0.4, 0.2, 0.0]:
		_place_rooms(amplitude)
		if _lines_are_clear():
			return


func _grid_position(floor: int, column: int) -> Vector2:
	var x := floor * X_DIST
	if floor == 0:
		x -= int(FRAME_GAP)
	elif floor == FLOORS - 1:
		x += int(FRAME_GAP)
	return Vector2(x, column * Y_DIST)


## A candidate that lands within MIN_ROOM_DISTANCE of an already placed room is retried and
## finally left on its grid position. The start and the boss are never offset.
func _place_rooms(amplitude: float) -> void:
	var placed: Array[Room] = []
	for floor in FLOORS:
		for room: Room in map_data[floor]:
			var grid := _grid_position(floor, room.column)
			room.position = grid
			if floor != 0 and floor != FLOORS - 1 and amplitude > 0.0:
				for attempt in 6:
					var offset := Vector2(randf() - 0.5, randf() - 0.5) * PLACEMENT_RANDOMNESS * amplitude
					if _far_enough(grid + offset, placed):
						room.position = grid + offset
						break
			placed.append(room)


func _far_enough(position: Vector2, placed: Array[Room]) -> bool:
	for other: Room in placed:
		# Rooms more than one floor away are always far apart.
		if position.x - other.position.x > MIN_ROOM_DISTANCE * 4.0:
			continue
		if position.distance_to(other.position) < MIN_ROOM_DISTANCE:
			return false
	return true


## True when no two connection lines intersect (except at a shared room) and no line passes
## within LINE_CLEARANCE of a room that is not one of its ends.
func _lines_are_clear() -> bool:
	for floor in range(0, FLOORS - 1):
		var edges: Array = []
		for room: Room in map_data[floor]:
			if not room.active:
				continue
			for target: Room in room.next_rooms:
				edges.append([room, target])
		for i in edges.size():
			var a: Room = edges[i][0]
			var b: Room = edges[i][1]
			for next_floor in [floor, floor + 1]:
				for other: Room in map_data[next_floor]:
					if not other.active or other == a or other == b:
						continue
					var closest := Geometry2D.get_closest_point_to_segment(other.position, a.position, b.position)
					if closest.distance_to(other.position) < LINE_CLEARANCE:
						return false
			for j in range(i + 1, edges.size()):
				var c: Room = edges[j][0]
				var d: Room = edges[j][1]
				if a == c or b == d:
					# Lines sharing a room must fan apart from it (no overlapping).
					var first := b.position - a.position
					var second := d.position - c.position
					if b == d:
						first = a.position - b.position
						second = c.position - d.position
					if rad_to_deg(absf(first.angle_to(second))) < MIN_BRANCH_ANGLE:
						return false
					continue
				if Geometry2D.segment_intersects_segment(a.position, b.position, c.position, d.position) != null:
					return false
	return true


func _assign_random_type(room: Room) -> void:
	var roll := randf()

	if roll < 0.57:
		_set_room_type(
			room,
			Room.Type.MONSTER,
			battle_stats_pool.get_random_battle_for_tier(1)
		)

	elif roll < 0.75:
		_set_room_type(
			room,
			Room.Type.EVENT,
			null
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
			room.position = _grid_position(i, j)

			row.append(room)

		result.append(row)

	return result
