extends SceneTree
## Renders the text pixel maps under art/src into PNG icons.
## Map file format: "@<name> <width>x<height> <out folder>" then <height> rows of <width> palette chars.
## Run: Godot --headless --path . --script res://tools/build_icons.gd
## Exit code 1 (with a message per problem) when a map has the wrong size or an unknown character.

const PALETTE_FILE := "res://art/src/palette.txt"
const MAP_FILES := ["res://art/src/items.pix", "res://art/src/statuses.pix"]
const FOLDERS := {
	"items": "res://art/verdadeira arte/items",
	"status": "res://art/verdadeira arte/status",
}


func _init() -> void:
	var errors: Array[String] = []
	var palette := _load_palette(errors)
	var built := 0
	for path in MAP_FILES:
		built += _build_file(path, palette, errors)
	if errors.is_empty():
		print("BUILD ICONS OK (%d icons)" % built)
		quit(0)
	else:
		print("BUILD ICONS FAILED")
		for e in errors:
			print("  ", e)
		quit(1)


func _load_palette(errors: Array[String]) -> Dictionary:
	var palette := {}
	var file := FileAccess.open(PALETTE_FILE, FileAccess.READ)
	if file == null:
		errors.append("cannot read %s" % PALETTE_FILE)
		return palette
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(" ")
		if parts.size() != 2 or parts[0].length() != 1:
			errors.append("bad palette line: %s" % line)
			continue
		palette[parts[0]] = Color.html("#" + parts[1])
	return palette


func _build_file(path: String, palette: Dictionary, errors: Array[String]) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("cannot read %s" % path)
		return 0
	var count := 0
	var name := ""
	var size := Vector2i.ZERO
	var folder := ""
	var rows: Array[String] = []
	var lines := file.get_as_text().split("\n")
	lines.append("@end")
	for raw in lines:
		var line := raw.strip_edges()
		if line.begins_with("@"):
			if name != "":
				if _write(name, size, folder, rows, palette, errors):
					count += 1
			rows = []
			if line == "@end":
				break
			var head := line.substr(1).split(" ")
			if head.size() != 3 or not head[1].contains("x"):
				errors.append("%s: bad header '%s'" % [path, line])
				name = ""
				continue
			name = head[0]
			size = Vector2i(int(head[1].split("x")[0]), int(head[1].split("x")[1]))
			if not FOLDERS.has(head[2]):
				errors.append("%s: unknown folder '%s'" % [path, head[2]])
				name = ""
				continue
			folder = FOLDERS[head[2]]
		elif name != "" and not line.is_empty() and not line.begins_with("#"):
			rows.append(line)
	return count


func _write(name: String, size: Vector2i, folder: String, rows: Array[String], palette: Dictionary, errors: Array[String]) -> bool:
	var ok := true
	if rows.size() != size.y:
		errors.append("%s: expected %d rows, found %d" % [name, size.y, rows.size()])
		return false
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row := rows[y]
		if row.length() != size.x:
			errors.append("%s row %d: expected %d chars, found %d ('%s')" % [name, y, size.x, row.length(), row])
			ok = false
			continue
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			if not palette.has(ch):
				errors.append("%s row %d col %d: unknown palette char '%s'" % [name, y, x, ch])
				ok = false
				continue
			image.set_pixel(x, y, palette[ch])
	if not ok:
		return false
	var out := ProjectSettings.globalize_path(folder.path_join(name + ".png"))
	if image.save_png(out) != OK:
		errors.append("%s: cannot save %s" % [name, out])
		return false
	return true
