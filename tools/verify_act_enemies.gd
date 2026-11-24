extends Node
## Headless check of the ice-enemies, krampus-boss, fire-enemies and fire-dragon-boss specs:
## content validation, both battle pools, every enemy mechanic, and a smoke run of every
## Act 2 and Act 3 battle in the real battle scene.
## Run: Godot --headless --path . res://tools/verify_act_enemies.tscn

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const RELICS_SCENE := preload("res://scenes/relic_handler/relic_handler.tscn")

const ICE_ENEMIES := ["snow_wolf", "snow_wolf_alpha", "ice_spider", "snow_golem", "banshee", "yeti"]
const FIRE_ENEMIES := ["campfire", "flames", "fire_salamander", "fire_imp", "ashen_warrior", "phoenix", "magma_golem"]
const PATHS := {
	"snow_wolf": "res://enemies/snow_wolf/snow_wolf.tres",
	"snow_wolf_alpha": "res://enemies/snow_wolf_alpha/snow_wolf_alpha.tres",
	"ice_spider": "res://enemies/ice_spider/ice_spider.tres",
	"snow_golem": "res://enemies/snow_golem/snow_golem.tres",
	"banshee": "res://enemies/banshee/banshee.tres",
	"yeti": "res://enemies/yeti/yeti.tres",
	"krampus": "res://enemies/krampus/krampus.tres",
	"campfire": "res://enemies/living_flame/campfire.tres",
	"flames": "res://enemies/living_flame/flames.tres",
	"fire_salamander": "res://enemies/fire_salamander/fire_salamander.tres",
	"fire_imp": "res://enemies/fire_imp/fire_imp.tres",
	"ashen_warrior": "res://enemies/ashen_warrior/ashen_warrior.tres",
	"phoenix": "res://enemies/phoenix/phoenix.tres",
	"magma_golem": "res://enemies/magma_golem/magma_golem.tres",
	"fire_dragon": "res://enemies/fire_dragon/fire_dragon.tres",
}

var _errors: Array[String] = []
var _player: Player
var _smoke_actions := 0


