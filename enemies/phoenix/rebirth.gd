class_name PhoenixRebirth
extends EnemyAction
## Passive (never chosen as an action). The first lethal hit turns the Phoenix into an
## ash pile (5 health, bar frozen, no attacks). After REVIVE_TIME seconds of battle time
## it returns with REVIVE_SHARE of its maximum health unless the pile is killed.

const REVIVE_TIME := 6.0
const REVIVE_SHARE := 0.6
const ASH_HEALTH := 5
const ASH_FACTOR := "ash"

@export var ash_art: Texture2D

var reborn_used := false
var in_ash := false
var ash_left := 0.0


func _ready() -> void:
	type = Type.CONDITIONAL
	_connect.call_deferred()


func _connect() -> void:
	if not is_instance_valid(enemy):
		return
	enemy.before_death = _intercept
	enemy.battle_tick.connect(_on_battle_tick)


func is_performable() -> bool:
	return false


func _intercept() -> bool:
	if reborn_used:
		return false
	reborn_used = true
	in_ash = true
	ash_left = REVIVE_TIME
	enemy.stats.block = 0
	enemy.stats.health = ASH_HEALTH
	enemy.special_state = "ASH"
	enemy.atb_mods.set_factor(ASH_FACTOR, 0.0)
	if ash_art:
		enemy.sprite_2d.texture = ash_art
	enemy._spawn_popup("ASH", Color.GRAY)
	return true


func _on_battle_tick(delta: float) -> void:
	if not in_ash or not is_instance_valid(enemy):
		return
	ash_left -= delta
	if ash_left > 0.0:
		return
	in_ash = false
	enemy.special_state = ""
	enemy.atb_mods.clear_factor(ASH_FACTOR)
	enemy.sprite_2d.texture = enemy.stats.art
	enemy.stats.health = floori(enemy.stats.max_health * REVIVE_SHARE)
	enemy._spawn_popup("REBORN", Color.ORANGE)
