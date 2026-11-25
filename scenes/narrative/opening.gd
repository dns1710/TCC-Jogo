class_name Opening
extends Control
## The camp opening shown before a New Run: rain, a few lines revealed one at a time.
## One click or key press ends it. Then it starts the run.

signal finished

const RUN_SCENE := preload("res://scenes/run/run.tscn")
const LINES: ScoutmasterLines = preload("res://scenes/narrative/scoutmaster_lines.tres")
const INPUT_GRACE := 0.3
const FADE := 0.6
const GAP := 0.9
const HOLD := 1.2

## Tests turn this off so finishing does not change scene.
var auto_start_run := true

var _done := false
var _age := 0.0
var _tween: Tween
var _labels: Array[Label] = []

@onready var _lines_box: VBoxContainer = %Lines


func _ready() -> void:
	for line in LINES.opening:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate.a = 0.0
		_lines_box.add_child(label)
		_labels.append(label)
	_tween = create_tween()
	for label in _labels:
		_tween.tween_property(label, "modulate:a", 1.0, FADE)
		_tween.tween_interval(GAP)
	_tween.tween_interval(HOLD)
	_tween.tween_callback(skip)


func line_count() -> int:
	return _labels.size()


func _process(delta: float) -> void:
	_age += delta


func _input(event: InputEvent) -> void:
	if _age < INPUT_GRACE:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo):
		get_viewport().set_input_as_handled()
		skip()


## Ends the opening now. Safe to call more than once.
func skip() -> void:
	if _done:
		return
	_done = true
	if _tween:
		_tween.kill()
	finished.emit()
	if auto_start_run:
		get_tree().change_scene_to_packed(RUN_SCENE)
