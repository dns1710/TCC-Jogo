class_name Tooltip
extends PanelContainer

@export var hover_delay := 0.5
@export var mouse_offset := Vector2(8,8)

@onready var name_label: Label = %NameLabel
#@onready var text_label: Label = %TextLabel
@onready var text_label: RichTextLabel = %TooltipTextRich

var pending_title: String
var pending_description: String

var hover_timer: Timer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
	
	hover_timer = Timer.new()
	hover_timer.one_shot = true
	hover_timer.wait_time = hover_delay
	add_child(hover_timer)
	hover_timer.timeout.connect(_on_hover_timer_timeout)


func show_tooltip(title: String, description: String) -> void:
	pending_title = title
	pending_description = description
	hover_timer.start()
	

func hide_tooltip() -> void:
	hover_timer.stop()
	hide()


func _on_hover_timer_timeout() -> void:
	name_label.text = pending_title
	text_label.text = pending_description
	update_minimum_size()
	reset_size()
	_update_position()
	await get_tree().process_frame
	show()


func _update_tooltip_position() -> void:
	reset_size()
	_update_position()

func _process(_delta: float) -> void:
	if visible:
		_update_position()
		

func _update_position() -> void:
	var mouse_position := get_viewport().get_mouse_position()
	var viewport_size := get_viewport_rect().size
	var new_position := mouse_position + mouse_offset
	new_position.x = clampf(
		new_position.x,
		0.0,
		maxf(0.0, viewport_size.x - size.x)
	)
	new_position.y = clampf(
		new_position.y,
		0.0,
		maxf(0.0, viewport_size.y - size.y)
	)
	position = new_position
#@export var fade_seconds := 0.2

#@onready var tooltip_icon: TextureRect = %TooltipIcon
#@onready var tooltip_text_label: RichTextLabel = %TooltipText

#var tween: Tween
#var is_visible_now := false


#func _ready() -> void:
#	modulate = Color.TRANSPARENT
#	hide()


#func show_tooltip(icon: Texture, text: String) -> void:
#	is_visible_now = true
#	if tween:
#		tween.kill()
	
	#tooltip_icon.texture = icon
#	tooltip_text_label.text = text
#	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
#	tween.tween_callback(show)
#	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)


#func hide_tooltip() -> void:
#	is_visible_now = false
#	if tween:
#		tween.kill()

#	get_tree().create_timer(fade_seconds, false).timeout.connect(hide_animation)


#func hide_animation() -> void:
#	if not is_visible_now:
#		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
#		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
#		tween.tween_callback(hide)
