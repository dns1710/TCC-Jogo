extends Node
## Headless check of item-pool-expansion: Ward, the engine hooks (status events, player attacked,
## slow immunity, lethal veto, turn-bar carry-over) and the behaviour of the 24 new items.
## Run: Godot --headless --path . res://tools/verify_item_pool_expansion.tscn

const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HANDLER_SCENE := preload("res://scenes/relic_handler/relic_handler.tscn")
const ATTACK := preload("res://custom_resources/actions/action_attack.tres")
const BLOCK := preload("res://custom_resources/actions/action_block.tres")
const STATUS_DIR := "res://statuses/"
const DEBUFFS := {
	"Freeze": "status_freeze", "Brittle": "status_brittle", "Sunder": "status_sunder", "Scorch": "status_scorch",
	"Ashen": "status_ashen", "SpeedDown": "status_speed_down", "AttackDown": "status_attack_down",
	"Poison": "status_poison", "Burn": "status_burn",
}
const ALL_ITEMS := [
	"weapon/breaker_pick", "weapon/riposte_foil", "weapon/shatterglass_hammer", "weapon/cinderbrand",
	"weapon/bulwark_maul", "weapon/hunters_mercy", "weapon/frostfire_pike",
	"helmet/fur_lined_cap", "helmet/frostborn_circlet", "helmet/cracked_visor", "helmet/warden_visage",
	"armor/emberweave_tunic", "armor/sentinels_aegis", "armor/reactive_plate", "armor/mirrorscale_mail",
	"trinket/kindling_bundle", "trinket/pine_tar_gloves", "trinket/warding_talisman", "trinket/rime_bead",
	"trinket/hunters_snare", "trinket/carrion_thurible", "trinket/quicksilver_spurs",
	"trinket/phoenix_feather", "trinket/glass_heart",
]

var _errors: Array[String] = []
var player: Player
var handler: RelicHandler
var enemies: Array[Enemy] = []
var _added: Array = []
var _absorbed: Array = []
var _removed: Array = []
var _died := 0
var _checks := 0


