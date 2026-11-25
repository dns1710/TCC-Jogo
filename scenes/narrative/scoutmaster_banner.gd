extends CanvasLayer
## Autoload. Shows a one-line scoutmaster remark when the difficulty adjustment changes
## rooms. Events.dda_adjusted records the direction; the remark appears when the room
## change becomes visible (Events.animation_dda_lock(true)). A remark that never got an
## animation is dropped at the next battle. Never takes the mouse: a click anywhere
## dismisses it without being consumed.

const LINES: ScoutmasterLines = preload("res://scenes/narrative/scoutmaster_lines.tres")
const PREFIX := "SCOUTMASTER: "
const FADE := 0.25
const HOLD := 3.0
## Pixels between the remark and the bottom edge of the 256x144 viewport.
const BOTTOM_MARGIN := 4

enum Pending {NONE, HARDER, EASIER}

var current_line := ""

var _pending := Pending.NONE
var _last_line := ""
var _panel: PanelContainer
var _label: Label
var _tween: Tween


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Bottom of the screen: the top holds the inventory and relic bar.
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -BOTTOM_MARGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.65)
	style.set_content_margin_all(3)
	_panel.add_theme_stylebox_override("panel", style)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_label)
	_panel.modulate.a = 0.0
	_panel.visible = false
	add_child(_panel)

	Events.dda_adjusted.connect(_on_dda_adjusted)
	Events.animation_dda_lock.connect(_on_animation_dda_lock)
	Events.battle_start.connect(_on_battle_start)


func is_showing() -> bool:
	return _panel.visible


## Hides the remark at once.
func dismiss() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_panel.visible = false
	_panel.modulate.a = 0.0


func _input(event: InputEvent) -> void:
	if _panel.visible and event is InputEventMouseButton and event.pressed:
		dismiss()


func _on_dda_adjusted(harder: bool) -> void:
	_pending = Pending.HARDER if harder else Pending.EASIER


func _on_animation_dda_lock(value: bool) -> void:
	if not value or _pending == Pending.NONE:
		return
	var pool: Array[String] = LINES.harder if _pending == Pending.HARDER else LINES.easier
	_pending = Pending.NONE
	_show(_pick(pool))


func _on_battle_start() -> void:
	_pending = Pending.NONE


func _pick(pool: Array[String]) -> String:
	var options := pool.filter(func(line: String): return line != _last_line)
	if options.is_empty():
		options = pool
	return options[randi() % options.size()]


func _show(line: String) -> void:
	dismiss()
	current_line = line
	_last_line = line
	_label.text = PREFIX + line
	_panel.visible = true
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, FADE)
	_tween.tween_interval(HOLD)
	_tween.tween_property(_panel, "modulate:a", 0.0, FADE)
	_tween.tween_callback(func(): _panel.visible = false)
