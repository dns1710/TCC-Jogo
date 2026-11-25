extends Node
## Prints every relic in one table, grouped by rarity, and flags anything above its rarity
## budget or with inconsistent data. A report, not a gate: it always exits with code 0.
## Run: Godot --headless --path . res://tools/report_item_balance.tscn

const RELICS_ROOT := "res://relics"
const SKIP_FOLDERS := ["1old"]
const STATUSES_ROOT := "res://statuses"
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Mythic"]
const SLOT_NAMES := ["Weapon", "Helmet", "Armor", "Trinket"]

## Budgets per rarity (common, uncommon, rare, mythic). Mythic has no cap: reviewed by hand.
## Weapon caps are proposed values, confirmed when the first report is read.
## Points are weighted by what they are worth in tools/simulate_balance.tscn (`--rank=1`): a point of SPEED saves about
## 2.2 HP per fight, ATTACK about 1.55 and starting BLOCK about 0.6, so with SPEED as 1.0 they weigh 0.7 and 0.3.
const STAT_WEIGHTS := {"atk": 0.7, "blk": 0.3, "spd": 1.0}
const STAT_BUDGET := [1.0, 2.0, 3.0, -1.0]
## Relics that exceed a budget on purpose: {relic id: reason}. They are not flagged and show the reason instead.
## Empty today: no relic needs an exception once SPEED, ATTACK and BLOCK are weighted by their worth.
const EXCEPTIONS := {}
const WEAPON_AVG_BUDGET := [3.5, 5.5, 6.5, -1.0]


func _ready() -> void:
	print(build_report())
	get_tree().quit(0)


## Every relic under res://relics except retired folders, sorted by rarity, slot and name.
static func load_relics() -> Array[Relic]:
	var relics: Array[Relic] = []
	for path in _find_tres(RELICS_ROOT):
		var res := load(path)
		if res is Relic:
			relics.append(res)
	relics.sort_custom(func(a: Relic, b: Relic) -> bool:
		if a.rarity != b.rarity:
			return a.rarity < b.rarity
		if a.equip != b.equip:
			return a.equip < b.equip
		return a.relic_name < b.relic_name)
	return relics


