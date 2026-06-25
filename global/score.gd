extends Node

var score := 0

func _ready():
	Events.player_died.connect(_on_run_ended)

func reset_score():
	score = 0

func add_room_clear():
	score += 10

func add_gold(amount:int):
	score += amount

func add_run_victory():
	score += 100

func _on_run_ended():
	var player_name = "Player"# - " + Time.get_datetime_string_from_system()

	await SupabaseService.submit_score(
		player_name,
		Score.score
	)
	print(score)
	Score.reset_score()
