extends Node
## Guards weapon dice data and rolls. Every weapon must define both die sides and dice amount,
## its tooltip must state the same dice, no other slot may carry weapon dice, and the handler's
## real damage roll must stay inside [amount, amount * sides] plus the character's ATTACK and hit
## both ends of that range. Also checks Brittle receives the weapon's die size (die_sides).
## Run: Godot --headless --path . res://tools/verify_weapon_dice.tscn

const Report := preload("res://tools/report_item_balance.gd")
const HANDLER_SCENE := preload("res://scenes/relic_handler/relic_handler.tscn")
const ROLLS := 3000

var _errors: Array[String] = []


func _ready() -> void:
	var stats := (load("res://characters/player/player.tres") as CharacterStats).create_instance()
	var handler := HANDLER_SCENE.instantiate() as RelicHandler
	handler.character_stats = stats
	var regex := RegEx.create_from_string("^(\\d+)d(\\d+) weapon damage")

	for relic in Report.load_relics():
		var label := "%s (%s)" % [relic.relic_name, relic.resource_path.get_file()]
		var sides := relic.weapon_dice_attack
		var amount := relic.weapon_dice_amount
		if relic.equip != Relic.Equip.WEAPON:
			_expect(sides == 0 and amount == 0, "%s is not a weapon but has weapon dice %dd%d" % [label, amount, sides])
			continue
		_expect(sides > 0 and amount > 0, "%s must define both dice amount and die sides, has %dd%d" % [label, amount, sides])
		var found := regex.search(relic.tooltip)
		if found == null:
			_errors.append("%s tooltip must start with 'NdS weapon damage'" % label)
		else:
			_expect(int(found.get_string(1)) == amount and int(found.get_string(2)) == sides,
				"%s tooltip says %sd%s but data is %dd%d" % [label, found.get_string(1), found.get_string(2), amount, sides])
		if sides <= 0 or amount <= 0:
			continue

		handler.equipped_weapon = relic
		var low := 1 << 30
		var high := -1
		for i in ROLLS:
			var damage := handler.get_weapon_damage()
			low = mini(low, damage)
			high = maxi(high, damage)
		var expected_low: int = amount + stats.attack
		var expected_high: int = amount * sides + stats.attack
		_expect(low >= expected_low and high <= expected_high,
			"%s rolled %d..%d, outside %d..%d" % [label, low, high, expected_low, expected_high])
		_expect(low == expected_low and high == expected_high,
			"%s never reached the ends of its range: saw %d..%d, expected %d..%d" % [label, low, high, expected_low, expected_high])

	handler.free()

	if _errors.is_empty():
		print("WEAPON DICE CHECK OK")
		get_tree().quit(0)
	else:
		print("WEAPON DICE CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
