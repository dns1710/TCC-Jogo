class_name Map
extends Node2D

const SCROLL_SPEED := 15.0
const MAP_ROOM := preload("res://scenes/map/map_room.tscn")
const MAP_LINE := preload("res://scenes/map/map_line.tscn")

@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D

# ✅ botão agora dentro do Map
@onready var reroll_button = get_node_or_null("Reroll/RerollButton")

var map_data: Array[Array] = []
var floors_climbed := 0
var last_room: Room = null
var camera_edge_y := 0.0

var dragging := false
var last_mouse_pos := Vector2.ZERO

var zoom_speed := 0.1
var min_zoom := 0.5
var max_zoom := 2.0
var camera_edge_x := 0.0
var reroll_mode := false


func _ready() -> void:
	add_to_group("map")

	camera_edge_x = MapGenerator.Y_DIST * (MapGenerator.MAP_WIDTH - 1)
	hide_map()
	
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_button_pressed)
	else:
		push_warning("RerollButton não encontrado!")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				dragging = event.pressed
				last_mouse_pos = event.position

			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_camera(zoom_speed)

			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_camera(-zoom_speed)

	elif event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.position - last_mouse_pos
		camera_2d.position -= delta
		last_mouse_pos = event.position
		_clamp_camera()


func _zoom_camera(amount: float) -> void:
	var new_zoom := camera_2d.zoom + Vector2(amount, amount)

	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)

	camera_2d.zoom = new_zoom
	_clamp_camera()


func _clamp_camera() -> void:
	var min_x = 0
	var max_x = MapGenerator.X_DIST * (MapGenerator.FLOORS - 1)

	var min_y = 0
	var max_y = MapGenerator.Y_DIST * (MapGenerator.MAP_WIDTH - 1)

	camera_2d.position.x = clamp(camera_2d.position.x, min_x, max_x)
	camera_2d.position.y = clamp(camera_2d.position.y, min_y, max_y)


func generate_new_map() -> void:
	floors_climbed = 0
	last_room = null
	map_data = map_generator.generate_map()
	create_map()


func load_map(map: Array[Array], floors_completed: int, last_room_climbed: Room) -> void:
	floors_climbed = floors_completed
	last_room = last_room_climbed
	map_data = map

	create_map()

	if last_room == null:
		unlock_floor(0)
	else:
		unlock_next_rooms()


func create_map() -> void:
	_clear_map()

	if map_data.is_empty():
		return

	for current_floor in map_data:
		for room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)

	# câmera inicial
	var start_room = map_data[0][int(MapGenerator.MAP_WIDTH / 2)]
	camera_2d.position = start_room.position
	camera_2d.zoom = Vector2(0.8, 0.8)
	
	# boss
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	var boss_room: Room = map_data[MapGenerator.FLOORS - 1][middle]
	_spawn_room(boss_room)

	visuals.position.y = get_viewport_rect().size.y / 2.0


func _clear_map() -> void:
	for child in rooms.get_children():
		child.queue_free()

	for child in lines.get_children():
		child.queue_free()


func unlock_floor(which_floor: int = floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		map_room.available = map_room.room.row == which_floor


func unlock_next_rooms() -> void:
	if last_room == null:
		unlock_floor(0)
		return

	for map_room: MapRoom in rooms.get_children():
		map_room.available = last_room.next_rooms.has(map_room.room)


func show_map() -> void:
	show()
	camera_2d.enabled = true

	if last_room == null:
		unlock_floor(0)
	else:
		unlock_next_rooms()


func hide_map() -> void:
	hide()
	camera_2d.enabled = false
	dragging = false


func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)

	new_map_room.room = room

	new_map_room.clicked.connect(_on_map_room_clicked)
	new_map_room.selected.connect(_on_map_room_selected)

	_connect_lines(room)

	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return

	for next_room in room.next_rooms:
		var new_line := MAP_LINE.instantiate() as Line2D
		new_line.add_point(room.position)
		new_line.add_point(next_room.position)
		lines.add_child(new_line)


func _on_map_room_clicked(room: Room) -> void:
	if reroll_mode:
		_reroll_room(room)
		reroll_mode = false
		_update_reroll_visuals()
		return

	for map_room in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false


func _on_map_room_selected(room: Room) -> void:
	last_room = room
	floors_climbed += 1
	hide_map()
	Events.map_exited.emit(room)


func _on_reroll_button_pressed() -> void:
	reroll_mode = true
	_update_reroll_visuals()


func _update_reroll_visuals() -> void:
	for map_room in rooms.get_children():
		map_room.set_reroll_highlight(reroll_mode)


func _reroll_room(room: Room) -> void:
	if room.row < floors_climbed:
		return

	if room.type == Room.Type.BOSS:
		return

	var types = [
		Room.Type.MONSTER,
		Room.Type.EVENT,
		Room.Type.SHOP,
		Room.Type.CAMPFIRE
	]

	var pool = []

	for t in types:
		if t != room.original_type:
			pool.append(t)

	room.type = pool.pick_random()

	match room.type:
		Room.Type.MONSTER:
			room.battle_stats = map_generator.battle_stats_pool.get_random_battle_for_tier(1)

		Room.Type.EVENT:
			room.event_scene = map_generator.event_room_pool.get_random()

	for map_room in rooms.get_children():
		if map_room.room == room:
			map_room.update_visual()
