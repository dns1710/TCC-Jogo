extends Node
## Guard and report for the enemy-scaling and act-difficulty-curve specs. Checks that an act's health scale,
## attack bonus and boss dice reach spawned enemies without touching shared resources, that Brittle still
## works on scaled hits, and that the three acts form a rising curve whose worst boss hit stays survivable.
## Prints each enemy's effective health, average hit and worst hit per act.
## Run: Godot --headless --path . res://tools/verify_enemy_scaling.tscn

const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ACT_PATHS := ["res://acts/act_1_forest.tres", "res://acts/act_2_ice.tres", "res://acts/act_3_fire.tres"]
const PLAYER_PATH := "res://characters/player/player.tres"
const ROLLS := 2000

var _errors: Array[String] = []


func _ready() -> void:
	var acts: Array[Act] = []
	for path in ACT_PATHS:
		acts.append(load(path))

	_check_act_data(acts)
	_check_apply()
	await _check_boss_dice_and_brittle()
	await _check_handler(acts)
	_check_curve_and_report(acts)

	if _errors.is_empty():
		print("ENEMY SCALING CHECK OK")
		get_tree().quit(0)
	else:
		print("ENEMY SCALING CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


# ---------------------------------------------------------------- act data

func _check_act_data(acts: Array[Act]) -> void:
	_expect(is_equal_approx(acts[0].enemy_health_scale, 1.0) and acts[0].enemy_attack_bonus == 0 and acts[0].boss_extra_dice == 0,
		"act 1 keeps the baseline enemy strength")
	var blank := Act.new()
	_expect(is_equal_approx(blank.enemy_health_scale, 1.0) and blank.enemy_attack_bonus == 0 and blank.boss_extra_dice == 0,
		"an act without scaling values leaves enemies unchanged")
	for i in range(1, acts.size()):
		var prev := acts[i - 1]
		var act := acts[i]
		var not_lower: bool = act.enemy_health_scale >= prev.enemy_health_scale and act.enemy_attack_bonus >= prev.enemy_attack_bonus
		var differs: bool = act.enemy_health_scale > prev.enemy_health_scale or act.enemy_attack_bonus > prev.enemy_attack_bonus
		_expect(not_lower and differs, "act %d must be stronger than act %d (health scale and attack bonus never drop, one rises)" % [i + 1, i])


# ---------------------------------------------------------------- applying the scaling

func _check_apply() -> void:
	var base := load("res://enemies/cap/cap.tres") as EnemyStats
	var base_health := base.max_health
	var base_attack := base.max_attack
	var act := Act.new()
	act.enemy_health_scale = 1.25
	act.enemy_attack_bonus = 2

	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	enemy.stats = base
	_expect(enemy.stats.max_health == base_health, "an unscaled enemy has base health")
	EnemyScaling.apply(enemy, act)
	_expect(enemy.stats.max_health == ceili(base_health * 1.25 - 0.0001) and enemy.stats.health == enemy.stats.max_health,
		"health %d -> %d at scale 1.25, got %d/%d" % [base_health, ceili(base_health * 1.25), enemy.stats.health, enemy.stats.max_health])
	_expect(enemy.stats.attack == base_attack + 2, "attack bonus +2, got %d from %d" % [enemy.stats.attack, base_attack])
	_expect(enemy.extra_attack_dice == 0, "a regular enemy gets no boss dice")
	_expect(base.max_health == base_health and base.max_attack == base_attack, "the shared enemy resource is untouched")

	var again := ENEMY_SCENE.instantiate() as Enemy
	add_child(again)
	again.stats = base
	_expect(again.stats.max_health == base_health, "a later enemy of the same type spawns with base health")
	EnemyScaling.apply(again, null)
	_expect(again.stats.max_health == base_health, "no act means no scaling")

	var rounding := Act.new()
	rounding.enemy_health_scale = 1.1
	var chicken := ENEMY_SCENE.instantiate() as Enemy
	add_child(chicken)
	chicken.stats = load("res://enemies/zscout/zscout.tres")
	var zscout_base := chicken.stats.max_health
	EnemyScaling.apply(chicken, rounding)
	_expect(chicken.stats.max_health == ceili(zscout_base * 1.1 - 0.0001), "scaling rounds up without float drift (%d -> %d)" % [zscout_base, chicken.stats.max_health])

	# A boss in a scaled act rolls extra dice; summoned minions are scaled like any enemy.
	var boss_act := Act.new()
	boss_act.boss_extra_dice = 1
	var boss := ENEMY_SCENE.instantiate() as Enemy
	add_child(boss)
	boss.stats = load("res://enemies/krampus/krampus.tres")
	EnemyScaling.apply(boss, boss_act)
	_expect(boss.extra_attack_dice == 1, "a boss gets the act's extra dice")

	for node in [enemy, again, chicken, boss]:
		node.free()


func _check_boss_dice_and_brittle() -> void:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	enemy.stats = load("res://enemies/big_chicken_boss/big_chicken.tres")
	var action := ProbeAction.new()
	action.enemy = enemy
	action.dice_amount = 1
	action.dice_value = 6
	var attack := enemy.stats.attack

	enemy.extra_attack_dice = 0
	var low := 1 << 30
	var high := -1
	for i in ROLLS:
		var damage := action.roll_attack(1, 6)
		low = mini(low, damage)
		high = maxi(high, damage)
	_expect(low == 1 + attack and high == 6 + attack, "a regular 1d6 hit rolls %d..%d, saw %d..%d" % [1 + attack, 6 + attack, low, high])

	enemy.extra_attack_dice = 1
	low = 1 << 30
	high = -1
	for i in ROLLS:
		var damage := action.roll_attack(1, 6)
		low = mini(low, damage)
		high = maxi(high, damage)
	_expect(low == 2 + attack and high == 12 + attack, "a boss 1d6 hit with 1 extra die rolls 2d6: %d..%d, saw %d..%d" % [2 + attack, 12 + attack, low, high])

	# Brittle still adds one die of the attack's own size on a scaled hit.
	var player := PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.stats = (load(PLAYER_PATH) as CharacterStats).create_instance()
	await _frames(2)
	var melee := MeleeAttackAction.new()
	melee.enemy = enemy
	melee.target = player
	melee.dice_amount = 1
	melee.dice_value = 6
	player.brittle_next_hit = true
	melee._hit()
	_expect(not player.brittle_next_hit, "a scaled boss hit carries its die size, so Brittle is spent on it")
	var extra_roll := player._consume_brittle(Modifier.Type.DMG_TAKEN, 6)
	_expect(extra_roll == 0, "Brittle was already consumed by the hit")
	player.brittle_next_hit = true
	var bonus := player._consume_brittle(Modifier.Type.DMG_TAKEN, 6)
	_expect(bonus >= 1 and bonus <= 6, "Brittle adds one die of the attack's size (1..6), got %d" % bonus)

	melee.free()
	action.free()
	player.free()
	enemy.free()


func _check_handler(acts: Array[Act]) -> void:
	var pool := load("res://battles/map2/battle_stats_pool.tres") as BattleStatsPool
	pool.setup()
	var battle: BattleStats = pool.get_random_battle_for_tier(1)
	var plain := EnemyHandler.new()
	var scaled := EnemyHandler.new()
	add_child(plain)
	add_child(scaled)
	scaled.act = acts[1]
	plain.setup_enemies(battle)
	scaled.setup_enemies(battle)
	await _frames(2)
	var plain_enemies := plain.get_alive_enemies()
	var scaled_enemies := scaled.get_alive_enemies()
	_expect(not plain_enemies.is_empty() and plain_enemies.size() == scaled_enemies.size(), "both handlers spawned the same battle")
	for i in mini(plain_enemies.size(), scaled_enemies.size()):
		var base := plain_enemies[i].stats.max_health
		_expect(scaled_enemies[i].stats.max_health == ceili(base * acts[1].enemy_health_scale - 0.0001),
			"a spawned act-2 enemy has %d health, expected %d scaled from %d" % [scaled_enemies[i].stats.max_health, ceili(base * acts[1].enemy_health_scale), base])
		_expect(scaled_enemies[i].stats.attack == plain_enemies[i].stats.attack + acts[1].enemy_attack_bonus, "a spawned act-2 enemy has the attack bonus")

	var boss_pool := load("res://battles/map3/battle_stats_pool.tres") as BattleStatsPool
	boss_pool.setup()
	var boss_battle: BattleStats = boss_pool.get_random_battle_for_tier(3)
	var boss_handler := EnemyHandler.new()
	add_child(boss_handler)
	boss_handler.act = acts[2]
	boss_handler.setup_enemies(boss_battle)
	await _frames(2)
	var found_boss := false
	for enemy in boss_handler.get_alive_enemies():
		if enemy.stats is EnemyStats and (enemy.stats as EnemyStats).is_boss:
			found_boss = true
			_expect(enemy.extra_attack_dice == acts[2].boss_extra_dice, "the act-3 boss rolls the act's extra dice, has %d" % enemy.extra_attack_dice)
	_expect(found_boss, "the act-3 boss battle contains a boss")
	for handler in [plain, scaled, boss_handler]:
		handler.free()


# ---------------------------------------------------------------- curve and report

class ProbeAction extends EnemyAction:
	var dice_amount := 1
	var dice_value := 6


## Attack profile of one enemy: list of {avg, worst, hits} per damaging action.
func _attack_profile(stats: EnemyStats, extra_dice: int, attack_bonus: int) -> Dictionary:
	var best_avg := 0.0
	var best_worst := 0
	if stats.ai == null:
		return {"avg": 0.0, "worst": 0}
	var ai := stats.ai.instantiate()
	var stack: Array[Node] = [ai]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if not (node is EnemyAction) or node.get("dice_amount") == null or node.get("dice_value") == null:
			continue
		var amount: int = node.get("dice_amount") + extra_dice
		var sides: int = node.get("dice_value")
		var hits: int = node.get("hits") if node.get("hits") != null else 1
		var multiplier := 1.0
		if node.get("bonus_vs_status") != null and node.get("bonus_vs_status") != "":
			multiplier = node.get("bonus_multiplier")
		var attack := stats.max_attack + attack_bonus
		var avg := (amount * (sides + 1) / 2.0 + attack) * hits
		var worst := floori((amount * sides + attack) * multiplier) * hits + sides # + Brittle's extra die
		best_avg = maxf(best_avg, avg)
		best_worst = maxi(best_worst, worst)
	ai.free()
	return {"avg": best_avg, "worst": best_worst}


func _check_curve_and_report(acts: Array[Act]) -> void:
	var player_health: int = (load(PLAYER_PATH) as CharacterStats).max_health
	var enemies: Array[EnemyStats] = []
	var dir := DirAccess.open("res://enemies")
	for sub in dir.get_directories():
		if sub == "old":
			continue
		var sub_dir := DirAccess.open("res://enemies/" + sub)
		for file in sub_dir.get_files():
			if file.ends_with(".tres"):
				var res := load("res://enemies/%s/%s" % [sub, file])
				if res is EnemyStats:
					enemies.append(res)
	enemies.sort_custom(func(a: EnemyStats, b: EnemyStats) -> bool: return a.resource_path < b.resource_path)

	print("Player starts with %d health. Worst hit includes one Brittle die." % player_health)
	var boss_ratio_sum := {}
	var regular_ratio_sum := {}
	var regular_count := 0
	var boss_count := 0
	for act_index in acts.size():
		var act := acts[act_index]
		print("")
		print("Act %d: health x%.2f, attack +%d, boss dice +%d" % [act_index + 1, act.enemy_health_scale, act.enemy_attack_bonus, act.boss_extra_dice])
		print("  %-22s %6s %7s %7s %s" % ["enemy", "health", "avg hit", "worst", ""])
		var worst_boss := 0
		for stats in enemies:
			var extra := act.boss_extra_dice if stats.is_boss else 0
			var base := _attack_profile(stats, 0, 0)
			var scaled := _attack_profile(stats, extra, act.enemy_attack_bonus)
			var health := ceili(stats.max_health * act.enemy_health_scale - 0.0001)
			print("  %-22s %6d %7.1f %7d %s" % [stats.resource_path.get_file().get_basename(), health, scaled["avg"], scaled["worst"], "BOSS" if stats.is_boss else ""])
			if base["avg"] > 0.0:
				var ratio: float = scaled["avg"] / base["avg"]
				if stats.is_boss:
					boss_ratio_sum[act_index] = boss_ratio_sum.get(act_index, 0.0) + ratio
					if act_index == 0:
						boss_count += 1
					worst_boss = maxi(worst_boss, scaled["worst"])
				else:
					regular_ratio_sum[act_index] = regular_ratio_sum.get(act_index, 0.0) + ratio
					if act_index == 0:
						regular_count += 1
		# Only the bosses fought in this act matter for survivability, but the printed worst case covers all bosses.
		print("  worst boss hit in this act (any boss): %d" % worst_boss)

	for act_index in range(1, acts.size()):
		var boss_growth: float = boss_ratio_sum.get(act_index, 0.0) / maxf(1.0, boss_count)
		var regular_growth: float = regular_ratio_sum.get(act_index, 0.0) / maxf(1.0, regular_count)
		print("act %d average hit growth (information only): bosses x%.2f, regular enemies x%.2f" % [act_index + 1, boss_growth, regular_growth])

	# Worst case per boss in the act it is fought in.
	var boss_acts := {"bear_boss": 0, "big_chicken": 0, "krampus": 1, "fire_dragon": 2}
	for stats in enemies:
		if not stats.is_boss:
			continue
		var boss_name := stats.resource_path.get_file().get_basename()
		if not boss_acts.has(boss_name):
			_errors.append("boss %s has no act in this check" % boss_name)
			continue
		var act: Act = acts[boss_acts[boss_name]]
		var profile := _attack_profile(stats, act.boss_extra_dice, act.enemy_attack_bonus)
		_expect(profile["worst"] < player_health, "%s's worst hit %d must stay below the player's %d health" % [boss_name, profile["worst"], player_health])
