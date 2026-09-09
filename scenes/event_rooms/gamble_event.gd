extends EventRoom

@onready var fifty_button: EventRoomButton = %FiftyButton
@onready var allin_button: EventRoomButton = %AllInButton
@onready var skip_button: EventRoomButton = %SkipButton


func setup() -> void:
	#skip_button.visible = run_stats.gold < 50
	fifty_button.disabled = run_stats.gold < 50
	allin_button.disabled = run_stats.gold < 1
	
	fifty_button.event_button_callback = bet_50
	allin_button.event_button_callback = bet_allin

func bet_50() -> void:
	fifty_button.disabled = true
	run_stats.gold -= 50
	
	if RNG.instance.randf() < 0.5:
		run_stats.gold += 100

func bet_allin() -> void:
	var bet_all_in: = run_stats.gold
	allin_button.disabled = true
	run_stats.gold = 0
	
	if RNG.instance.randf() < 0.5:
		run_stats.gold = bet_all_in * 2
