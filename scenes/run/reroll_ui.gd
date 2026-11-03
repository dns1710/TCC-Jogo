extends CanvasLayer

@export var run_stats: RunStats : set = set_run_stats

@onready var reroll_label: Label = $RerollLabel


func _ready() -> void:
	reroll_label.text = str(run_stats.rerolls)


func set_run_stats(new_value: RunStats) -> void:
	run_stats = new_value
	
	if not run_stats.gold_changed.is_connected(_update_rerolls):
		run_stats.gold_changed.connect(_update_rerolls)
		_update_rerolls()


func _update_rerolls() -> void:
	reroll_label.text = str(run_stats.gold)
