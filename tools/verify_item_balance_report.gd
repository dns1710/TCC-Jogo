extends Node
## Headless guard for the item-balance-report spec: every relic outside relics/1old is listed,
## stat totals count negatives, weapon averages are right, budget flags and data warnings fire,
## consumables and statuses are detected, and the report output is complete.
## Run: Godot --headless --path . res://tools/verify_item_balance_report.tscn

const Report := preload("res://tools/report_item_balance.gd")

var _errors: Array[String] = []


func _ready() -> void:
	var relics := Report.load_relics()
	_expect(relics.size() == 63, "expected 63 relics, found %d" % relics.size())
	for relic in relics:
		_expect(not relic.resource_path.contains("/1old/"), "retired relic listed: %s" % relic.resource_path)

	var status_ids := Report.load_status_ids()
	_expect(status_ids.has("Scorch") and status_ids.has("SpeedDown"), "status ids not loaded: %s" % [status_ids])

	var tradeoff := Relic.new()
	tradeoff.bonus_blk = 3
	tradeoff.bonus_spd = -1
	_expect(Report.stat_total(tradeoff) == 2, "+3 BLOCK -1 SPEED must total 2, got %d" % Report.stat_total(tradeoff))
	_expect(is_equal_approx(Report.weighted_total(tradeoff), 3 * 0.3 - 1.0), "weighted total counts BLOCK at 0.3 and SPEED at 1.0, got %.2f" % Report.weighted_total(tradeoff))

	var axe := _relic("res://relics/weapon/acha.tres")
	_expect(Report.dice_text(axe) == "1d12", "Great Axe dice text, got %s" % Report.dice_text(axe))
	_expect(is_equal_approx(Report.weapon_average(axe), 6.5), "1d12 average must be 6.5")

	var trinket := _relic("res://relics/trinket/boot.tres")
	_expect(Report.dice_text(trinket) == "-" and Report.weapon_average(trinket) == 0.0, "a no-weapon relic shows no dice")

	var overpowered := Relic.new()
	overpowered.relic_name = "Too Fast"
	overpowered.id = "too_fast"
	overpowered.rarity = Relic.Rarity.COMMON
	overpowered.bonus_spd = 3
	_expect(Report.flags(overpowered).any(func(f: String) -> bool: return f.begins_with("OVER stat")), "a common relic with +3 SPEED must be flagged over the stat budget")
	var excepted := Report.flags(overpowered, {"too_fast": "tradeoff test"})
	_expect(not excepted.any(func(f: String) -> bool: return f.begins_with("OVER")) and excepted.has("exception: tradeoff test"),
		"an excepted relic is not flagged and shows its reason, got %s" % [excepted])
	var heavier := _relic("res://relics/armor/slow.tres")
	_expect(not Report.flags(heavier).any(func(f: String) -> bool: return f.begins_with("OVER")), "Heavier Armor is inside its budget once BLOCK is weighted")

	var glass_heart := _relic("res://relics/trinket/glass_heart.tres")
	_expect(Report.flags(glass_heart).has("review by hand"), "mythic relics are listed for hand review")

	var broken := Relic.new()
	broken.relic_name = "Broken"
	broken.id = "broken"
	broken.weapon_dice_attack = 6
	_expect(Report.flags(broken).any(func(f: String) -> bool: return f.begins_with("DATA")), "die sides without a dice amount must carry a data warning")
	broken.weapon_dice_attack = 0
	broken.weapon_dice_amount = 1
	_expect(Report.flags(broken).any(func(f: String) -> bool: return f.begins_with("DATA")), "dice amount without die sides must carry a data warning")
	for relic in relics:
		_expect(not Report.flags(relic).any(func(f: String) -> bool: return f.begins_with("DATA")), "%s has a data warning" % relic.relic_name)

	var phoenix := _relic("res://relics/trinket/phoenix_feather.tres")
	_expect(Report.is_consumable(phoenix), "Phoenix Feather must be marked consumable")
	_expect(not Report.is_consumable(trinket), "a plain stat relic is not consumable")

	var cinder := _relic("res://relics/weapon/cinderbrand.tres")
	_expect(Report.statuses_mentioned(cinder, status_ids).has("Scorch"), "Cinderbrand must list Scorch")

	var thurible := _relic("res://relics/trinket/carrion_thurible.tres")
	var mentioned := Report.statuses_mentioned(thurible, status_ids)
	_expect(mentioned.size() == _unique(mentioned).size(), "statuses must not repeat: %s" % [mentioned])

	var report := Report.build_report()
	for heading in ["## Common", "## Uncommon", "## Rare", "## Mythic", "## Summary", "Heavier Armor"]:
		_expect(report.contains(heading), "report is missing '%s'" % heading)
	_expect(report.find("## Common") < report.find("## Uncommon") and report.find("## Rare") < report.find("## Mythic"),
		"rarity groups must run from common to mythic")

	if _errors.is_empty():
		print("ITEM BALANCE REPORT CHECK OK")
		get_tree().quit(0)
	else:
		print("ITEM BALANCE REPORT CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _relic(path: String) -> Relic:
	var relic := load(path) as Relic
	_expect(relic != null, "cannot load %s" % path)
	return relic if relic != null else Relic.new()


func _unique(items: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for item in items:
		if not out.has(item):
			out.append(item)
	return out


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
