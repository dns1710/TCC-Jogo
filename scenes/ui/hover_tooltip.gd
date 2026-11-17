class_name HoverTooltip
extends PanelContainer

@export var hover_delay: float = 0.5
@export var mouse_offset := Vector2(12, 12)

@onready var title_label: Label = %TitleLabel
@onready var type_label: Label = %TypeLabel
@onready var description_label: RichTextLabel = %DescriptionLabel

var hover_timer: Timer

var pending_title: String
var pending_rarity: String
var pending_equip: String
var pending_description: String


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	hover_timer = Timer.new()
	hover_timer.one_shot = true
	hover_timer.wait_time = hover_delay
	add_child(hover_timer)

	hover_timer.timeout.connect(_on_hover_timer_timeout)


func show_tooltip(title: String, rarity: String, equip: String, description: String) -> void:
	pending_title = title.to_upper()
	pending_rarity = rarity
	pending_equip = equip
	pending_description = description
	hover_timer.start()


func hide_tooltip() -> void:
	hover_timer.stop()
	hide()


func _on_hover_timer_timeout() -> void:
	title_label.text = pending_title
	type_label.text = pending_rarity + " " + pending_equip
	description_label.text = pending_description
	
	match pending_rarity:
		"Common":
			type_label.modulate = Color.CORNFLOWER_BLUE
		"Uncommon":
			type_label.modulate = Color.ORANGE
		"Rare":
			type_label.modulate = Color.CRIMSON

	description_label.update_minimum_size()
	update_minimum_size()
	
	show()
	
	await get_tree().process_frame
	
	reset_size()
	_update_position()
	

func _process(_delta: float) -> void:
	if visible:
		_update_position()


func _update_position() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size := get_viewport_rect().size

	var new_pos := mouse_pos + mouse_offset

	new_pos.x = clampf(
		new_pos.x,
		0.0,
		maxf(0.0, viewport_size.x - size.x)
	)

	new_pos.y = clampf(
		new_pos.y,
		0.0,
		maxf(0.0, viewport_size.y - size.y)
	)

	position = new_pos
