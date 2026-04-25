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
	# -------------------------------
	# FLOOR 0 → START (combat)
	# -------------------------------
	var start = map_data[0][mid]
	start.type = Room.Type.MONSTER

	start.battle_stats = battle_stats_pool.get_random_battle_for_tier(0)

	# 🔥 DEBUG + SAFETY (IMPORTANTE)
	if start.battle_stats == null:
		push_error("START ROOM SEM BATTLE_STATS (POOL RETORNOU NULL)")
		start.battle_stats = battle_stats_pool.get_random_battle_for_tier(0)

	print("START ROOM OK:", start, "BATTLE:", start.battle_stats)
	print("EVENT POOL:", event_room_pool)
	print("EVENT SAMPLE:", event_room_pool.get_random())
	# -------------------------------
	# FLOOR 1 → split (shop / event)
	# -------------------------------
	var left1 = map_data[1][mid - 1]
	var right1 = map_data[1][mid + 1]

	left1.type = Room.Type.SHOP
	right1.type = Room.Type.EVENT

	right1.event_scene = event_room_pool.get_random()

	start.connect_to([left1, right1])

	# -------------------------------
	# FLOOR 2 → combat
	# -------------------------------
	var combat2 = map_data[2][mid]
	combat2.type = Room.Type.MONSTER
	combat2.battle_stats = battle_stats_pool.get_random_battle_for_tier(1)

	if combat2.battle_stats == null:
		push_error("COMBAT2 SEM BATTLE_STATS")
		combat2.battle_stats = battle_stats_pool.get_random_battle_for_tier(1)

	left1.connect_to([combat2])
	right1.connect_to([combat2])

	# -------------------------------
	# FLOOR 3 → treasure
	# -------------------------------
	var treasure = map_data[3][mid]
	treasure.type = Room.Type.TREASURE

	combat2.connect_to([treasure])

	# -------------------------------
	# FLOOR 4 → split (event / rest)
	# -------------------------------
	var left2 = map_data[4][mid - 1]
	var right2 = map_data[4][mid + 1]

	left2.type = Room.Type.EVENT
	right2.type = Room.Type.CAMPFIRE
	
	left2.event_scene = event_room_pool.get_random()

	treasure.connect_to([left2, right2])

	# -------------------------------
	# FLOOR 5 → rest
	# -------------------------------
	var rest = map_data[5][mid]
	rest.type = Room.Type.CAMPFIRE

	left2.connect_to([rest])
	right2.connect_to([rest])

	# -------------------------------
	# FLOOR 6 → boss
	# -------------------------------
	var boss = map_data[6][mid]
	boss.type = Room.Type.BOSS
	boss.battle_stats = battle_stats_pool.get_random_battle_for_tier(2)

	if boss.battle_stats == null:
		push_error("BOSS SEM BATTLE_STATS")
		boss.battle_stats = battle_stats_pool.get_random_battle_for_tier(2)

	rest.connect_to([boss])

	return map_data


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
