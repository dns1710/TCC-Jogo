extends Node
## Plays a relic loadout against an act's regular fights (or its boss) in a small abstract combat loop and
## prints turns to win, HP lost and win rate. It reads enemy health, dice and act scaling, and relic stats
## and dice, from the game resources, and uses the game's turn-bar pacing (ATBConfig). It is a ranking tool,
## not a replacement for playing: statuses (burn, poison, freeze, brittle...), enemy block and most relic
## effects are NOT simulated, and the output lists which relics in a loadout were reduced to their stats.
## Supported effects: first-attack bonus dice (Stick, Bigger Stick), Needle's speed dice, Riposte Foil's dice
## after blocking, Bulwark Maul's block dice, Great Axe's first-hit block, Glass Heart's Brittle (extra die on the
## next hit taken, back after 3 actions) and Cracked Visor's +1d8 while Brittle.
## The player policy: attack, but block when below 40% health and holding under 5 block.
##
## Run: Godot --headless --path . res://tools/simulate_balance.tscn
##   Extra arguments go after `--`:
##   --loadout=ThornSword,HeavyPlate   relic ids (default: the starter, mid and full presets)
##   --vs=GreatAxe,ScoutScarf          a second loadout to compare against --loadout
##   --act=1|2|3   --tier=1|2|3        which act and battle tier (default act 1, tier 1)
##   --rank=1      every relic added alone to the kit (Stick + Old Shirt), sorted by HP saved, per rarity
##   --builds=40   random builds drawn like a run picks relics (instead of presets), per act
##   --no-scaling=1  ignore the act's enemy scaling (to see what it costs)
##   --fights=500  --seed=7  --block-below=0.4 (the player blocks under this share of health)
## Advisory only: always exits with code 0.

const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const Report := preload("res://tools/report_item_balance.gd")
const ACT_PATHS := ["res://acts/act_1_forest.tres", "res://acts/act_2_ice.tres", "res://acts/act_3_fire.tres"]
const PLAYER_PATH := "res://characters/player/player.tres"
const STEP := 0.05
const MAX_SECONDS := 600.0
const BLOCK_AMOUNT := 5
const DEFAULT_BLOCK_BELOW_HEALTH := 0.4
## Progression targets confirmed with the owner: median HP lost per regular fight for a typical build, per act.
const TARGET_BUILD_HP_LOST := [Vector2(0.20, 0.35), Vector2(0.25, 0.40), Vector2(0.30, 0.45)]

const PRESETS := {
	"kit": ["Stick", "OldShirt"],
	"mid": ["ThornSword", "FrostbornCirclet", "HeavyPlate", "AttackBadge", "BlockBadge"],
	"full": ["GreatAxe", "ScoutScarf", "HeavierArmor", "GlassHeart", "AttackBadge"],
}
## Relics held when an act is entered under the current reward rules (from tools/simulate_rewards.tscn, rounded),
## and the rarity mix of what a run picks up (common, uncommon, rare, mythic).
const HELD_AT_ACT := [4, 9, 17]
const RARITY_MIX := [30, 40, 24, 6]
const SUPPORTED_EFFECTS := ["Stick", "BiggerStick", "Needle", "RiposteFoil", "BulwarkMaul", "GreatAxe", "GlassHeart", "CrackedVisor"]

var _rng := RandomNumberGenerator.new()
var _template_cache := {}
var _block_below := DEFAULT_BLOCK_BELOW_HEALTH
var _scaling := true


