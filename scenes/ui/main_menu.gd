extends Control

const RUN_SCENE = preload("res://scenes/run/run.tscn")
const LEADERBOARD_SCENE = preload("res://scenes/ui/leaderboard.tscn")

@export var run_startup: RunStartup
@export var music: AudioStream
@onready var continue_button: Button = %Continue


func _ready() -> void:
	get_tree().paused = false
	MusicPlayer.play(music, true)
	continue_button.disabled = SaveGame.load_data() == null


func _on_continue_pressed() -> void:
	run_startup.type = RunStartup.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_new_run_pressed() -> void:
	run_startup.type = RunStartup.Type.NEW_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_packed(LEADERBOARD_SCENE)
	

func _on_exit_pressed() -> void:
	get_tree().quit()
