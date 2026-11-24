class_name BattleStats
extends Resource

@export_range(0, 3) var battle_tier: int
@export_range(0.0, 10.0) var weight: float
@export var gold_reward_min: int
@export var gold_reward_max: int
@export var enemies: PackedScene

const REWARD_CONFIG: RewardConfig = preload("res://custom_resources/reward_config.tres")

var accumulated_weight: float = 0.0


func roll_gold_reward() -> int:
	## The configured income scale applies to every battle and boss payout.
	return RewardRules.scale_gold(REWARD_CONFIG, RNG.pick_random(gold_reward_min, gold_reward_max))
