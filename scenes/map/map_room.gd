class_name MapRoom
extends Area2D

signal clicked(room: Room)
signal selected(room: Room)

const ICONS := {
	Room.Type.NOT_ASSIGNED: [null, Vector2.ONE],
	Room.Type.MONSTER: [preload("res://art/tile_0103.png"), Vector2.ONE],
	Room.Type.TREASURE: [preload("res://art/tile_0089.png"), Vector2.ONE],
	Room.Type.CAMPFIRE: [preload("res://art/player_heart.png"), Vector2(0.6, 0.6)],
	Room.Type.SHOP: [preload("res://art/gold.png"), Vector2(0.6, 0.6)],
	Room.Type.BOSS: [preload("res://art/tile_0105.png"), Vector2(1.25, 1.25)],
	Room.Type.EVENT: [preload("res://art/rarity.png"), Vector2(0.9, 0.9)],
}

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false : set = set_available
var room: Room : set = set_room


func set_available(new_value: bool) -> void:
	available = new_value

	if available:
		animation_player.play("highlight")
	elif not room.selected:
		animation_player.play("RESET")


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(0, 360)
	update_visual()


func show_selected() -> void:
	line_2d.modulate = Color.WHITE


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event.is_action_pressed("left_mouse"):
		return

	var map = get_tree().get_first_node_in_group("map")
	if map == null:
		return

	# 🎲 REROLL MODE
	if map.reroll_mode:
		clicked.emit(room)
		return

	# 🎮 NORMAL
	if not available:
		return

	room.selected = true
	clicked.emit(room)
	animation_player.play("select")


func _on_map_room_selected() -> void:
	selected.emit(room)


func update_visual() -> void:
	if not ICONS.has(room.type):
		return

	sprite_2d.texture = ICONS[room.type][0]
	sprite_2d.scale = ICONS[room.type][1]


func set_reroll_highlight(active: bool) -> void:
	if active:
		modulate = Color(1.2, 1.2, 0.9)
	else:
		modulate = Color(1, 1, 1)
