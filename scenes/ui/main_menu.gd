extends Control

const RUN_SCENE = preload("res://scenes/run/run.tscn")
const OPENING_SCENE = preload("res://scenes/narrative/opening.tscn")

@export var run_startup: RunStartup
@export var music: AudioStream
@onready var continue_button: Button = %Continue


func _ready() -> void:
	get_tree().paused = false
	MusicPlayer.play(music, true)
	continue_button.disabled = SaveGame.load_data() == null


## A new run starts with the camp opening (which then loads the run); a continued run
## goes straight to the run.
func scene_for(type: RunStartup.Type) -> PackedScene:
	return OPENING_SCENE if type == RunStartup.Type.NEW_RUN else RUN_SCENE


func _on_continue_pressed() -> void:
	run_startup.type = RunStartup.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(scene_for(run_startup.type))


func _on_new_run_pressed() -> void:
	run_startup.type = RunStartup.Type.NEW_RUN
	get_tree().change_scene_to_packed(scene_for(run_startup.type))


func _on_tutorial_pressed() -> void:
	Events.tutorial_requested.emit()


func _on_exit_pressed() -> void:
	get_tree().quit()
