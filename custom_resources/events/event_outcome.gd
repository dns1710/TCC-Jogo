class_name EventOutcome
extends Resource
## One possible result of an event choice: the story text plus what it changes.

const REWARD_CONFIG: RewardConfig = preload("res://custom_resources/reward_config.tres")

@export_multiline var text := ""
## Relative chance among the choice's outcomes (ignored when the choice has a stat check).
@export var weight := 1.0

@export_group("Effects")
@export var gold := 0
## For all-in choices: gold gained = floor(bet * bet_multiplier).
@export var bet_multiplier := 0.0
@export var hp := 0
## Heals this share of max health (0.5 = half).
@export_range(0.0, 1.0) var heal_share := 0.0
@export var max_hp := 0
@export var attack := 0
@export var block := 0
@export var speed := 0
@export var rerolls := 0
## Hidden difficulty score change.
@export var dda := 0
## Grants a random relic of this rarity (0 common .. 3 mythic); -1 for none.
@export_range(-1, 3) var relic_rarity := -1
@export var convert_from: Room.Type = Room.Type.NOT_ASSIGNED
@export var convert_to: Room.Type = Room.Type.NOT_ASSIGNED
@export var convert_count := 1


## Applies the effects and returns one readable line per thing that changed.
func apply(event: EventRoom, bet := 0) -> Array[String]:
	var lines: Array[String] = []
	var stats := event.character_stats
	var run := event.run_stats

	# Gold gained follows the income scale; gold lost and winnings from a bet do not.
	var scaled_gold := RewardRules.scale_gold(REWARD_CONFIG, gold) if gold > 0 else gold
	var gold_delta := scaled_gold + int(floor(bet * bet_multiplier))
	if gold_delta != 0:
		var before := run.gold
		run.gold = maxi(0, run.gold + gold_delta)
		_add_line(lines, run.gold - before, "gold")

	if max_hp != 0:
		var before := stats.max_health
		stats.max_health = maxi(1, stats.max_health + max_hp)
		_add_line(lines, stats.max_health - before, "max HP")

	var hp_delta := hp + int(ceil(stats.max_health * heal_share))
	if hp_delta != 0:
		var before := stats.health
		stats.health = clampi(stats.health + hp_delta, 1, stats.max_health)
		_add_line(lines, stats.health - before, "HP")

	if attack != 0:
		var before := stats.max_attack
		stats.max_attack = maxi(1, stats.max_attack + attack)
		_add_line(lines, stats.max_attack - before, "ATTACK")

	if block != 0:
		var before := stats.max_block
		stats.max_block = maxi(0, stats.max_block + block)
		_add_line(lines, stats.max_block - before, "BLOCK")

	if speed != 0:
		var before := stats.max_speed
		stats.max_speed = maxi(1, stats.max_speed + speed)
		_add_line(lines, stats.max_speed - before, "SPEED")

	if rerolls != 0:
		var before := run.rerolls
		run.rerolls = maxi(0, run.rerolls + rerolls)
		_add_line(lines, run.rerolls - before, "rerolls")

	if dda != 0:
		DDA.change_score(run, dda, "event")

	if relic_rarity >= 0:
		var relic := _pick_relic(event)
		if relic:
			event.relic_handler.add_relic(relic)
			lines.append("Found: %s" % relic.relic_name)
		else:
			lines.append("No relic left to find")

	if convert_from != Room.Type.NOT_ASSIGNED and convert_to != Room.Type.NOT_ASSIGNED and event.map:
		event.map.call("change_room", convert_from, convert_to, convert_count)
		lines.append("The path ahead shifts")

	return lines


func _add_line(lines: Array[String], delta: int, label: String) -> void:
	if delta != 0:
		lines.append("%+d %s" % [delta, label])


func _pick_relic(event: EventRoom) -> Relic:
	if event.relic_handler == null:
		return null

	var candidates: Array[Relic] = []
	for relic: Relic in event.relic_pool:
		if relic == null or relic.rarity != relic_rarity:
			continue
		if not relic.can_appear_as_reward(event.character_stats):
			continue
		if event.relic_handler.has_relic(relic.id):
			continue
		candidates.append(relic)

	return RNG.array_pick_random(candidates)
