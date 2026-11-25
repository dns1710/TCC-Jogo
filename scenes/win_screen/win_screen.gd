class_name WinScreen
extends Control
## The ending sequence: the victory message, the storm ending, the scoutmaster epilogue,
## the portrait dimming as the scout falls asleep, then the exit button. One click or key
## jumps to the end state. Everything the sequence ends in is set by _apply_end_state(),
## which both the finished tween and skip() use.

signal finished

const MAIN_MENU_PATH = "res://scenes/ui/main_menu.tscn"
const MESSAGE := "The %s\nis victorious!"
const LINES: ScoutmasterLines = preload("res://scenes/narrative/scoutmaster_lines.tres")
const DIMMED := Color(0.35, 0.35, 0.5, 1.0)
const INPUT_GRACE := 0.4
const VICTORY_HOLD := 2.0
const NIGHT_FADE := 2.0
const LINE_FADE := 0.6
const LINE_HOLD := 0.9
const BUTTON_FADE := 0.5

@export var character: CharacterStats : set = set_character
## Tests turn this off to look at the screen before the sequence starts.
@export var autoplay := true
## Speeds the sequence up (tests only).
var time_scale := 1.0

var _tween: Tween
var _playing := false
var _finished := false
var _age := 0.0
var _epilogue_labels: Array[Label] = []

@onready var message: Label = %Message
@onready var character_portrait: TextureRect = %CharacterPortrait
@onready var _night: ColorRect = %Night
@onready var _rain: RainBackdrop = %RainBackdrop
@onready var _epilogue: VBoxContainer = %Epilogue
@onready var _button: Button = %MainMenuButton


func _ready() -> void:
	for line in LINES.epilogue:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.modulate.a = 0.0
		_epilogue.add_child(label)
		_epilogue_labels.append(label)
	_button.visible = false
	_button.modulate.a = 0.0
	_night.modulate.a = 0.0
	if autoplay:
		play()


func set_character(new_character: CharacterStats) -> void:
	character = new_character
	message.text = MESSAGE % character.character_name
	character_portrait.texture = character.portrait


## Starts the ending sequence.
func play() -> void:
	if _playing or _finished:
		return
	_playing = true
	_tween = create_tween()
	_tween.set_speed_scale(time_scale)
	_tween.tween_interval(VICTORY_HOLD)
	_tween.tween_callback(_rain.stop_rain.bind(NIGHT_FADE / maxf(time_scale, 0.01)))
	_tween.tween_property(_night, "modulate:a", 1.0, NIGHT_FADE)
	for i in _epilogue_labels.size():
		_tween.tween_property(_epilogue_labels[i], "modulate:a", 1.0, LINE_FADE)
		if i == _epilogue_labels.size() - 1:
			_tween.parallel().tween_property(character_portrait, "modulate", DIMMED, LINE_FADE * 2.0)
		_tween.tween_interval(LINE_HOLD)
	_tween.tween_property(_button, "modulate:a", 1.0, BUTTON_FADE).from(0.0)
	_tween.parallel().tween_callback(func(): _button.visible = true)
	_tween.tween_callback(_finish)


## Jumps to the end state. Safe to call at any time, including after the end.
func skip() -> void:
	if _finished:
		return
	if _tween:
		_tween.kill()
	_finish()


func is_raining() -> bool:
	return _rain.is_raining()


func exit_button() -> Button:
	return _button


func epilogue_line_count() -> int:
	return _epilogue_labels.size()


func epilogue_fully_shown() -> bool:
	for label in _epilogue_labels:
		if label.modulate.a < 0.99:
			return false
	return not _epilogue_labels.is_empty()


func portrait_dimmed() -> bool:
	return character_portrait.modulate.is_equal_approx(DIMMED)


func _process(delta: float) -> void:
	_age += delta


func _input(event: InputEvent) -> void:
	if _finished or _age < INPUT_GRACE:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo):
		get_viewport().set_input_as_handled()
		skip()


func _finish() -> void:
	if _finished:
		return
	_apply_end_state()
	_finished = true
	_playing = false
	finished.emit()


func _apply_end_state() -> void:
	_rain.stop_rain(0.0)
	_night.modulate.a = 1.0
	for label in _epilogue_labels:
		label.modulate.a = 1.0
	character_portrait.modulate = DIMMED
	_button.visible = true
	_button.modulate.a = 1.0


## The single exit of the ending (a scoring screen can redirect it later).
func exit() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_main_menu_button_pressed() -> void:
	exit()