func _ready() -> void:
	Events.status_added.connect(func(o, s): _added.append([o, s.id]))
	Events.status_absorbed.connect(func(o, s): _absorbed.append([o, s.id]))
	Events.status_removed.connect(func(o, s): _removed.append([o, s.id]))
	Events.player_died.connect(func(): _died += 1)
	await _run()
	if _errors.is_empty():
		print("ITEM POOL EXPANSION CHECK OK (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("ITEM POOL EXPANSION CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_errors.append(message)


func _frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


func _settle(seconds := 0.45) -> void:
	await get_tree().create_timer(seconds).timeout


# ------------------------------------------------------------------ harness

func _setup(enemy_count := 1, health := 500) -> void:
	_teardown()
	player = PLAYER_SCENE.instantiate() as Player
	add_child(player)
	player.stats = load("res://characters/player/player.tres").create_instance()
	player.stats.max_health = 100
	player.stats.health = 100
	player.stats.block = 0
	handler = HANDLER_SCENE.instantiate() as RelicHandler
	add_child(handler)
	handler.character_stats = player.stats
	for i in enemy_count:
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		add_child(enemy)
		enemy.stats = load("res://enemies/zscout/zscout.tres")
		enemy.stats.max_health = health
		enemy.stats.health = health
		enemy.stats.block = 0
		enemies.append(enemy)
	_added.clear()
	_absorbed.clear()
	_removed.clear()
	await _frames(2)


func _teardown() -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.free()
	enemies.clear()
	if is_instance_valid(handler):
		handler.free()
	if is_instance_valid(player):
		player.free()
	player = null
	handler = null


## Equips an item like a run does and activates it like the start of a combat.
func _equip(path: String) -> Relic:
	var relic := load("res://relics/%s.tres" % path) as Relic
	handler.add_relic(relic, false)
	handler.equip_relic(relic)
	for ui: RelicUI in handler.relics.get_children():
		if ui.relic == relic:
			relic.activate_relic(ui)
	return relic


func _status(file: String, stacks := 0) -> Status:
	var status: Status = load(STATUS_DIR + file + ".tres").duplicate()
	if stacks > 0:
		status.stacks = stacks
	return status


func _apply(actor: Node, file: String, stacks := 0) -> void:
	actor.status_handler.add_status(_status(file, stacks))


func _has(actor: Node, id: String) -> bool:
	return ItemFx.has_status(actor, id)


func _stacks(actor: Node, id: String) -> int:
	var status := ItemFx.get_status(actor, id)
	return status.stacks if status else 0


func _watch(enemy: Enemy) -> Array:
	var amounts := []
	enemy.damage_received.connect(func(amount: int, _m): amounts.append(amount))
	return amounts


func _attack(target: Node) -> void:
	ATTACK.use_action([target], player.stats)


func _block() -> void:
	BLOCK.use_action([player], player.stats)


func _run() -> void:
	await _check_ward()
	await _check_brittle()
	await _check_hooks()
	await _check_commons_uncommons()
	await _check_rares()
	await _check_mythics()
	await _check_signal_hygiene()
	_teardown()


# ------------------------------------------------------------------ Ward

func _check_ward() -> void:
	await _setup()
	for id in DEBUFFS:
		_apply(player, "status_ward")
		_added.clear()
		_absorbed.clear()
		_apply(player, DEBUFFS[id])
		_expect(not _has(player, id), "Ward did not stop %s" % id)
		_expect(not _has(player, "Ward"), "Ward stayed after absorbing %s" % id)
		_expect(_absorbed.size() == 1 and _absorbed[0][1] == id, "absorbed event for %s fired %d times" % [id, _absorbed.size()])
		_expect(_added.filter(func(a): return a[1] == id).is_empty(), "%s was announced as added after Ward negated it" % id)
	_expect(player.atb_rate_multiplier == 1.0, "a negated debuff still changed the turn bar")

	_apply(player, "status_ward")
	_apply(player, "status_attack_up")
	_expect(_has(player, "AttackUp") and _has(player, "Ward"), "a buff must not consume Ward")

	_apply(player, "status_ward")
	var wards := 0
	for ui: StatusUI in player.status_handler.get_children():
		if ui.status.id == "Ward":
			wards += 1
	_expect(wards == 1, "Ward stacked (%d)" % wards)

	_apply(player, "status_speed_down", 1)
	_apply(player, "status_scorch", 1)
	_expect(not _has(player, "SpeedDown") and _has(player, "Scorch"), "one Ward must absorb exactly one debuff")

	_apply(player, "status_ward")
	for i in 5:
		player.add_atb(1.0)
	_expect(_has(player, "Ward"), "Ward expired by itself")

	# Both application routes end in add_status; an enemy owns the same handler.
	_apply(enemies[0], "status_ward")
	var effect := StatusEffect.new()
	effect.status = _status("status_freeze")
	effect.execute([enemies[0]])
	_expect(not enemies[0].atb_mods.is_frozen(), "Ward did not stop Freeze through StatusEffect")

	# Tooltip and icon.
	var ward := _status("status_ward")
	_expect(ward.get_tooltip().to_lower().contains("debuff"), "Ward tooltip does not mention debuffs")
	_expect(ward.icon != null, "Ward has no icon")


# ------------------------------------------------------------------ Brittle rolls one extra die

func _check_brittle() -> void:
	await _setup()
	for actor: Node in [player, enemies[0]]:
		var tag := " (%s)" % ("player" if actor == player else "enemy")
		_apply(actor, "status_brittle")
		_expect(_has(actor, "Brittle"), "Brittle was not applied" + tag)
		var seen := []
		actor.damage_received.connect(func(amount: int, _m): seen.append(amount))
		# Flat hits (no die) neither use nor spend Brittle.
		actor.take_damage(5, Modifier.Type.DMG_TAKEN)
		await _settle(0.1)
		_expect(seen == [5] and _has(actor, "Brittle"), "a flat hit must not touch Brittle, got %s" % [seen] + tag)
		# Ticks that skip modifiers do not spend it either.
		actor.take_damage(3, Modifier.Type.NO_MODIFIER, null, 6)
		await _settle(0.1)
		_expect(_has(actor, "Brittle"), "a no-modifier hit spent Brittle" + tag)
		# A d6 hit rolls one more d6: 5 -> 6..11, then Brittle ends.
		seen.clear()
		actor.take_damage(5, Modifier.Type.DMG_TAKEN, null, 6)
		await _settle(0.2)
		_expect(seen.size() == 1 and seen[0] >= 6 and seen[0] <= 11, "Brittle should add one d6 (6..11), got %s" % [seen] + tag)
		_expect(not _has(actor, "Brittle"), "Brittle should end after the die hit" + tag)
		seen.clear()
		actor.take_damage(5, Modifier.Type.DMG_TAKEN, null, 6)
		await _settle(0.1)
		_expect(seen == [5], "the second die hit must not be boosted, got %s" % [seen] + tag)
	# The weapon attack reports its die, so a Brittle enemy loses Brittle to a normal attack.
	await _setup()
	_apply(enemies[0], "status_brittle")
	_attack(enemies[0])
	await _settle(0.3)
	_expect(not _has(enemies[0], "Brittle"), "a weapon attack should spend Brittle")


# ------------------------------------------------------------------ hooks

func _check_hooks() -> void:
	await _setup(2)
	# status added / removed events
	_added.clear()
	_apply(player, "status_scorch", 2)
	_expect(_added.size() == 1 and _added[0][0] == player and _added[0][1] == "Scorch", "status_added not announced for Scorch")
	_apply(player, "status_scorch", 1)
	_expect(_added.size() == 2, "stacking Scorch must announce again")
	_removed.clear()
	player.status_handler.remove_status("Scorch")
	_expect(not _has(player, "Scorch"), "remove_status left Scorch on the player")
	_expect(_removed.size() == 1 and _removed[0][1] == "Scorch", "status_removed not announced")
	_removed.clear()
	player.status_handler.remove_status("Scorch")
	_expect(_removed.is_empty(), "removing a missing status emitted an event")

	# player attacked event reaches every item slot, and weapons are unaffected.
	var seen := []
	var listener := func(targets: Array, damage: int): seen.append([targets.size(), damage])
	Events.player_attacked.connect(listener)
	_equip("weapon/riposte_foil")
	_attack(enemies[0])
	await _settle()
	Events.player_attacked.disconnect(listener)
	_expect(seen.size() == 1 and seen[0][0] == 1 and seen[0][1] >= 1, "player_attacked should fire once per attack, got %s" % [seen])

	# slow immunity
	var slow := _status("status_speed_down", 2)
	player.slow_immune = true
	player.status_handler.add_status(slow)
	_expect(is_equal_approx(player.atb_rate_multiplier, 1.0), "slow-immune player was slowed")
	player.slow_immune = false

	# turn-bar carry-over
	player.request_atb_start(0.25)
	player.reset_atb()
	_expect(is_equal_approx(player.atb, 5.0), "carry-over of 25%% should start the bar at 5, got %s" % player.atb)
	player.reset_atb()
	_expect(is_equal_approx(player.atb, 0.0), "carry-over must be used once")
	player.request_atb_start(0.8)
	player.request_atb_start(0.8)
	player.reset_atb()
	_expect(player.can_act and is_equal_approx(player.atb, ATBConfig.MAX), "carry-over past 100%% must cap at a full bar")
	player.reset_atb()

	# lethal veto
	_died = 0
	player.before_death = func() -> bool:
		player.stats.health = 7
		return true
	player.take_damage(999, Modifier.Type.NO_MODIFIER)
	await _settle()
	_expect(is_instance_valid(player) and player.stats.health == 7 and _died == 0, "veto should keep the player alive at 7")
	player.before_death = Callable()
	player.take_damage(999, Modifier.Type.NO_MODIFIER)
	await _settle()
	_expect(_died == 1, "without a veto the player must die")
	player = null


# ------------------------------------------------------------------ common and uncommon

func _check_commons_uncommons() -> void:
	# Kindling Bundle
	await _setup(2)
	_equip("trinket/kindling_bundle")
	_block()
	var total := _stacks(enemies[0], "Scorch") + _stacks(enemies[1], "Scorch")
	_expect(total == 1, "Kindling Bundle should add exactly 1 Scorch, got %d" % total)

	# Pine-Tar Gloves
	await _setup()
	_equip("trinket/pine_tar_gloves")
	var hits := _watch(enemies[0])
	_attack(enemies[0])
	await _settle()
	_expect(hits.size() == 1, "Pine-Tar Gloves hit a clean target (%s)" % [hits])
	hits.clear()
	_apply(enemies[0], "status_poison")
	_attack(enemies[0])
	await _settle()
	_expect(hits.size() == 2 and hits[1] >= 1 and hits[1] <= 4, "Pine-Tar Gloves should add 1d4 on an already Poisoned enemy, got %s" % [hits])
	hits.clear()
	enemies[0].status_handler.remove_status("Poison")
	_apply(enemies[0], "status_speed_down", 1)
	_attack(enemies[0])
	await _settle()
	_expect(hits.size() == 2, "Pine-Tar Gloves should count any debuff (Speed Down), got %s" % [hits])
	# A debuff applied by the hit itself must not count.
	await _setup()
	_equip("trinket/pine_tar_gloves")
	_equip("weapon/poison_dagger")
	hits = _watch(enemies[0])
	_attack(enemies[0])
	await _settle()
	_expect(hits.size() == 1 and _has(enemies[0], "Poison"), "Pine-Tar Gloves added damage for a debuff the hit itself applied, got %s" % [hits])
	hits.clear()
	_attack(enemies[0])
	await _settle()
	_expect(hits.size() == 2, "Pine-Tar Gloves should add damage once the target already had Poison, got %s" % [hits])

	# Fur-Lined Cap
	await _setup()
	_equip("helmet/fur_lined_cap")
	_apply(player, "status_speed_down", 3)
	_expect(is_equal_approx(player.atb_rate_multiplier, 1.0), "Fur-Lined Cap did not stop Speed Down")

	# Breaker Pick
	await _setup()
	_equip("weapon/breaker_pick")
	enemies[0].stats.block = 60
	_attack(enemies[0])
	await _settle()
	_expect(_has(enemies[0], "Sunder"), "Breaker Pick should Sunder a target that kept block")
	await _setup()
	_equip("weapon/breaker_pick")
	_attack(enemies[0])
	await _settle()
	_expect(not _has(enemies[0], "Sunder"), "Breaker Pick Sundered a target without block")

	# Riposte Foil
	await _setup()
	var foil := _equip("weapon/riposte_foil")
	_expect(foil.get_weapon_bonus_damage() == 0, "Riposte Foil has a bonus before any Block")
	_block()
	var bonus := foil.get_weapon_bonus_damage()
	_expect(bonus >= 1 and bonus <= 6, "Riposte Foil bonus after Block should be 1d6, got %d" % bonus)
	_expect(foil.get_weapon_bonus_damage() == 0, "Riposte Foil bonus must be used once")

	# Frostborn Circlet
	await _setup()
	_equip("helmet/frostborn_circlet")
	_apply(player, "status_freeze")
	_expect(player.atb_mods.is_frozen(), "test setup: player should be frozen")
	for i in 40:
		player.add_atb(0.05)
	_expect(_stacks(player, "AttackUp") == 1, "Frostborn Circlet should grant 1 Attack Up on thaw, got %d" % _stacks(player, "AttackUp"))

	# Warding Talisman
	await _setup()
	_equip("trinket/warding_talisman")
	_expect(_has(player, "Ward"), "Warding Talisman did not give Ward")

	# Emberweave Tunic
	await _setup()
	_equip("armor/emberweave_tunic")
	player.stats.block = 0
	_apply(player, "status_scorch", 2)
	_expect(player.stats.block >= 2 and player.stats.block <= 8, "Emberweave Tunic should give 1d4 block per Scorch stack (2..8), got %d" % player.stats.block)

	# Rime Bead
	await _setup()
	_equip("trinket/rime_bead")
	_attack(enemies[0])
	await _settle()
	_expect(not _has(enemies[0], "Brittle"), "Rime Bead made an unslowed enemy Brittle")
	_apply(enemies[0], "status_speed_down", 1)
	_attack(enemies[0])
	await _settle()
	_expect(_has(enemies[0], "Brittle"), "Rime Bead should make a slowed enemy Brittle")

	# Hunter's Snare
	await _setup(2)
	_equip("trinket/hunters_snare")
	for e in enemies:
		_expect(_stacks(e, "SpeedDown") == 1, "Hunter's Snare should give 1 Speed Down, got %d" % _stacks(e, "SpeedDown"))


# ------------------------------------------------------------------ rare

func _check_rares() -> void:
	# Shatterglass Hammer
	await _setup()
	_equip("weapon/shatterglass_hammer")
	for i in 3:
		_attack(enemies[0])
	await _settle()
	_expect(not enemies[0].atb_mods.is_frozen(), "Shatterglass froze before the fourth attack")
	_attack(enemies[0])
	await _settle(0.2)
	_expect(enemies[0].atb_mods.is_frozen(), "Shatterglass fourth attack should Freeze")
	var hits := _watch(enemies[0])
	_attack(enemies[0])
	await _settle(0.2)
	_expect(_has(enemies[0], "Brittle") and hits.size() == 2, "Shatterglass should shatter a Frozen enemy (Brittle, extra hit), got %s" % [hits])
	_expect(not enemies[0].atb_mods.is_frozen() and not enemies[0].atb_mods.can_freeze(), "the shatter should end the Freeze and start its immunity")
	hits.clear()
	_attack(enemies[0])
	await _settle(0.2)
	_expect(hits.size() == 1, "a shattered enemy must not shatter again, got %s" % [hits])
	await _setup()
	_equip("weapon/shatterglass_hammer")
	enemies[0].atb_mods.freeze_immune = true
	for i in 4:
		_attack(enemies[0])
	await _settle(0.2)
	_expect(_has(enemies[0], "Brittle") and not enemies[0].atb_mods.is_frozen(), "Shatterglass boss fallback should be Brittle, not Freeze")

	# Cinderbrand
	await _setup()
	_equip("weapon/cinderbrand")
	for i in 3:
		_attack(enemies[0])
	await _settle(0.2)
	_expect(_stacks(enemies[0], "Scorch") == 3, "Cinderbrand should build 3 Scorch, got %d" % _stacks(enemies[0], "Scorch"))
	hits = _watch(enemies[0])
	_attack(enemies[0])
	await _settle(0.2)
	var detonation := 0
	for h in hits:
		if h >= 3 and h <= 12:
			detonation = h
	_expect(detonation > 0 and hits.size() == 2 and not _has(enemies[0], "Scorch"), "Cinderbrand should detonate 3 Scorch for 3d4 and clear it, got %s" % [hits])

	# Bulwark Maul
	await _setup()
	var maul := _equip("weapon/bulwark_maul")
	player.stats.block = 4
	_expect(maul.get_weapon_bonus_damage() == 0, "Bulwark Maul gave a bonus below 5 block")
	player.stats.block = 12
	var maul_bonus := maul.get_weapon_bonus_damage()
	_expect(maul_bonus >= 2 and maul_bonus <= 8, "Bulwark Maul with 12 block should roll 2d4, got %d" % maul_bonus)
	_expect(player.stats.block == 12, "Bulwark Maul spent block")
	player.stats.block = 60
	maul_bonus = maul.get_weapon_bonus_damage()
	_expect(maul_bonus >= 3 and maul_bonus <= 12, "Bulwark Maul must cap at 3d4, got %d" % maul_bonus)

	# Cracked Visor
	await _setup()
	_equip("helmet/cracked_visor")
	hits = _watch(enemies[0])
	_attack(enemies[0])
	await _settle(0.2)
	_expect(hits.size() == 1, "Cracked Visor added damage while not Brittle")
	hits.clear()
	_apply(player, "status_brittle")
	_attack(enemies[0])
	await _settle(0.2)
	_expect(hits.size() == 2 and hits[1] >= 1 and hits[1] <= 8, "Cracked Visor should add 1d8 while Brittle, got %s" % [hits])

	# Sentinel's Aegis
	await _setup()
	_equip("armor/sentinels_aegis")
	_expect(_has(player, "Ward"), "Sentinel's Aegis should start with Ward")
	player.status_handler.remove_status("Ward")
	_block()
	_block()
	_expect(not _has(player, "Ward"), "Aegis regained Ward before the third Block")
	_block()
	_expect(_has(player, "Ward"), "Aegis should regain Ward on the third Block")

	# Carrion Thurible
	await _setup(2, 100)
	_equip("trinket/carrion_thurible")
	player.stats.health = 50
	_apply(enemies[0], "status_poison")
	enemies[0].take_damage(999, Modifier.Type.NO_MODIFIER)
	await _settle(0.5)
	_expect(_has(enemies[1], "Poison"), "Carrion Thurible should pass Poison on")
	_expect(player.stats.health == 50, "Carrion Thurible must not heal, got %d" % player.stats.health)
	await _setup(4, 100)
	_equip("trinket/carrion_thurible")
	_apply(enemies[0], "status_poison")
	_apply(enemies[0], "status_scorch", 2)
	enemies[0].take_damage(999, Modifier.Type.NO_MODIFIER)
	await _settle(0.5)
	var poisoned := enemies.slice(1).filter(func(e): return _has(e, "Poison")).size()
	var scorched := enemies.slice(1).filter(func(e): return _stacks(e, "Scorch") == 2).size()
	_expect(poisoned == 1 and scorched == 1, "Carrion Thurible should pass the statuses to exactly one random enemy, got %d poisoned and %d scorched" % [poisoned, scorched])

	# Quicksilver Spurs
	await _setup()
	_equip("trinket/quicksilver_spurs")
	_attack(enemies[0])
	player.reset_atb()
	_expect(is_equal_approx(player.atb, 0.0), "Spurs gave tempo on an unslowed enemy")
	_apply(enemies[0], "status_speed_down", 1)
	_attack(enemies[0])
	player.reset_atb()
	_expect(is_equal_approx(player.atb, 5.0), "Spurs should start the next bar at 25%%, got %s" % player.atb)

	# Reactive Plate
	await _setup()
	_equip("armor/reactive_plate")
	player.stats.block = 5
	hits = _watch(enemies[0])
	player.take_damage(3, Modifier.Type.DMG_TAKEN, enemies[0])
	await _settle(0.2)
	_expect(hits.is_empty() and not _has(enemies[0], "Brittle"), "Reactive Plate fired without breaking block")
	player.stats.block = 5
	player.take_damage(8, Modifier.Type.DMG_TAKEN, enemies[0])
	await _settle(0.2)
	_expect(hits.size() == 1 and hits[0] >= 2 and hits[0] <= 8 and _has(enemies[0], "Brittle"),
		"Reactive Plate should hit the attacker for 2d4 and make it Brittle, got %s" % [hits])


# ------------------------------------------------------------------ mythic

func _check_mythics() -> void:
	# Mirrorscale Mail
	await _setup(2)
	_equip("armor/mirrorscale_mail")
	enemies[1].atb_mods.freeze_immune = true
	_expect(_has(player, "Ward"), "Mirrorscale Mail should start with Ward")
	_apply(player, "status_freeze")
	_expect(not player.atb_mods.is_frozen(), "Mirrorscale Mail did not stop Freeze")
	_expect(enemies[0].atb_mods.is_frozen(), "Mirrorscale Mail should mirror Freeze onto enemies")
	_expect(not enemies[1].atb_mods.is_frozen(), "Mirrorscale Mail froze a freeze-immune enemy")
	Events.player_action_completed.emit()
	_expect(not _has(player, "Ward"), "Mirrorscale Ward returned too early")
	Events.player_action_completed.emit()
	_expect(_has(player, "Ward"), "Mirrorscale Ward should return after 2 actions")

	# Phoenix Feather
	await _setup(2, 100)
	_equip("trinket/phoenix_feather")
	_died = 0
	player.take_damage(999, Modifier.Type.NO_MODIFIER)
	await _settle(0.5)
	_expect(is_instance_valid(player) and _died == 0 and player.stats.health == 30, "Phoenix Feather should leave the player at 30, got %s" % player.stats.health)
	for e in enemies:
		_expect(_stacks(e, "Scorch") == 1, "Phoenix Feather should give 1 Scorch, got %d" % _stacks(e, "Scorch"))
	_expect(not handler.has_relic("PhoenixFeather") and not handler.is_equipped(load("res://relics/trinket/phoenix_feather.tres")), "Phoenix Feather should be removed from the inventory after it triggers")
	player.take_damage(999, Modifier.Type.NO_MODIFIER)
	await _settle(0.5)
	_expect(_died == 1, "Phoenix Feather must only save the player once")
	player = null

	# Hunter's Mercy
	await _setup(1, 100)
	_equip("weapon/hunters_mercy")
	enemies[0].stats.health = 25
	_attack(enemies[0])
	await _settle(0.6)
	_expect(not is_instance_valid(enemies[0]) or enemies[0].is_queued_for_deletion(), "Hunter's Mercy should execute an enemy under 30%")
	_expect(player.atb >= ATBConfig.MAX * 0.5 - 0.01, "Hunter's Mercy kill should raise the bar to 50%%, got %s" % player.atb)
	await _setup(1, 100)
	_equip("weapon/hunters_mercy")
	enemies[0].stats.freeze_immune = true
	enemies[0].stats.health = 25
	var boss_hits := _watch(enemies[0])
	_attack(enemies[0])
	await _settle(0.6)
	_expect(is_instance_valid(enemies[0]) and not enemies[0].is_queued_for_deletion(), "Hunter's Mercy executed a boss")
	_expect(boss_hits.size() == 2, "Hunter's Mercy should add 50%% damage on a boss under 30%%, got %s" % [boss_hits])

	# Frostfire Pike
	await _setup()
	_equip("weapon/frostfire_pike")
	_attack(enemies[0])
	await _settle(0.2)
	_expect(_stacks(enemies[0], "Scorch") == 1 and not _has(enemies[0], "SpeedDown"), "Pike's first hit should apply 1 Scorch")
	_expect(not _has(enemies[0], "Brittle"), "Pike shocked a target holding only Scorch")
	_attack(enemies[0])
	await _settle(0.2)
	_expect(_stacks(enemies[0], "SpeedDown") == 1, "Pike's second hit should apply 1 Speed Down")
	_expect(_has(enemies[0], "Brittle") and _has(enemies[0], "Sunder"), "Pike should shock a target with Scorch and Speed Down")
	# The shock fires once: clear it and hit again, it must not come back while both statuses stay.
	enemies[0].status_handler.remove_status("Brittle")
	enemies[0].status_handler.remove_status("Sunder")
	_attack(enemies[0])
	await _settle(0.2)
	_attack(enemies[0])
	await _settle(0.2)
	_expect(not _has(enemies[0], "Brittle") and not _has(enemies[0], "Sunder"), "Pike shocked a target that still held both statuses")
	# After Speed Down wears off the shock can happen again.
	enemies[0].status_handler.remove_status("SpeedDown")
	_attack(enemies[0])
	await _settle(0.2)
	_expect(not _has(enemies[0], "Brittle"), "Pike shocked without both statuses")
	_attack(enemies[0])
	await _settle(0.2)
	_expect(_has(enemies[0], "Brittle") and _has(enemies[0], "Sunder"), "Pike should shock again after a status wore off")

	# Glass Heart
	await _setup()
	_equip("trinket/glass_heart")
	_expect(_has(player, "Brittle"), "Glass Heart should start Brittle")
	player.take_damage(1, Modifier.Type.DMG_TAKEN, null, 6)
	await _settle(0.3)
	_expect(not _has(player, "Brittle"), "the hit should consume Brittle")
	Events.player_action_completed.emit()
	Events.player_action_completed.emit()
	_expect(not _has(player, "Brittle"), "Brittle returned too early")
	Events.player_action_completed.emit()
	_expect(_has(player, "Brittle"), "Glass Heart should bring Brittle back 3 actions later")

	# Warden's Visage
	await _setup()
	_equip("helmet/warden_visage")
	_apply(enemies[0], "status_scorch", 2)
	_expect(_stacks(enemies[0], "Scorch") == 3, "Warden's Visage should make 2 Scorch 3, got %d" % _stacks(enemies[0], "Scorch"))
	_apply(enemies[0], "status_speed_down", 2)
	_expect(_stacks(enemies[0], "SpeedDown") == 3, "Warden's Visage should make 2 Speed Down 3")
	_apply(enemies[0], "status_attack_up", 2)
	_expect(_stacks(enemies[0], "AttackUp") == 2, "Warden's Visage amplified a buff")


# ------------------------------------------------------------------ signals do not leak or double up

func _check_signal_hygiene() -> void:
	var signals: Array[Signal] = [
		Events.player_attacked, Events.player_damaged, Events.player_action_completed, Events.action_used,
		Events.status_added, Events.status_removed, Events.status_absorbed, Events.enemy_died,
	]
	for path in ALL_ITEMS:
		await _setup()
		var relic := _equip(path)
		var ui: RelicUI
		for candidate: RelicUI in handler.relics.get_children():
			if candidate.relic == relic:
				ui = candidate
		var first := _connections_to(relic, signals)
		relic.activate_relic(ui)
		var second := _connections_to(relic, signals)
		_expect(first == second, "%s connects again on a second combat (%d -> %d)" % [path, first, second])
		handler.unequip_relic_instance(relic)
		await _frames(2)
		_expect(_connections_to(relic, signals) == 0, "%s keeps %d signal connections after unequip" % [path, _connections_to(relic, signals)])


func _connections_to(relic: Relic, signals: Array[Signal]) -> int:
	var count := 0
	for sig in signals:
		for connection in sig.get_connections():
			if connection["callable"].get_object() == relic:
				count += 1
	return count
