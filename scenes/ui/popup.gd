class_name PopUp
extends Label
## Floating combat text in the style of Fortnite damage numbers: the number pops out of the actor,
## drifts away from it while growing bigger, then fades. Popups of the same actor (the anchor) start
## a short time apart, so several hits or status names never land on top of each other, and they
## drift to alternating sides.

## Seconds between the starts of two popups of the same actor.
const STAGGER := 0.14
## Seconds the number takes to drift out and grow to full size.
const TRAVEL_TIME := 0.34
const HOLD_TIME := 0.35
const FADE_TIME := 0.3
const START_SCALE := 0.45
## How far (pixels) a popup drifts away from the actor, sideways and up.
const TRAVEL := Vector2(18.0, 18.0)
## Extra rise for every pair of popups of the same actor that are still on screen.
const LEVEL_RISE := 18.0

## anchor id -> live popups (waiting or showing).
static var _live := {}
## anchor id -> when (seconds, real time) the next popup of that actor may start.
static var _next_start := {}
## anchor id -> how many popups started, to alternate sides.
static var _started := {}

var _origin := Vector2.ZERO
var _anchor := 0
## The size this popup grows to.
var end_scale := 1.5
## Seconds this popup waits before it appears (0 for the first of a burst).
var start_delay := 0.0
## +1 drifts right, -1 left.
var side := 1.0

## How far the popup has drifted from where it spawned.
var offset := Vector2.ZERO : set = _set_offset
## Where this popup comes to rest while it is held, relative to where it spawned.
var drift := Vector2.ZERO


func setup(poptext: String, color: Color = Color.WHITE, anchor_id := 0) -> void:
	text = str(poptext)
	modulate = color

	reset_size()
	pivot_offset = size / 2.0
	global_position -= size / 2.0
	_origin = global_position
	_anchor = anchor_id

	# Same actor: wait for the previous popup's slot; a different actor starts at once.
	var now := Time.get_ticks_msec() / 1000.0
	var start := maxf(now, float(_next_start.get(anchor_id, 0.0)))
	_next_start[anchor_id] = start + STAGGER
	start_delay = start - now

	var index: int = _started.get(anchor_id, 0)
	_started[anchor_id] = index + 1
	side = 1.0 if index % 2 == 0 else -1.0

	var live: Array = _live.get(anchor_id, [])
	var level := live.size() / 2
	live.append(self)
	_live[anchor_id] = live
	tree_exiting.connect(_forget)

	# Bigger numbers grow bigger; names of statuses stay smaller so they stay readable.
	end_scale = 1.4 + clampf(float(text.to_int()) / 25.0, 0.0, 0.8) if text.is_valid_int() else 1.1

	# Visual randomness only: uses the global generator so the run's seeded RNG is untouched.
	var target := Vector2(side * TRAVEL.x * randf_range(0.7, 1.0), -TRAVEL.y * randf_range(0.7, 1.0) - level * LEVEL_RISE)

	drift = target
	var base_alpha := modulate.a
	modulate.a = 0.0
	scale = Vector2.ONE * START_SCALE
	var tween := create_tween()
	if start_delay > 0.0:
		tween.tween_interval(start_delay)
	# Pop out: appear, drift away from the actor and grow, overshooting a little.
	tween.tween_property(self, "modulate:a", base_alpha, 0.06)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * end_scale, TRAVEL_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "offset", target, TRAVEL_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_TIME)
	# Fade while still drifting.
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.parallel().tween_property(self, "offset", target * 1.25, FADE_TIME)
	tween.finished.connect(queue_free)


func _set_offset(value: Vector2) -> void:
	offset = value
	global_position = _origin + offset


func _forget() -> void:
	var live: Array = _live.get(_anchor, [])
	live.erase(self)
	if live.is_empty():
		_live.erase(_anchor)
		_started.erase(_anchor)
		_next_start.erase(_anchor)