func _ready() -> void:
	var options := _parse_args()
	var fights: int = int(options.get("fights", 500))
	var act_index: int = clampi(int(options.get("act", 1)) - 1, 0, 2)
	var tier: int = int(options.get("tier", 1))
	var seed_value: int = int(options.get("seed", 7))
	_block_below = float(options.get("block-below", DEFAULT_BLOCK_BELOW_HEALTH))
	_scaling = not options.has("no-scaling")

	if options.has("loadout"):
		var first := _resolve_loadout(String(options["loadout"]).split(",", false))
		var results := {"loadout": _run(first, act_index, tier, fights, seed_value)}
		print(_header(act_index, tier, fights, seed_value))
		print(_describe("loadout", first, results["loadout"]))
		if options.has("breakdown"):
			_print_breakdown(results["loadout"])
		if options.has("vs"):
			var second := _resolve_loadout(String(options["vs"]).split(",", false))
			var second_result := _run(second, act_index, tier, fights, seed_value)
			print(_describe("vs", second, second_result))
			print("difference (vs minus loadout): HP lost %+.1f, actions to win %+.2f, win rate %+d points" % [
				second_result["hp_lost"] - results["loadout"]["hp_lost"],
				second_result["turns"] - results["loadout"]["turns"],
				roundi((second_result["win_rate"] - results["loadout"]["win_rate"]) * 100)])
	elif options.has("rank"):
		_run_ranking(act_index, tier, fights, seed_value)
	elif options.has("builds"):
		_run_random_builds(int(options["builds"]), fights, tier, seed_value)
	else:
		_run_presets(fights, tier, seed_value)
	get_tree().quit(0)


func _parse_args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var parts := arg.substr(2).split("=", true, 1)
			out[parts[0]] = parts[1]
	return out


func _header(act_index: int, tier: int, fights: int, seed_value: int) -> String:
	return "Balance simulation: act %d, tier %d, %d fights per loadout, seed %d" % [act_index + 1, tier, fights, seed_value]


func _run_presets(fights: int, tier: int, seed_value: int) -> void:
	print("Balance simulation: %d fights per cell, tier %d, seed %d" % [fights, tier, seed_value])
	print("Each fight starts at full health. HP lost is per fight; actions = player turns to win.")
	var table := {}
	for preset in PRESETS:
		var loadout := _resolve_loadout(PRESETS[preset])
		print("")
		print("%s: %s" % [preset, _describe_loadout(loadout)])
		for act_index in 3:
			var result := _run(loadout, act_index, tier, fights, seed_value)
			table[[preset, act_index]] = result
			print("  act %d: win %3d%%  actions %4.1f  HP lost %4.1f (%2d%% of %d)" % [
				act_index + 1, roundi(result["win_rate"] * 100), result["turns"], result["hp_lost"],
				roundi(result["hp_lost"] / result["health"] * 100), roundi(result["health"])])
		if not loadout["unsupported"].is_empty():
			print("  effects not simulated: %s" % ", ".join(loadout["unsupported"]))
	print("")
	_run_random_builds(30, 40, tier, seed_value)


# ---------------------------------------------------------------- ranking