func _ready() -> void:
	await _run_checks()
	if _errors.is_empty():
		print("ACT ENEMIES CHECK OK")
		get_tree().quit(0)
	else:
		print("ACT ENEMIES CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 2) -> void:
	for i in count:
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _new_handler() -> EnemyHandler:
	var holder := Node2D.new()
	add_child(holder)
	var handler := EnemyHandler.new()
	holder.add_child(handler)
	return handler


func _spawn(handler: EnemyHandler, key: String, summoner: Node = null) -> Enemy:
	var enemy := handler.spawn_enemy(load(PATHS[key]), summoner)
	await _frames()
	return enemy


func _act(enemy: Enemy, node_name: String) -> EnemyAction:
	return enemy.enemy_action_picker.get_node(node_name)


func _kill(enemy: Enemy) -> void:
	enemy.take_damage(9999, Modifier.Type.NO_MODIFIER)


func _status(actor: Node, id: String) -> Status:
	return actor.status_handler._get_status(id)


func _stacks(actor: Node, id: String) -> int:
	var status := _status(actor, id)
	if not status:
		return 0
	if status.can_expire and status.duration <= 0:
		return 0
	return status.stacks


func _done(handler: EnemyHandler) -> void:
	handler.get_parent().queue_free()
	await _frames()


func _await_completed(enemy: Enemy, timeout := 8.0) -> bool:
	var done := [false]
	var on_done := func(e: Enemy): if e == enemy: done[0] = true
	Events.enemy_action_completed.connect(on_done)
	var started := Time.get_ticks_msec()
	while not done[0] and Time.get_ticks_msec() - started < timeout * 1000.0:
		await get_tree().process_frame
	Events.enemy_action_completed.disconnect(on_done)
	return done[0]


## Performs an action and waits for it to finish.
func _do(enemy: Enemy, action: EnemyAction) -> void:
	if "duration" in action:
		action.duration = 0.05
	action.perform_action()
	_expect(await _await_completed(enemy), "%s must complete" % action.name)


func _reset_player() -> void:
	_player.stats.health = _player.stats.max_health
	_player.stats.block = 0
	for ui in _player.status_handler.get_children():
		ui.queue_free()
	_player.atb_mods = ATBModifiers.new()
	_player.ignore_block_next_hit = false
	_player.block_gain_multiplier = 1.0


func _run_checks() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	_player.stats = load("res://characters/player/player.tres").create_instance()
	_player.stats.max_health = 5000
	_player.stats.health = 5000
	_player.stats.block = 0
	await _frames()

	_check_content()
	_check_pools()
	await _check_wolves()
	await _check_spider()
	await _check_snow_golem()
	await _check_banshee()
	await _check_yeti()
	await _check_krampus()
	await _check_campfire()
	await _check_salamander()
	await _check_imps()
	await _check_warrior()
	await _check_phoenix()
	await _check_magma_golem()
	await _check_dragon()
	await _check_smoke_battles()


# ---------------------------------------------------------------- content and pools

func _check_content() -> void:
	for key in PATHS:
		var stats: EnemyStats = load(PATHS[key])
		_expect(stats != null, "%s must load" % key)
		if not stats:
			continue
		_expect(stats.max_health > 0 and stats.max_speed > 0 and stats.max_attack > 0, "%s needs positive stats" % key)
		_expect(stats.art != null, "%s needs art" % key)
		_expect(stats.ai != null, "%s needs an AI scene" % key)
		if stats.ai:
			var ai := stats.ai.instantiate()
			_expect(ai.get_child_count() > 0, "%s AI needs actions" % key)
			ai.free()
	_expect((load(PATHS["krampus"]) as EnemyStats).freeze_immune, "Krampus must be Freeze-immune")
	_expect((load(PATHS["fire_dragon"]) as EnemyStats).freeze_immune, "Fire Dragon must be Freeze-immune")


func _battle_enemy_paths(battle: BattleStats) -> Array[String]:
	var paths: Array[String] = []
	var scene := battle.enemies.instantiate()
	for child in scene.get_children():
		paths.append((child as Enemy).stats.ai.resource_path)
	scene.free()
	return paths


func _check_pool_for(act_path: String, allowed: Array, boss_key: String, act_label: String) -> void:
	var act: Act = load(act_path)
	_expect(act.battle_background != null, "%s must define a battle background" % act_label)
	var pool: BattleStatsPool = act.battle_stats_pool
	_expect(pool.pool != Array(load("res://battles/battle_stats_pool.tres").pool), "%s must not use Act 1's pool" % act_label)
	var minimum := [3, 4, 2, 1]
	for tier in 4:
		var battles := pool.pool.filter(func(b: BattleStats): return b.battle_tier == tier)
		_expect(battles.size() >= minimum[tier], "%s tier %d needs %d battles, has %d" % [act_label, tier, minimum[tier], battles.size()])
		for battle: BattleStats in battles:
			_expect(battle.gold_reward_max >= battle.gold_reward_min and battle.gold_reward_min > 0, "%s battle gold range invalid" % act_label)
			for path in _battle_enemy_paths(battle):
				if tier == 3:
					_expect(path == (load(PATHS[boss_key]) as EnemyStats).ai.resource_path, "%s tier 3 must hold only the boss, found %s" % [act_label, path])
				else:
					var ok := false
					for key in allowed:
						if (load(PATHS[key]) as EnemyStats).ai.resource_path == path:
							ok = true
					_expect(ok, "%s tier %d battle holds a non-act enemy: %s" % [act_label, tier, path])
	pool.setup()
	for tier in 4:
		_expect(pool.get_random_battle_for_tier(tier) != null, "%s tier %d must never return null" % [act_label, tier])


func _check_pools() -> void:
	_check_pool_for("res://acts/act_2_ice.tres", ICE_ENEMIES, "krampus", "Act 2")
	_check_pool_for("res://acts/act_3_fire.tres", FIRE_ENEMIES, "fire_dragon", "Act 3")


# ---------------------------------------------------------------- Act 2

func _check_wolves() -> void:
	_reset_player()
	var handler := _new_handler()
	var alpha := await _spawn(handler, "snow_wolf_alpha")
	var a := await _spawn(handler, "snow_wolf")
	var b := await _spawn(handler, "snow_wolf")
	var bite := _act(a, "Bite") as MeleeAttackAction
	bite.dice_amount = 0
	var base: int = a.stats.attack
	_expect(bite.roll_damage() == base + 2, "pack bonus must add 2 with 2 other wolves, got %d (base %d)" % [bite.roll_damage(), base])
	_kill(b)
	await _wait(0.5)
	_expect(bite.roll_damage() == base + 1, "pack bonus must drop to +1 after a wolf dies")
	_kill(alpha)
	await _wait(0.5)
	_expect(bite.roll_damage() == base, "pack bonus must be 0 with no other wolf")
	await _done(handler)

	handler = _new_handler()
	alpha = await _spawn(handler, "snow_wolf_alpha")
	var pup := await _spawn(handler, "snow_wolf")
	var howl := _act(alpha, "Howl") as StatusAction
	_expect(howl.is_performable(), "Alpha must be able to Howl at the start")
	await _do(alpha, howl)
	_expect(_stacks(pup, "SpeedUp") == 1 and _stacks(alpha, "SpeedUp") == 1, "Howl must give every wolf 1 Speed Up")
	_expect(not howl.is_performable(), "no Howl right after Howling")
	for i in 3:
		Events.enemy_action_completed.emit(alpha)
	_expect(not howl.is_performable(), "no Howl within 4 actions")
	Events.enemy_action_completed.emit(alpha)
	_expect(howl.is_performable(), "Howl again after 4 actions")
	await _done(handler)


func _check_spider() -> void:
	_reset_player()
	var handler := _new_handler()
	var spider := await _spawn(handler, "ice_spider")
	spider.stats.attack = 4
	var bite := _act(spider, "CrystalBite") as MeleeAttackAction
	bite.dice_amount = 0
	_expect(bite.roll_damage() == 4, "bite on an unslowed player deals base damage, got %d" % bite.roll_damage())
	await _do(spider, _act(spider, "Web"))
	_expect(_stacks(_player, "SpeedDown") == 2, "Web must apply 2 Speed Down stacks")
	_expect(bite.roll_damage() == 6, "bite on a slowed player deals 50%% more (6), got %d" % bite.roll_damage())
	await _done(handler)


func _check_snow_golem() -> void:
	_reset_player()
	var handler := _new_handler()
	var golem := await _spawn(handler, "snow_golem")
	var pack := _act(golem, "PackSnow")
	for i in 5:
		await _do(golem, pack)
	_expect(golem.stats.block == 20, "five Pack Snow must reach 20 block, got %d" % golem.stats.block)
	_expect(golem.enemy_action_picker.get_action() == _act(golem, "Avalanche"), "Avalanche must be next at 20 block")
	await _do(golem, pack)
	_expect(golem.stats.block == 20, "Pack Snow must not exceed the cap")
	var before: int = _player.stats.health
	await _do(golem, _act(golem, "Avalanche"))
	_expect(golem.stats.block == 0, "Avalanche must clear the Golem's block")
	_expect(_player.stats.health < before, "Avalanche must hit the player")
	_expect(golem.enemy_action_picker.get_action() != _act(golem, "Avalanche"), "Avalanche must not repeat without block")
	await _done(handler)


func _check_banshee() -> void:
	_reset_player()
	var handler := _new_handler()
	var banshee := await _spawn(handler, "banshee")
	var wail := _act(banshee, "FrostWail") as StatusAction
	_expect(not wail.is_performable(), "no Frost Wail without Brittle")
	await _do(banshee, _act(banshee, "Haunt"))
	_expect(_status(_player, "Brittle") != null, "Haunt must apply Brittle")
	_expect(wail.is_performable(), "Frost Wail available against a Brittle player")
	_expect(banshee.enemy_action_picker.get_action() == wail, "Frost Wail takes priority when available")
	await _do(banshee, wail)
	_expect(_player.atb_mods.is_frozen(), "Frost Wail must freeze the player")
	for i in 5:
		Events.enemy_action_completed.emit(banshee)
	_expect(not wail.is_performable(), "no Wail on a frozen or immune player")
	for i in 130:
		_player.add_atb(0.05) # 6.5 s: freeze (1.5 s) and immunity (4 s) end
	_expect(_player.atb_mods.can_freeze(), "player can be frozen again after immunity")
	_expect(wail.is_performable(), "Wail returns once 5 actions passed and the player is freezable")
	await _do(banshee, wail)
	for i in 130:
		_player.add_atb(0.05)
	for i in 4:
		Events.enemy_action_completed.emit(banshee)
	_expect(not wail.is_performable(), "no Wail within 5 actions of the last")
	Events.enemy_action_completed.emit(banshee)
	_expect(wail.is_performable(), "Wail allowed 5 actions after the last")
	await _done(handler)


func _check_yeti() -> void:
	_reset_player()
	var handler := _new_handler()
	var yeti := await _spawn(handler, "yeti")
	var prepare := _act(yeti, "Prepare")
	var pound := _act(yeti, "GroundPound")
	await _do(yeti, prepare)
	_expect(yeti.special_state == TelegraphAction.STATE, "Prepare must set the warning state")
	_expect(yeti.sprite_2d.texture != yeti.stats.art, "Prepare must show the warning pose")
	_expect(yeti.enemy_action_picker.get_action() == pound, "Ground Pound must follow the warning")
	await _do(yeti, pound)
	_expect(_stacks(_player, "SpeedDown") == 2, "Ground Pound must apply 2 Speed Down")
	var roar := _act(yeti, "Roar")
	_expect(not roar.is_performable(), "no Roar above 50% health")
	yeti.stats.health = yeti.stats.max_health / 2
	_expect(yeti.enemy_action_picker.get_action() == roar, "Roar must be the next action at 50% health")
	await _do(yeti, roar)
	_expect(_stacks(yeti, "AttackUp") == 3, "Roar must give Attack Up (+3)")
	_expect(yeti.slow_immune, "Yeti must be slow-immune after the Roar")
	var slow: Status = load("res://statuses/status_speed_down.tres").duplicate()
	slow.stacks = 2
	yeti.status_handler.add_status(slow)
	await _frames()
	_expect(is_equal_approx(yeti.atb_rate_multiplier, 1.0), "Speed Down must have no effect after the Roar")
	_expect(not roar.is_performable(), "Roar must not repeat")
	await _done(handler)


func _check_krampus() -> void:
	_reset_player()
	var handler := _new_handler()
	var k := await _spawn(handler, "krampus")
	_expect(k.atb_mods.freeze_immune, "Krampus must be Freeze-immune")
	var freeze: Status = load("res://statuses/status_freeze.tres").duplicate()
	k.status_handler.add_status(freeze)
	_expect(is_equal_approx(k.atb_rate_multiplier, 1.0), "Freeze must not affect Krampus")

	var hits := [0]
	var on_hit := func(_source, _amount): hits[0] += 1
	Events.player_damaged.connect(on_hit)
	await _do(k, _act(k, "BirchSwitch"))
	Events.player_damaged.disconnect(on_hit)
	_expect(hits[0] == 2, "Birch Switch must hit twice, hit %d times" % hits[0])
	await _do(k, _act(k, "ChainPull"))
	_expect(_stacks(_player, "SpeedDown") == 3, "Chain Pull must apply 3 Speed Down")
	_expect(_status(_player, "Brittle") != null, "Chain Pull must apply Brittle")

	# One hit across both thresholds: Phase 2 first, Phase 3 after, each once.
	var phase2 := _act(k, "Phase2")
	var phase3 := _act(k, "Phase3")
	var summon := _act(k, "SummonWolves") as SummonAction
	_expect(not phase2.is_performable(), "no phase 2 above 50%")
	_expect(not summon.is_performable(), "no wolves in phase 1")
	k.stats.health = 20
	var base_speed: int = k.stats.speed
	_expect(k.enemy_action_picker.get_action() == phase2, "phase 2 first when both thresholds are crossed")
	await _do(k, phase2)
	_expect(k.phase == 2, "phase 2 reached")
	_expect(k.enemy_action_picker.get_action() == phase3, "phase 3 follows")
	await _do(k, phase3)
	_expect(k.phase == 3, "phase 3 reached")
	_expect(k.stats.speed == base_speed + 1, "phase 3 gives Speed Up once")
	_expect(not phase2.is_performable() and not phase3.is_performable(), "phase actions never repeat")

	# Wolves: 2 at once, cap, cooldown.
	_expect(summon.is_performable(), "wolves available in phase 2 and later")
	summon.duration = 0.05
	await _do(k, summon)
	var wolves := handler.get_minions_of(k)
	_expect(wolves.size() == 2, "Krampus must summon 2 wolves, got %d" % wolves.size())
	for i in 5:
		Events.enemy_action_completed.emit(k)
	_expect(not summon.is_performable(), "no summon while 2 wolves are alive")
	_kill(wolves[0])
	await _wait(0.5)
	_expect(summon.is_performable(), "resummon with 1 wolf after the cooldown")
	await _do(k, summon)
	_expect(not summon.is_performable(), "no summon right after a summon (cooldown and cap)")
	_kill(handler.get_minions_of(k)[0])
	await _wait(0.5)
	for i in 2:
		Events.enemy_action_completed.emit(k)
	_expect(not summon.is_performable(), "no summon within 3 actions of the last")

	# Winter's Wrath: warning, strike with Freeze, then two ordinary actions in between.
	var prepare := _act(k, "WrathPrepare")
	var strike := _act(k, "WrathStrike")
	for i in 6:
		Events.enemy_action_completed.emit(k)
	_expect(prepare.is_performable(), "Wrath is available in phase 3")
	await _do(k, prepare)
	_expect(k.special_state == TelegraphAction.STATE, "Wrath must show its warning first")
	_expect(k.enemy_action_picker.get_action() == strike, "the heavy hit is the next action after the warning")
	_reset_player()
	await _do(k, strike)
	_expect(_player.atb_mods.is_frozen(), "Winter's Wrath must freeze the player")
	_expect(not prepare.is_performable(), "no Wrath right after Wrath")
	Events.enemy_action_completed.emit(k)
	_expect(not prepare.is_performable(), "no Wrath after one ordinary action")
	Events.enemy_action_completed.emit(k)
	_expect(prepare.is_performable(), "Wrath is every third action")
	await _done(handler)


# ---------------------------------------------------------------- Act 3

func _check_campfire() -> void:
	_reset_player()
	var handler := _new_handler()
	var fire := await _spawn(handler, "campfire")
	var s1 := await _spawn(handler, "flames", fire)
	var spawn := _act(fire, "Spawn") as SummonAction
	spawn.duration = 0.05
	_expect(spawn.is_performable(), "Campfire spawns when fewer than 2 Spirits live")
	await _do(fire, spawn)
	_expect(handler.get_minions_of(fire).size() == 2, "second Spirit spawned")
	_expect(not spawn.is_performable(), "no spawn at 2 Spirits")
	_kill(s1)
	await _wait(0.5)
	_expect(not spawn.is_performable(), "no spawn within 2 actions of the last")
	Events.enemy_action_completed.emit(fire)
	Events.enemy_action_completed.emit(fire)
	_expect(spawn.is_performable(), "spawn again after 2 actions")

	var spirit: Enemy = handler.get_minions_of(fire)[0]
	var singe := _act(spirit, "Burn")
	await _do(spirit, singe)
	_expect(_status(_player, "Burn") != null, "Spirit attack must apply Burn")
	await _do(spirit, singe)
	_expect(_stacks(_player, "Burn") >= 0, "Spirit attack is repeatable")

	var stoke := _act(fire, "Stoke") as HealAlliesAction
	spirit.stats.health = 3
	_expect(stoke.is_performable(), "Stoke available while a Spirit is damaged")
	await _do(fire, stoke)
	_expect(spirit.stats.health == spirit.stats.max_health, "Stoke heals to full and not above, is %d" % spirit.stats.health)

	# Fizzle: the Campfire dies, the Spirits go after their next action, the battle empties.
	_expect(fire.stats.attack >= 1, "Campfire stats sane")
	_kill(fire)
	await _wait(0.5)
	for minion in handler.get_alive_enemies():
		_expect(minion.fizzling, "Spirits must fizzle when the Campfire dies")
		minion.reset_atb()
		minion.do_action()
	await _wait(2.5)
	_expect(handler.get_alive_enemies().is_empty(), "battle must end once the Campfire and Spirits are gone")
	await _done(handler)


func _check_salamander() -> void:
	_reset_player()
	var handler := _new_handler()
	var sal := await _spawn(handler, "fire_salamander")
	sal.stats.max_health = 500
	sal.stats.health = 500
	sal.stats.block = 0
	sal.take_damage(2, Modifier.Type.DMG_TAKEN)
	await _wait(0.3)
	_expect(_stacks(_player, "Scorch") == 1, "hit on a Salamander with its hide up must Scorch the player")
	for i in 3:
		Events.enemy_action_completed.emit(sal)
	sal.take_damage(2, Modifier.Type.DMG_TAKEN)
	await _wait(0.3)
	_expect(_stacks(_player, "Scorch") == 1, "no Scorch while the hide is down after the third action")
	sal.acting = true
	await _frames()
	sal.acting = false
	sal.take_damage(2, Modifier.Type.DMG_TAKEN)
	await _wait(0.3)
	_expect(_stacks(_player, "Scorch") == 2, "hide is back up once the Salamander acts again")
	await _done(handler)


func _check_imps() -> void:
	var handler := _new_handler()
	var imps: Array[Enemy] = []
	for i in 5:
		imps.append(await _spawn(handler, "fire_imp"))
	_kill(imps[0])
	await _wait(0.5)
	for i in range(1, 5):
		_expect(_stacks(imps[i], "SpeedUp") == 1, "imp %d must gain 1 Speed Up when an imp dies" % i)
	for i in range(1, 4):
		_kill(imps[i])
		await _wait(0.5)
	_expect(_stacks(imps[4], "SpeedUp") == 3, "Speed Up from Frenzy is capped at 3, got %d" % _stacks(imps[4], "SpeedUp"))
	await _done(handler)


func _check_warrior() -> void:
	_reset_player()
	var handler := _new_handler()
	var warrior := await _spawn(handler, "ashen_warrior")
	var rally := _act(warrior, "Rally") as StatusAction
	_expect(not rally.is_performable(), "no Rally without an ally")
	await _do(warrior, _act(warrior, "SunderStrike"))
	_expect(_status(_player, "Sunder") != null and _player.ignore_block_next_hit, "Sunder Strike must apply Sunder")
	var ally := await _spawn(handler, "fire_imp")
	_expect(rally.is_performable(), "Rally available with an ally")
	await _do(warrior, rally)
	_expect(_stacks(ally, "AttackUp") == 1, "Rally must give allies Attack Up")
	for i in 3:
		Events.enemy_action_completed.emit(warrior)
	_expect(not rally.is_performable(), "no Rally within 4 actions")
	Events.enemy_action_completed.emit(warrior)
	_expect(rally.is_performable(), "Rally after 4 actions")
	_kill(ally)
	await _wait(0.5)
	_expect(not rally.is_performable(), "no Rally when the ally is gone")
	await _done(handler)


func _check_phoenix() -> void:
	_reset_player()
	# Revival after 6 seconds at 60%, then a real second death.
	var handler := _new_handler()
	var phoenix := await _spawn(handler, "phoenix")
	_kill(phoenix)
	await _wait(0.5)
	_expect(is_instance_valid(phoenix) and not phoenix.is_queued_for_deletion(), "first lethal hit must leave an ash pile")
	_expect(phoenix.special_state == "ASH" and phoenix.stats.health == 5, "ash pile has 5 health")
	for i in 100:
		phoenix.add_atb(0.05) # 5 s
	_expect(phoenix.special_state == "ASH", "still ash before 6 seconds")
	_expect(phoenix.atb == 0.0, "the ash pile must not charge actions")
	for i in 30:
		phoenix.add_atb(0.05)
	_expect(phoenix.special_state == "", "Phoenix revives after 6 seconds")
	_expect(phoenix.stats.health == floori(phoenix.stats.max_health * 0.6), "revives with 60%% health, has %d" % phoenix.stats.health)
	_kill(phoenix)
	await _wait(0.5)
	_expect(not is_instance_valid(phoenix) or phoenix.is_queued_for_deletion(), "no second rebirth")
	await _done(handler)

	# Killing the ash pile ends it for good.
	handler = _new_handler()
	phoenix = await _spawn(handler, "phoenix")
	_kill(phoenix)
	await _wait(0.5)
	for i in 40:
		phoenix.add_atb(0.05)
	_kill(phoenix)
	await _wait(0.5)
	_expect(not is_instance_valid(phoenix) or phoenix.is_queued_for_deletion(), "killing the ash pile must kill the Phoenix for good")
	await _done(handler)

	# The hook alone: a vetoing callable survives once, dies the second time.
	handler = _new_handler()
	var plain := await _spawn(handler, "fire_imp")
	var vetoed := [false]
	plain.before_death = func():
		if vetoed[0]:
			return false
		vetoed[0] = true
		plain.stats.health = 2
		return true
	_kill(plain)
	await _wait(0.5)
	_expect(is_instance_valid(plain) and not plain.is_queued_for_deletion(), "veto must keep the enemy alive")
	_kill(plain)
	await _wait(0.5)
	_expect(not is_instance_valid(plain) or plain.is_queued_for_deletion(), "second lethal hit must kill")
	await _done(handler)


func _check_magma_golem() -> void:
	_reset_player()
	var handler := _new_handler()
	var golem := await _spawn(handler, "magma_golem")
	_expect(golem.stats.block == 15, "Magma Golem starts with 15 block, has %d" % golem.stats.block)
	var prepare := _act(golem, "Prepare")
	var slam := _act(golem, "Slam")
	await _do(golem, prepare)
	_expect(golem.stats.block == 23, "Prepare adds 8 block, has %d" % golem.stats.block)
	_expect(golem.special_state == TelegraphAction.STATE and golem.sprite_2d.texture != golem.stats.art, "Prepare must warn the player")
	_expect(golem.enemy_action_picker.get_action() == slam, "Slam follows Prepare")
	await _do(golem, slam)
	_expect(_status(_player, "Ashen") != null, "Slam must apply Ashen")
	await _done(handler)


func _check_dragon() -> void:
	_reset_player()
	var handler := _new_handler()
	var dragon := await _spawn(handler, "fire_dragon")
	_expect(dragon.atb_mods.freeze_immune, "Dragon must be Freeze-immune")
	var prepare := _act(dragon, "BreathPrepare")
	var breath := _act(dragon, "FireBreath")
	await _do(dragon, prepare)
	_expect(dragon.special_state == TelegraphAction.STATE, "Breath must be telegraphed")
	_expect(dragon.enemy_action_picker.get_action() == breath, "Breath is the next action after the warning")
	await _do(dragon, breath)
	_expect(_stacks(_player, "Scorch") == 2, "Fire Breath must apply 2 Scorch, got %d" % _stacks(_player, "Scorch"))

	# One hit across both thresholds: Roar first, phase 3 after, each once.
	var imp := await _spawn(handler, "fire_imp", dragon)
	var roar := _act(dragon, "Roar")
	var phase3 := _act(dragon, "Phase3")
	var summon := _act(dragon, "SummonImps") as SummonAction
	_expect(not roar.is_performable() and not summon.is_performable(), "no Roar or imps above 60%")
	dragon.stats.health = 20
	var base_speed: int = dragon.stats.speed
	_expect(dragon.enemy_action_picker.get_action() == roar, "Roar first when both thresholds are crossed")
	await _do(dragon, roar)
	_expect(_stacks(dragon, "AttackUp") == 1 and _stacks(imp, "AttackUp") == 1, "Roar must give every living enemy Attack Up")
	_expect(dragon.phase == 2, "phase 2 reached")
	_expect(dragon.enemy_action_picker.get_action() == phase3, "phase 3 follows the Roar")
	_expect(not roar.is_performable(), "Roar happens once")
	var scorch_before := _stacks(_player, "Scorch")
	Events.enemy_action_completed.emit(dragon)
	_expect(_stacks(_player, "Scorch") == scorch_before, "no Ember Field before phase 3")
	await _do(dragon, phase3)
	_expect(dragon.phase == 3, "phase 3 reached")
	_expect(dragon.stats.speed == base_speed + 2, "phase 3 gives Speed Up x2 once")
	_expect(not phase3.is_performable(), "phase 3 action happens once")
	scorch_before = _stacks(_player, "Scorch")
	Events.enemy_action_completed.emit(dragon)
	_expect(_stacks(_player, "Scorch") == scorch_before + 1, "Ember Field adds 1 Scorch per Dragon action")

	# Imps: cap 2, cooldown 4.
	summon.duration = 0.05
	_kill(imp)
	await _wait(0.5)
	_expect(summon.is_performable(), "imps available in phase 2 and later")
	await _do(dragon, summon)
	_expect(handler.get_minions_of(dragon).size() == 2, "Dragon summons up to 2 imps, has %d" % handler.get_minions_of(dragon).size())
	_kill(handler.get_minions_of(dragon)[0])
	await _wait(0.5)
	for i in 3:
		Events.enemy_action_completed.emit(dragon)
	_expect(not summon.is_performable(), "no summon within 4 actions of the last")
	Events.enemy_action_completed.emit(dragon)
	_expect(summon.is_performable(), "summon after the 4-action cooldown")
	await _do(dragon, summon)
	for i in 6:
		Events.enemy_action_completed.emit(dragon)
	_expect(handler.get_minions_of(dragon).size() == 2, "back to 2 imps")
	_expect(not summon.is_performable(), "no summon while 2 imps are alive")
	await _done(handler)


# ---------------------------------------------------------------- smoke battles

func _check_smoke_battles() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		node.queue_free()
	await _frames()
	var on_ready := func():
		await get_tree().create_timer(0.1).timeout
		Events.player_action_completed.emit()
	Events.player_atb_ready.connect(on_ready)
	var on_action := func(_e): _smoke_actions += 1
	Events.enemy_action_completed.connect(on_action)
	Engine.time_scale = 4.0
	for act_path in ["res://acts/act_2_ice.tres", "res://acts/act_3_fire.tres"]:
		var act: Act = load(act_path)
		for battle_stats: BattleStats in act.battle_stats_pool.pool:
			_smoke_actions = 0
			var relics := RELICS_SCENE.instantiate()
			add_child(relics)
			var battle := BATTLE_SCENE.instantiate() as Battle
			add_child(battle)
			var stats: CharacterStats = load("res://characters/player/player.tres").duplicate()
			stats.max_health = 9999
			battle.char_stats = stats
			battle.battle_stats = battle_stats
			battle.relics = relics
			battle.battle_background = act.battle_background
			battle.start_battle()
			await _wait(10.0) # 10 s of battle time (2.5 s real at 4x)
			var name := battle_stats.resource_path.get_file()
			_expect(battle.enemy_handler.get_child_count() > 0, "%s: enemies must be present" % name)
			_expect(_smoke_actions > 0, "%s: enemies must act during the smoke run" % name)
			battle.enemy_handler.child_order_changed.disconnect(battle._on_enemies_child_order_changed)
			battle.queue_free()
			relics.queue_free()
			await _frames()
	Engine.time_scale = 1.0
	Events.player_atb_ready.disconnect(on_ready)
	Events.enemy_action_completed.disconnect(on_action)
