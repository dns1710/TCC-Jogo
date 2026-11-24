class_name EventChoice
extends Resource
## A button the player can press in an event, with its price and possible results.

enum CheckStat {NONE, ATTACK, BLOCK, SPEED}

@export var label := ""

@export_group("Cost")
@export var cost_gold := 0
@export var cost_hp := 0
@export var cost_rerolls := 0
## Bets everything the player has; outcomes can pay out with bet_multiplier.
@export var all_in := false

@export_group("Stat check")
## With a stat check, outcomes[0] is success and outcomes[1] is failure.
@export var check_stat: CheckStat = CheckStat.NONE
@export_range(0.0, 1.0) var check_base := 0.0
@export_range(0.0, 1.0) var check_per_point := 0.0

@export_group("Results")
@export var outcomes: Array[EventOutcome] = []


func bet(run: RunStats) -> int:
	return run.gold if all_in else cost_gold


func can_afford(stats: CharacterStats, run: RunStats) -> bool:
	if all_in and run.gold < 1:
		return false
	if run.gold < cost_gold:
		return false
	if cost_hp > 0 and stats.health - cost_hp < 1:
		return false
	return run.rerolls >= cost_rerolls


func check_chance(stats: CharacterStats) -> float:
	var value := 0
	match check_stat:
		CheckStat.ATTACK:
			value = stats.max_attack
		CheckStat.BLOCK:
			value = stats.max_block
		CheckStat.SPEED:
			value = stats.max_speed
		_:
			return 1.0
	return clampf(check_base + check_per_point * value, 0.0, 1.0)


func pick_outcome(stats: CharacterStats) -> EventOutcome:
	if outcomes.is_empty():
		return null

	if check_stat != CheckStat.NONE and outcomes.size() >= 2:
		return outcomes[0] if RNG.instance.randf() < check_chance(stats) else outcomes[1]

	var total := 0.0
	for outcome in outcomes:
		total += outcome.weight
	var roll := RNG.instance.randf_range(0.0, total)
	for outcome in outcomes:
		roll -= outcome.weight
		if roll < 0.0:
			return outcome
	return outcomes[outcomes.size() - 1]


## Takes the price and returns the lines to show for it.
func pay(event: EventRoom) -> Array[String]:
	var lines: Array[String] = []
	var spent := bet(event.run_stats)
	if spent > 0:
		event.run_stats.gold -= spent
		lines.append("-%d gold" % spent)
	if cost_hp > 0:
		event.character_stats.health = maxi(1, event.character_stats.health - cost_hp)
		lines.append("-%d HP" % cost_hp)
	if cost_rerolls > 0:
		event.run_stats.rerolls -= cost_rerolls
		lines.append("-%d reroll%s" % [cost_rerolls, "" if cost_rerolls == 1 else "s"])
	return lines
