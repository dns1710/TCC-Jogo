extends Node
## Headless guard for the item-availability spec: every non-starter item is in at
## least one drop pool, no item is flagged as a starter, ids are unique, the items
## this change added sit in their expected pools, and a new run starts itemless.
## Run: Godot --headless --path . res://tools/verify_item_pools.tscn
## Backs up and restores user://savegame.tres so a real save is never lost.

const SAVE := "user://savegame.tres"
const BACKUP := "user://savegame.item_check_backup"
const LEGACY_FOLDER := "res://relics/1old"

## Items added to the pools by fix-item-pools-and-starter: path -> pools that must hold them.
## (Gloves is common and the treasure chest never offers commons.)
const ADDED := {
	"res://relics/armor/slow.tres": ["reward", "treasure", "shop"],
	"res://relics/armor/barbarian.tres": ["reward", "treasure", "shop"],
	"res://relics/weapon/icy.tres": ["reward", "treasure", "shop"],
	"res://relics/trinket/shadow.tres": ["reward", "treasure", "shop"],
	"res://relics/trinket/receba.tres": ["reward", "shop"],
}

## Pool size after item-pool-expansion: common, uncommon, rare, mythic.
const EXPECTED_RARITY_COUNTS := [15, 21, 19, 8]
const EXPANSION := [
	"weapon/breaker_pick", "weapon/riposte_foil", "weapon/shatterglass_hammer", "weapon/cinderbrand",
	"weapon/bulwark_maul", "weapon/hunters_mercy", "weapon/frostfire_pike",
	"helmet/fur_lined_cap", "helmet/frostborn_circlet", "helmet/cracked_visor", "helmet/warden_visage",
	"armor/emberweave_tunic", "armor/sentinels_aegis", "armor/reactive_plate", "armor/mirrorscale_mail",
	"trinket/kindling_bundle", "trinket/pine_tar_gloves", "trinket/warding_talisman", "trinket/rime_bead",
	"trinket/hunters_snare", "trinket/carrion_thurible", "trinket/quicksilver_spurs",
	"trinket/phoenix_feather", "trinket/glass_heart",
]

var _errors: Array[String] = []


func _ready() -> void:
	var had_save := FileAccess.file_exists(SAVE)
	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))

	_check_items()
	await _check_chest_skips_commons()
	await _check_new_run()

	if had_save:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	if _errors.is_empty():
		print("ITEM POOL CHECK OK")
		get_tree().quit(0)
	else:
		print("ITEM POOL CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _scene_property(scene_path: String, property: String) -> Array[Relic]:
	var node := (load(scene_path) as PackedScene).instantiate()
	var result: Array[Relic] = []
	for relic in node.get(property):
		if relic != null:
			result.append(relic)
	node.free()
	return result


func _all_relics(folder: String, into: Array[Relic]) -> void:
	for sub in DirAccess.get_directories_at(folder):
		var sub_path := folder.path_join(sub)
		if sub_path == LEGACY_FOLDER:
			continue
		_all_relics(sub_path, into)
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".tres"):
			var relic := load(folder.path_join(file)) as Relic
			if relic:
				into.append(relic)


func _label(relic: Relic) -> String:
	return "%s (%s)" % [relic.relic_name, relic.resource_path.trim_prefix("res://relics/")]


func _in_pool(pool: Array[Relic], relic: Relic) -> bool:
	for candidate in pool:
		if candidate.resource_path == relic.resource_path:
			return true
	return false


# ---------------------------------------------------------------- items and pools

