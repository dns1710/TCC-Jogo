class_name PopUp
extends Label
## Floating combat text. Popups that belong to the same actor (the anchor) cascade like a log:
## each new popup appears at the anchor and pushes the older ones up one line, so numbers
## and status names never sit on top of each other.

const LINE_HEIGHT := 12.0
const PUSH_TIME := 0.12
const HOLD_TIME := 0.55
const FADE_TIME := 0.4

## anchor id -> live popups, oldest first.
static var _live := {}

var _origin := Vector2.ZERO
var _anchor := 0
var _push_target := 0.0
var _push_tween: Tween

## Extra upward offset from being pushed by newer popups.
var push := 0.0 : set = _set_push


func setup(poptext: String, color: Color = Color.WHITE, anchor_id := 0) -> void:
	text = str(poptext)
	modulate = color

	reset_size()
	pivot_offset = size / 2.0
	global_position -= size / 2.0
	_origin = global_position
	_anchor = anchor_id

	var others: Array = _live.get(anchor_id, [])
	others = others.filter(func(p): return is_instance_valid(p))
	for other: PopUp in others:
		other.nudge()
	others.append(self)
	_live[anchor_id] = others
	tree_exiting.connect(_forget)

	modulate.a = 0.0
	scale = Vector2.ONE * 0.5
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.finished.connect(queue_free)


## Moves this popup up one line to make room for a newer one.
func nudge() -> void:
	_push_target += LINE_HEIGHT
	if _push_tween:
		_push_tween.kill()
	_push_tween = create_tween()
	_push_tween.tween_property(self, "push", _push_target, PUSH_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_push(value: float) -> void:
	push = value
	global_position = _origin + Vector2(0.0, -push)


func _forget() -> void:
	var list: Array = _live.get(_anchor, [])
	list.erase(self)
	if list.is_empty():
		_live.erase(_anchor)
