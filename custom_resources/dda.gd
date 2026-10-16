class_name DDA
extends RefCounted

const MAX_SCORE := 100
const MIN_SCORE := 0

const LOW_SCORE_THRESHOLD := 50

func update_score_battle(current_health: int, max_health: int, run_stats: RunStats) -> void:
	if max_health <= 0:
		return
	
	var previous_score := run_stats.dda_score
	var score_change := 0
	
	#score baseado na % de hp ao fim do combate
	var hp_percentage := (float(current_health) / float(max_health)) * 100
	if hp_percentage <= 5:
		score_change -= 10
	elif hp_percentage <= 15:
		score_change -= 8
	elif hp_percentage <= 30:
		score_change -= 5
	elif hp_percentage <= 45:
		score_change -= 2
	elif hp_percentage >= 95:
		score_change += 10
	elif hp_percentage >= 85:
		score_change += 8
	elif hp_percentage >= 70:
		score_change += 5
	elif hp_percentage >= 55:
		score_change += 2
	
	run_stats.dda_score = clampi(previous_score + score_change, MIN_SCORE, MAX_SCORE)