## Adds each relic alone to a kit of Stick and Old Shirt (replacing the item in its slot) and prints how much HP per
## fight it saves, per rarity. Stat-only relics are shown at face value; relics whose effects are not simulated
## are marked "~" and look weaker here than they are, so a "~" relic that already ranks high is a real outlier.
func _run_ranking(act_index: int, tier: int, fights: int, seed_value: int) -> void:
	print("Relic ranking: act %d, tier %d, %d fights each, seed %d" % [act_index + 1, tier, fights, seed_value])
	print("Kit: Stick + Old Shirt; a relic replaces the kit item in its slot. 'saves' = HP lost by the kit minus HP lost with the relic.")
	var kit := _run(_resolve_loadout(["Stick", "OldShirt"]), act_index, tier, fights, seed_value)
	print("kit alone: HP lost %.1f of 40, win %d%%" % [kit["hp_lost"], roundi(kit["win_rate"] * 100)])
	var rows: Array = []
	for relic in Report.load_relics():
		if relic.starter_relic:
			continue
		var ids: Array = ["Stick", "OldShirt"]
		match relic.equip:
			Relic.Equip.WEAPON:
				ids = [relic.id, "OldShirt"]
			Relic.Equip.ARMOR:
				ids = ["Stick", relic.id]
			_:
				ids.append(relic.id)
		var loadout := _resolve_loadout(ids)
		var result := _run(loadout, act_index, tier, fights, seed_value)
		rows.append({
			"rarity": relic.rarity, "name": relic.relic_name, "slot": relic.get_equip(),
			"saves": kit["hp_lost"] - result["hp_lost"], "win": result["win_rate"],
			"approx": not loadout["unsupported"].is_empty(),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["rarity"] != b["rarity"]:
			return a["rarity"] < b["rarity"]
		return a["saves"] > b["saves"])
	var rarity_names := ["Common", "Uncommon", "Rare", "Mythic"]
	var current := -1
	for row in rows:
		if row["rarity"] != current:
			current = row["rarity"]
			print("")
			print("%s" % rarity_names[current])
		print("  %-22s %-8s saves %5.1f HP  win %3d%% %s" % [row["name"], row["slot"], row["saves"], roundi(row["win"] * 100), "~" if row["approx"] else ""])


# ---------------------------------------------------------------- random builds

## A typical run holds HELD_AT_ACT relics when it enters each act and equips the rarest per slot. This draws
## such builds and prints how a build's HP lost per regular fight is spread, which is the number to tune.
func _run_random_builds(builds: int, fights: int, tier: int, seed_value: int) -> void:
	print("Random builds: %d builds per act, %d fights each, tier %d, seed %d" % [builds, fights, tier, seed_value])
	print("Builds hold %s relics when entering acts 1-3 and equip the rarest per slot. Targets (HP lost): %s" % [HELD_AT_ACT, TARGET_BUILD_HP_LOST])
	var all_relics := Report.load_relics().filter(func(r: Relic) -> bool: return not r.starter_relic)
	for act_index in 3:
		var shares: Array[float] = []
		var wins: Array[float] = []
		var worst_example := ""
		var worst_share := -1.0
		_rng.seed = seed_value + act_index
		for b in builds:
			var ids := _draw_build(all_relics, HELD_AT_ACT[act_index])
			var loadout := _resolve_loadout(ids)
			var result := _run(loadout, act_index, tier, fights, seed_value + b)
			var share: float = result["hp_lost"] / result["health"]
			shares.append(share)
			wins.append(result["win_rate"])
			if share > worst_share:
				worst_share = share
				worst_example = ", ".join(loadout["names"])
		shares.sort()
		wins.sort()
		var target: Vector2 = TARGET_BUILD_HP_LOST[act_index]
		var median := shares[shares.size() / 2]
		print("  act %d: HP lost p25 %d%%  median %d%%  p75 %d%% (target %d-%d%%: %s)  median win rate %d%%" % [
			act_index + 1, roundi(shares[shares.size() / 4] * 100), roundi(median * 100), roundi(shares[shares.size() * 3 / 4] * 100),
			roundi(target.x * 100), roundi(target.y * 100), "inside" if median >= target.x and median <= target.y else "OUTSIDE",
			roundi(wins[wins.size() / 2] * 100)])
		print("          hardest build: %s (%d%% lost)" % [worst_example, roundi(worst_share * 100)])


## `held` distinct relics by the rarity mix, then the rarest per slot (random among equals).
func _draw_build(all_relics: Array, held: int) -> Array:
	var by_rarity := [[], [], [], []]
	for relic in all_relics:
		by_rarity[clampi(relic.rarity, 0, 3)].append(relic)
	var picked: Array[Relic] = []
	var guard := 0
	while picked.size() < held and guard < 1000:
		guard += 1
		var roll := _rng.randi_range(1, 100)
		var rarity := 0
		for i in 4:
			roll -= RARITY_MIX[i]
			if roll <= 0:
				rarity = i
				break
		var candidates: Array = by_rarity[rarity].filter(func(r: Relic) -> bool: return not picked.has(r))
		if candidates.is_empty():
			continue
		picked.append(candidates[_rng.randi() % candidates.size()])
	var ids: Array = []
	for slot in [Relic.Equip.WEAPON, Relic.Equip.HELMET, Relic.Equip.ARMOR, Relic.Equip.TRINKET]:
		var in_slot := picked.filter(func(r: Relic) -> bool: return r.equip == slot)
		in_slot.shuffle()
		in_slot.sort_custom(func(a: Relic, b: Relic) -> bool: return a.rarity > b.rarity)
		var count := 2 if slot == Relic.Equip.TRINKET else 1
		for i in mini(count, in_slot.size()):
			ids.append(in_slot[i].id)
	return ids


# ---------------------------------------------------------------- loadouts

func _resolve_loadout(ids: Array) -> Dictionary:
	var relics: Array[Relic] = []
	var by_id := {}
	for relic in Report.load_relics():
		by_id[relic.id] = relic
	var names: Array[String] = []
	var unsupported: Array[String] = []
	for id in ids:
		if not by_id.has(id):
			push_warning("unknown relic id '%s' skipped" % id)
			continue
		var relic: Relic = by_id[id]
		relics.append(relic)
		names.append(relic.relic_name)
		if Report.script_source(relic) != "" and not SUPPORTED_EFFECTS.has(id):
			unsupported.append(relic.relic_name)
	var base := load(PLAYER_PATH) as CharacterStats
	var attack := base.max_attack
	var speed := base.max_speed
	var block := base.max_block
	var weapon: Relic = null
	for relic in relics:
		attack += relic.bonus_atk
		speed += relic.bonus_spd
		block += relic.bonus_blk
		if relic.equip == Relic.Equip.WEAPON:
			weapon = relic
	return {
		"ids": ids, "names": names, "relics": relics, "weapon": weapon, "unsupported": unsupported,
		"health": base.max_health, "attack": attack, "speed": maxi(speed, 1), "block": block,
	}


func _describe_loadout(loadout: Dictionary) -> String:
	var weapon: Relic = loadout["weapon"]
	var dice := "%dd%d" % [weapon.weapon_dice_amount, weapon.weapon_dice_attack] if weapon else "1d4"
	return "%s | attack %d, speed %d, start block %d, weapon %s" % [
		", ".join(loadout["names"]) if not loadout["names"].is_empty() else "no relics",
		loadout["attack"], loadout["speed"], loadout["block"], dice]


func _print_breakdown(result: Dictionary) -> void:
	for key in _template_cache:
		print("  %s" % key.get_file())
		for template in _template_cache[key]:
			var parts: Array[String] = []
			for action in template["actions"]:
				if action["sides"] > 0:
					parts.append("%s%dd%d x%d (w%.0f)" % ["" if action["chance"] else "cond ", action["amount"] + template["extra"], action["sides"], action["hits"], action["weight"]])
				elif action["telegraph"]:
					parts.append("telegraph (w%.0f)" % action["weight"])
			print("    hp %d atk %d spd %d: %s" % [template["health"], template["attack"], template["speed"], "; ".join(parts)])
	for battle_name in result["per_battle"]:
		var entry: Dictionary = result["per_battle"][battle_name]
		print("    %-28s win %3d%%  HP lost %4.1f" % [battle_name, roundi(100.0 * entry["won"] / entry["n"]), entry["lost"] / entry["n"]])


func _describe(label: String, loadout: Dictionary, result: Dictionary) -> String:
	var text := "%s: %s\n  win %d%%, %.1f actions to win, HP lost %.1f of %d (%d%%)" % [
		label, _describe_loadout(loadout), roundi(result["win_rate"] * 100), result["turns"], result["hp_lost"],
		roundi(result["health"]), roundi(result["hp_lost"] / result["health"] * 100)]
	if not loadout["unsupported"].is_empty():
		text += "\n  effects not simulated: %s" % ", ".join(loadout["unsupported"])
	return text


# ---------------------------------------------------------------- fights

func _run(loadout: Dictionary, act_index: int, tier: int, fights: int, seed_value: int) -> Dictionary:
	_rng.seed = seed_value
	var act := load(ACT_PATHS[act_index]) as Act
	var battles: Array[BattleStats] = []
	for battle in act.battle_stats_pool.pool:
		if battle != null and battle.battle_tier == tier:
			battles.append(battle)
	var wins := 0
	var turns_total := 0.0
	var hp_lost_total := 0.0
	var per_battle := {}
	for i in fights:
		var battle: BattleStats = _pick_battle(battles)
		if battle == null:
			break
		var outcome := _fight(loadout, _templates(battle, act, act_index))
		if outcome["won"]:
			wins += 1
			turns_total += outcome["turns"]
		hp_lost_total += outcome["hp_lost"]
		var entry: Dictionary = per_battle.get(battle.resource_path.get_file().get_basename(), {"n": 0, "lost": 0.0, "won": 0})
		entry["n"] += 1
		entry["lost"] += outcome["hp_lost"]
		entry["won"] += 1 if outcome["won"] else 0
		per_battle[battle.resource_path.get_file().get_basename()] = entry
	return {
		"win_rate": float(wins) / maxf(1.0, fights), "turns": turns_total / maxf(1.0, wins),
		"hp_lost": hp_lost_total / maxf(1.0, fights), "health": float(loadout["health"]), "per_battle": per_battle,
	}


func _pick_battle(battles: Array[BattleStats]) -> BattleStats:
	if battles.is_empty():
		return null
	var total := 0.0
	for battle in battles:
		total += battle.weight
	var roll := _rng.randf_range(0.0, total)
	for battle in battles:
		roll -= battle.weight
		if roll <= 0.0:
			return battle
	return battles.back()


## Enemy data of a battle in an act, cached: health and attack after the act's scaling, speed, and attacks.
func _templates(battle: BattleStats, act: Act, act_index: int) -> Array:
	var key := "%s|%d" % [battle.resource_path, act_index]
	if _template_cache.has(key):
		return _template_cache[key]
	var out: Array = []
	var scene := battle.enemies.instantiate()
	add_child(scene)
	for node in scene.get_children():
		var enemy := node as Enemy
		if enemy == null:
			continue
		EnemyScaling.apply(enemy, act if _scaling else null)
		var template := {
			"health": enemy.stats.max_health, "attack": enemy.stats.attack, "speed": enemy.stats.speed,
			"extra": enemy.extra_attack_dice, "actions": [],
		}
		var ai := enemy.stats.ai.instantiate()
		for action in ai.get_children():
			var entry := {
				"weight": action.get("chance_weight") if action.get("chance_weight") != null else 0.0,
				"chance": action.get("type") == EnemyAction.Type.CHANCE_BASED,
				"amount": action.get("dice_amount") if action.get("dice_amount") != null else 0,
				"sides": action.get("dice_value") if action.get("dice_value") != null else 0,
				"hits": action.get("hits") if action.get("hits") != null else 1,
				"telegraph": action is TelegraphAction,
				"strike": action is TelegraphedStrikeAction,
			}
			template["actions"].append(entry)
		ai.free()
		out.append(template)
	scene.free()
	_template_cache[key] = out
	return out


func _fight(loadout: Dictionary, templates: Array) -> Dictionary:
	var health: int = loadout["health"]
	var block: int = loadout["block"]
	var attack: int = loadout["attack"]
	var speed: float = loadout["speed"]
	var weapon: Relic = loadout["weapon"]
	var ids: Array = loadout["ids"]
	var amount := weapon.weapon_dice_amount if weapon else 1
	var sides := weapon.weapon_dice_attack if weapon else 4

	var enemies: Array = []
	for template in templates:
		enemies.append({
			"health": template["health"], "attack": template["attack"], "speed": template["speed"],
			"extra": template["extra"], "actions": template["actions"],
			"atb": _rng.randf_range(0.0, ATBConfig.MAX * ATBConfig.ENEMY_START_MAX_RATIO),
			"telegraphed": false,
		})
	var player_atb := ATBConfig.MAX * ATBConfig.PLAYER_START_RATIO
	var first_attack := true
	var first_hit := true
	var blocked_last := false
	var player_actions := 0
	var elapsed := 0.0
	var brittle := ids.has("GlassHeart")
	var brittle_countdown := -1

	while health > 0 and not enemies.is_empty() and elapsed < MAX_SECONDS:
		elapsed += STEP
		player_atb += speed * STEP
		if player_atb >= ATBConfig.MAX:
			player_atb = 0.0
			player_actions += 1
			if brittle_countdown > 0:
				brittle_countdown -= 1
				if brittle_countdown == 0:
					brittle = true
					brittle_countdown = -1
			if float(health) / loadout["health"] < _block_below and block < BLOCK_AMOUNT:
				block += BLOCK_AMOUNT
				blocked_last = true
			else:
				var damage := _roll(amount, sides, attack)
				if first_attack and (ids.has("Stick") or ids.has("BiggerStick")):
					damage += _roll(1, 10 if ids.has("BiggerStick") else 6)
				if ids.has("Needle") and speed >= 2:
					damage += _roll(floori(speed / 2.0), 4)
				if ids.has("RiposteFoil") and blocked_last:
					damage += _roll(1, 6)
				if ids.has("BulwarkMaul") and block >= 5:
					damage += _roll(mini(block / 5, 3), 4)
				if ids.has("CrackedVisor") and brittle:
					damage += _roll(1, 8)
				first_attack = false
				blocked_last = false
				enemies[0]["health"] -= damage
				if enemies[0]["health"] <= 0:
					enemies.remove_at(0)
			continue
		for enemy in enemies:
			enemy["atb"] += enemy["speed"] * STEP
			if enemy["atb"] >= ATBConfig.MAX:
				enemy["atb"] = 0.0
				var result := _enemy_hit(enemy, brittle)
				if result["brittle_used"]:
					brittle = false
					brittle_countdown = 3
				var hit: int = result["damage"]
				if hit > 0:
					if first_hit and ids.has("GreatAxe"):
						block += _roll(1, 4)
					first_hit = false
					var absorbed := mini(block, hit)
					block -= absorbed
					health -= hit - absorbed
				if health <= 0:
					break
	return {"won": health > 0 and enemies.is_empty(), "turns": player_actions, "hp_lost": loadout["health"] - maxi(health, 0)}


## Damage of one enemy turn: picks a weighted action; a telegraph is followed by its strike.
func _enemy_hit(enemy: Dictionary, brittle: bool) -> Dictionary:
	var actions: Array = enemy["actions"]
	var chosen: Dictionary = {}
	if enemy["telegraphed"]:
		for action in actions:
			if action["strike"]:
				chosen = action
		enemy["telegraphed"] = false
	if chosen.is_empty():
		var total := 0.0
		for action in actions:
			if action["chance"]:
				total += action["weight"]
		var roll := _rng.randf_range(0.0, maxf(total, 0.0001))
		for action in actions:
			if not action["chance"]:
				continue
			roll -= action["weight"]
			if roll <= 0.0:
				chosen = action
				break
	var none := {"damage": 0, "brittle_used": false}
	if chosen.is_empty():
		return none
	if chosen["telegraph"]:
		enemy["telegraphed"] = true
		return none
	if chosen["amount"] <= 0 or chosen["sides"] <= 0:
		return none
	var hits: int = chosen["hits"]
	var total_damage := 0
	var used := false
	for i in hits:
		total_damage += _roll(chosen["amount"] + enemy["extra"], chosen["sides"], enemy["attack"])
		if brittle and not used:
			total_damage += _roll(1, chosen["sides"])
			used = true
	return {"damage": total_damage, "brittle_used": used}


## Dice rolled with the simulator's own seeded generator, so runs repeat exactly.
func _roll(amount: int, sides: int, bonus := 0) -> int:
	var total := bonus
	for i in amount:
		total += _rng.randi_range(1, sides)
	return total