func _check_items() -> void:
	var pools := {
		"reward": _scene_property("res://scenes/run/run.tscn", "battle_relic_pool"),
		"treasure": _scene_property("res://scenes/treasure/treasure.tscn", "treasure_relic_pool"),
		"shop": _scene_property("res://scenes/shop/shop.tscn", "shop_relics"),
	}
	for name in pools:
		_expect(not pools[name].is_empty(), "%s pool is empty or could not be read" % name)

	var relics: Array[Relic] = []
	_all_relics("res://relics", relics)
	_expect(relics.size() >= 30, "expected to find the item resources, found %d" % relics.size())

	var ids := {}
	for relic in relics:
		_expect(not relic.id.is_empty(), "%s has no id" % _label(relic))
		if not relic.id.is_empty():
			_expect(not ids.has(relic.id), "%s reuses id '%s' (also %s)" % [_label(relic), relic.id, ids.get(relic.id, "")])
			ids[relic.id] = _label(relic)

		_expect(not relic.starter_relic, "%s is still flagged as a starter item, so it can never drop" % _label(relic))

		var found := false
		for name in pools:
			if _in_pool(pools[name], relic):
				found = true
		_expect(found, "%s is in no drop pool" % _label(relic))

	for path in ADDED:
		var relic := load(path) as Relic
		_expect(relic != null, "%s could not be loaded" % path)
		if relic == null:
			continue
		for name in ADDED[path]:
			_expect(_in_pool(pools[name], relic), "%s is missing from the %s pool" % [_label(relic), name])

	# item-pool-expansion: 24 new items, in every pool the rarity rules allow.
	var counts := [0, 0, 0, 0]
	for relic in relics:
		counts[relic.rarity] += 1
	_expect(counts == EXPECTED_RARITY_COUNTS, "rarity counts (common, uncommon, rare, mythic) are %s, expected %s" % [counts, EXPECTED_RARITY_COUNTS])
	for entry in EXPANSION:
		var relic := load("res://relics/%s.tres" % entry) as Relic
		_expect(relic != null, "%s could not be loaded" % entry)
		if relic == null:
			continue
		_expect(relic.icon != null, "%s has no icon" % _label(relic))
		_expect(relic.tooltip.length() > 10, "%s has no tooltip" % _label(relic))
		_check_tooltip_numbers(relic)
		_expect(_in_pool(pools["reward"], relic), "%s is missing from the reward pool" % _label(relic))
		_expect(_in_pool(pools["shop"], relic), "%s is missing from the shop pool" % _label(relic))
		if relic.rarity != Relic.Rarity.COMMON:
			_expect(_in_pool(pools["treasure"], relic), "%s is missing from the treasure pool" % _label(relic))



## The first tooltip line must state exactly the item's stat bonuses and weapon dice.
func _check_tooltip_numbers(relic: Relic) -> void:
	var first := relic.tooltip.split("\n")[0]
	var stats := {"BLOCK": relic.bonus_blk, "ATTACK": relic.bonus_atk, "SPEED": relic.bonus_spd}
	for stat in stats:
		var regex := RegEx.create_from_string("([+-]\\d+) " + stat)
		var found := regex.search(first)
		var stated := int(found.get_string(1)) if found else 0
		_expect(stated == stats[stat], "%s tooltip says %d %s but the item gives %d" % [_label(relic), stated, stat, stats[stat]])
	if relic.equip == Relic.Equip.WEAPON:
		var expected := "%dd%d weapon damage" % [relic.weapon_dice_amount, relic.weapon_dice_attack]
		_expect(first.begins_with(expected), "%s tooltip should start with '%s'" % [_label(relic), expected])


# ---------------------------------------------------------------- chests never offer commons

func _check_chest_skips_commons() -> void:
	var handler := load("res://scenes/relic_handler/relic_handler.tscn").instantiate() as RelicHandler
	add_child(handler)
	var treasure := load("res://scenes/treasure/treasure.tscn").instantiate() as Treasure
	add_child(treasure)
	await get_tree().process_frame
	treasure.relic_handler = handler
	treasure.char_stats = load("res://characters/player/player.tres").create_instance()

	var commons: Array[Relic] = []
	_all_relics("res://relics", commons)
	commons = commons.filter(func(r: Relic): return r.rarity == Relic.Rarity.COMMON)
	_expect(not commons.is_empty(), "expected some common items to test with")

	treasure.treasure_relic_pool = commons
	for i in 20:
		treasure.generate_relic()
		_expect(treasure.found_relic == null, "a chest must never offer a common item, offered %s" % treasure.found_relic)

	treasure.queue_free()
	handler.queue_free()


# ---------------------------------------------------------------- new run

func _check_new_run() -> void:
	var run := load("res://scenes/run/run.tscn").instantiate() as Run
	add_child(run)
	for i in 3:
		await get_tree().process_frame

	_expect(run.relic_handler.get_all_relics().is_empty(), "a new run must start with no relics, found %d" % run.relic_handler.get_all_relics().size())
	_expect(run.relic_handler.get_equipped_relics().is_empty(), "a new run must start with nothing equipped")

	var base := load("res://characters/player/player.tres") as CharacterStats
	var stats := run.character
	_expect(stats.max_attack == base.max_attack and stats.max_block == base.max_block and stats.max_speed == base.max_speed,
		"a new run must use the character's base stats (attack %d, block %d, speed %d)" % [stats.max_attack, stats.max_block, stats.max_speed])

	run.queue_free()
