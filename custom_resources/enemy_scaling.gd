class_name EnemyScaling
extends RefCounted
## Applies an act's scaling to one spawned enemy. Works on the enemy's own stats instance,
## never on the shared enemy resource.

static func apply(enemy: Enemy, act: Act) -> void:
	if act == null or enemy == null or enemy.stats == null:
		return
	var stats := enemy.stats
	var scaled_health := ceili(stats.max_health * act.enemy_health_scale - 0.0001)
	if scaled_health != stats.max_health:
		stats.max_health = maxi(scaled_health, 1)
		stats.health = stats.max_health
	if act.enemy_attack_bonus != 0:
		stats.max_attack += act.enemy_attack_bonus
		stats.attack = stats.max_attack
	if stats is EnemyStats and (stats as EnemyStats).is_boss:
		enemy.extra_attack_dice = act.boss_extra_dice
