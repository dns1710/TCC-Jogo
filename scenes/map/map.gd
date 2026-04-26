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

var map_data: Array[Array] = []
var floors_climbed := 0
var last_room: Room = null
var camera_edge_y := 0.0

var dragging := false
var last_mouse_pos := Vector2.ZERO

var zoom_speed := 0.1
var min_zoom := 0.5
var max_zoom := 2.0


func _ready() -> void:
	camera_edge_y = MapGenerator.X_DIST * (MapGenerator.FLOORS - 1)
	hide_map()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Mouse press / release
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

	# Drag camera
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
	var view_size := get_viewport_rect().size

	camera_2d.position.x = clamp(
		camera_2d.position.x,
		-view_size.x,
		view_size.x
	)

	camera_2d.position.y = clamp(
		camera_2d.position.y,
		-camera_edge_y,
		camera_edge_y
	)


func generate_new_map() -> void:
	floors_climbed = 0
	last_room = null
	map_data = map_generator.generate_map()
	create_map()


func load_map(map: Array[Array], floors_completed: int, last_room_climbed: Room) -> void:
	floors_climbed = floors_completed
	map_data = map
	last_room = last_room_climbed

	create_map()

	if last_room == null:
		unlock_floor(0)
	else:
		unlock_next_rooms()


func create_map() -> void:
	_clear_map()

	if map_data.is_empty():
		return

	for current_floor: Array in map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
			var start_room = map_data[0][int(MapGenerator.MAP_WIDTH / 2)]
			camera_2d.position = start_room.position
			camera_2d.zoom = Vector2(0.8, 0.8)

	# Spawn boss room manually
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

	if not new_map_room.clicked.is_connected(_on_map_room_clicked):
		new_map_room.clicked.connect(_on_map_room_clicked)

	if not new_map_room.selected.is_connected(_on_map_room_selected):
		new_map_room.selected.connect(_on_map_room_selected)

	_connect_lines(room)

	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return

	for next_room: Room in room.next_rooms:
		var new_line := MAP_LINE.instantiate() as Line2D
		new_line.add_point(room.position)
		new_line.add_point(next_room.position)
		lines.add_child(new_line)


func _on_map_room_clicked(room: Room) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false


func _on_map_room_selected(room: Room) -> void:
	last_room = room
	floors_climbed += 1
	hide_map()
	Events.map_exited.emit(room)
