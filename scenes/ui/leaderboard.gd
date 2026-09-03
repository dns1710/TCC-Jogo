extends Control

const ENTRY_SCENE = preload("res://scenes/ui/leaderboard_entry.tscn")

@onready var entries_container = %EntriesContainer
@onready var error_label = %ErrorLabel

func _ready():
	error_label.hide()
	await load_leaderboard()

func load_leaderboard():
	error_label.hide()

	for child in entries_container.get_children():
		child.queue_free()

	var response = await SupabaseService.get_top_scores()
	print("RESPONSE:", response)

	if not response.success:
		error_label.show()
		return

	var scores = response.data
	var rank := 1
	for data in scores:
		var entry = ENTRY_SCENE.instantiate()
		entry.get_node("Rank").text = "#" + str(rank)
		entry.get_node("Name").text = str(data["player_name"])
		entry.get_node("Score").text = str(data["score"])
		entries_container.add_child(entry)
		rank += 1

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