static func _find_tres(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		if sub in SKIP_FOLDERS:
			continue
		found.append_array(_find_tres(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".tres"):
			found.append(dir_path.path_join(file))
	return found


static func stat_total(relic: Relic) -> int:
	return relic.bonus_atk + relic.bonus_blk + relic.bonus_spd


## Stat total with BLOCK counted at its weight; this is what the budget compares.
static func weighted_total(relic: Relic) -> float:
	return relic.bonus_atk * STAT_WEIGHTS["atk"] + relic.bonus_blk * STAT_WEIGHTS["blk"] + relic.bonus_spd * STAT_WEIGHTS["spd"]


static func has_weapon_dice(relic: Relic) -> bool:
	return relic.weapon_dice_attack > 0 and relic.weapon_dice_amount > 0


static func weapon_average(relic: Relic) -> float:
	if not has_weapon_dice(relic):
		return 0.0
	return relic.weapon_dice_amount * (relic.weapon_dice_attack + 1) / 2.0


static func dice_text(relic: Relic) -> String:
	if not has_weapon_dice(relic):
		return "-"
	return "%dd%d" % [relic.weapon_dice_amount, relic.weapon_dice_attack]


## Flags: over-budget measures and data warnings for one relic.
static func flags(relic: Relic, exceptions: Dictionary = EXCEPTIONS) -> Array[String]:
	var out: Array[String] = []
	var rarity := clampi(relic.rarity, 0, 3)
	var stat_cap: float = STAT_BUDGET[rarity]
	if stat_cap >= 0.0 and weighted_total(relic) > stat_cap:
		out.append("OVER stat %.1f>%.1f" % [weighted_total(relic), stat_cap])
	var weapon_cap: float = WEAPON_AVG_BUDGET[rarity]
	if weapon_cap >= 0.0 and weapon_average(relic) > weapon_cap:
		out.append("OVER weapon %.1f>%.1f" % [weapon_average(relic), weapon_cap])
	if exceptions.has(relic.id):
		var kept: Array[String] = []
		for flag in out:
			if not flag.begins_with("OVER"):
				kept.append(flag)
		if kept.size() != out.size():
			kept.append("exception: %s" % exceptions[relic.id])
		out = kept
	if rarity == 3:
		out.append("review by hand")
	if (relic.weapon_dice_attack > 0) != (relic.weapon_dice_amount > 0):
		out.append("DATA dice sides/amount mismatch")
	if relic.relic_name.strip_edges() == "" or relic.id.strip_edges() == "":
		out.append("DATA missing name or id")
	return out


static func script_source(relic: Relic) -> String:
	var script := relic.get_script() as Script
	if script == null or script.resource_path == "res://custom_resources/relic.gd":
		return ""
	return script.source_code


static func is_consumable(relic: Relic) -> bool:
	return script_source(relic).contains("consume_relic")


## Status ids found in the relic's script source (quoted id or ItemFx constant). A hint only.
static func statuses_mentioned(relic: Relic, status_ids: Array[String]) -> Array[String]:
	var source := script_source(relic)
	var out: Array[String] = []
	if source == "":
		return out
	for id in status_ids:
		var snake := _to_snake_upper(id)
		if source.contains("\"%s\"" % id) or source.contains("ItemFx.%s" % snake):
			if not out.has(id):
				out.append(id)
	return out


static func _to_snake_upper(id: String) -> String:
	var result := ""
	for i in id.length():
		var c := id[i]
		if i > 0 and c == c.to_upper() and c != c.to_lower():
			result += "_"
		result += c.to_upper()
	return result


static func load_status_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir := DirAccess.open(STATUSES_ROOT)
	if dir == null:
		return ids
	for file in dir.get_files():
		if not file.ends_with(".tres"):
			continue
		var res := load(STATUSES_ROOT.path_join(file))
		if res != null and res.get("id") is String and res.get("id") != "":
			ids.append(res.get("id"))
	return ids


static func _effect_text(relic: Relic) -> String:
	return relic.tooltip.replace("\n\n", " / ").replace("\n", " ")


static func build_report() -> String:
	var relics := load_relics()
	var status_ids := load_status_ids()
	var lines: Array[String] = []
	lines.append("# Item balance report")
	lines.append("")
	lines.append("%d relics. Budgets: weighted stat total %s (SPEED 1.0, ATTACK 0.7, BLOCK 0.3), weapon average %s (mythic: review by hand)." % [
		relics.size(), STAT_BUDGET.slice(0, 3), WEAPON_AVG_BUDGET.slice(0, 3)])
	var sums := [0.0, 0.0, 0.0, 0.0]
	var counts := [0, 0, 0, 0]
	var flagged := 0
	for rarity in 4:
		lines.append("")
		lines.append("## %s" % RARITY_NAMES[rarity])
		lines.append("")
		lines.append("| Name | Slot | Stats | Weighted | Dice | Avg | Consumable | Statuses | Effect | Flags |")
		lines.append("|---|---|---|---|---|---|---|---|---|---|")
		for relic in relics:
			if clampi(relic.rarity, 0, 3) != rarity:
				continue
			var relic_flags := flags(relic)
			var real_flags := relic_flags.filter(func(f: String) -> bool: return f != "review by hand")
			if not real_flags.is_empty():
				flagged += 1
			counts[rarity] += 1
			sums[rarity] += weighted_total(relic)
			lines.append("| %s | %s | %d | %.1f | %s | %s | %s | %s | %s | %s |" % [
				relic.relic_name, SLOT_NAMES[clampi(relic.equip, 0, 3)], stat_total(relic), weighted_total(relic),
				dice_text(relic), ("%.1f" % weapon_average(relic)) if has_weapon_dice(relic) else "-",
				"yes" if is_consumable(relic) else "", ", ".join(statuses_mentioned(relic, status_ids)),
				_effect_text(relic), "; ".join(relic_flags)])
	lines.append("")
	lines.append("## Summary")
	lines.append("")
	lines.append("| Rarity | Count | Avg weighted total | Stat budget | Weapon avg budget |")
	lines.append("|---|---|---|---|---|")
	for rarity in 4:
		var average: float = float(sums[rarity]) / counts[rarity] if counts[rarity] > 0 else 0.0
		lines.append("| %s | %d | %.2f | %s | %s |" % [
			RARITY_NAMES[rarity], counts[rarity], average,
			"review" if STAT_BUDGET[rarity] < 0 else "%.1f" % STAT_BUDGET[rarity],
			"review" if WEAPON_AVG_BUDGET[rarity] < 0 else "%.1f" % WEAPON_AVG_BUDGET[rarity]])
	lines.append("")
	lines.append("%d relics flagged over budget or with data warnings." % flagged)
	return "\n".join(lines)
