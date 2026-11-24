class_name TutorialOverlay
extends CanvasLayer
## The tutorial pages. Pauses the tree while open and restores the previous paused state
## on close. When a battle is on screen, pages point at the turn bar and the buttons.

signal closed

## target: "bar" (the player's turn bar), "attack", "block" or "" (nothing highlighted).
const PAGES := [
	{"title": "TURN BAR", "body": "The bar beside each fighter fills over time. When yours is full, it is your turn.", "target": "bar"},
	{"title": "ATTACK", "body": "Press ATTACK, then click an enemy to hit it.", "target": "attack"},
	{"title": "BLOCK", "body": "Press BLOCK to gain block. Block absorbs damage before health.", "target": "block"},
	{"title": "ENEMIES ACT TOO", "body": "When an enemy's bar fills, it acts. Defeat them all to win the battle.", "target": ""},
	{"title": "STATUSES", "body": "Icons under a fighter are statuses. Hover or click one to read what it does.", "target": ""},
]

var page := 0
var _was_paused := false
var _pulse: Tween

@onready var title_label: Label = %Title
@onready var body_label: Label = %Body
@onready var page_label: Label = %PageLabel
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton
@onready var skip_button: Button = %SkipButton
@onready var highlight: Panel = %Highlight


func _ready() -> void:
	back_button.pressed.connect(back)
	next_button.pressed.connect(next)
	skip_button.pressed.connect(close)


func open() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	page = 0
	_show_page()


func next() -> void:
	if page >= PAGES.size() - 1:
		close()
		return
	page += 1
	_show_page()


func back() -> void:
	if page > 0:
		page -= 1
		_show_page()


func close() -> void:
	if _pulse:
		_pulse.kill()
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	# Keeps the pause key from toggling the pause menu underneath.
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _show_page() -> void:
	var data: Dictionary = PAGES[page]
	title_label.text = data["title"]
	body_label.text = data["body"]
	page_label.text = "%d/%d" % [page + 1, PAGES.size()]
	back_button.disabled = page == 0
	next_button.text = "Done" if page == PAGES.size() - 1 else "Next"
	_update_highlight(data["target"])


func _update_highlight(target: String) -> void:
	if _pulse:
		_pulse.kill()
	var rect := _target_rect(target)
	highlight.visible = rect.size != Vector2.ZERO
	if not highlight.visible:
		return
	rect = rect.grow(1.0)
	highlight.position = rect.position
	highlight.size = rect.size
	highlight.modulate.a = 1.0
	_pulse = create_tween().set_loops()
	_pulse.tween_property(highlight, "modulate:a", 0.35, 0.5)
	_pulse.tween_property(highlight, "modulate:a", 1.0, 0.5)


## Screen rectangle of the element a page points at, or an empty rect when there is no
## battle on screen (for example when the tutorial is opened from the main menu).
func _target_rect(target: String) -> Rect2:
	var node: CanvasItem = null
	match target:
		"attack":
			node = get_tree().root.find_child("AttackButton", true, false) as CanvasItem
		"block":
			node = get_tree().root.find_child("BlockButton", true, false) as CanvasItem
		"bar":
			var player := get_tree().get_first_node_in_group("player")
			if player:
				node = player.get_node_or_null("ATBProgress") as CanvasItem
	if not node or not node.is_visible_in_tree() or not "size" in node:
		return Rect2()
	var xform := node.get_global_transform_with_canvas()
	return Rect2(xform.origin, node.size * xform.get_scale())
