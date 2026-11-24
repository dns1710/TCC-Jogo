extends Node
## Headless guard for the item-status-art spec: every pixel map built a PNG of the right size with a
## transparent background and only palette colours, no two icons are identical or a pure palette swap,
## and no status resource still points at the placeholder art folder.
## Run: Godot --headless --path . res://tools/verify_item_art.tscn

const MAPS := {
	"res://art/src/items.pix": ["res://art/verdadeira arte/items", Vector2i(16, 16), 24],
	"res://art/src/statuses.pix": ["res://art/verdadeira arte/status", Vector2i(10, 10), 6],
}
const PALETTE_FILE := "res://art/src/palette.txt"
const STATUS_FOLDER := "res://statuses"

var _errors: Array[String] = []


func _ready() -> void:
	var palette := _palette()
	var shapes := {}
	for map_path in MAPS:
		var folder: String = MAPS[map_path][0]
		var size: Vector2i = MAPS[map_path][1]
		var names := _names(map_path)
		_expect(names.size() == MAPS[map_path][2], "%s: expected %d icons, found %d" % [map_path, MAPS[map_path][2], names.size()])
		for icon_name in names:
			var path := ProjectSettings.globalize_path(folder.path_join(icon_name + ".png"))
			var image := Image.load_from_file(path)
			_expect(image != null, "%s.png is missing" % icon_name)
			if image == null:
				continue
			_expect(image.get_size() == size, "%s.png is %s, expected %s" % [icon_name, image.get_size(), size])
			_expect(ResourceLoader.exists(folder.path_join(icon_name + ".png")), "%s.png has no import data" % icon_name)
			var shape := ""
			var painted := 0
			for y in image.get_height():
				for x in image.get_width():
					var c := image.get_pixel(x, y)
					if c.a == 0.0:
						shape += "."
						continue
					_expect(c.a == 1.0, "%s.png has a semi-transparent pixel at %d,%d" % [icon_name, x, y])
					_expect(palette.has(c.to_html(false)), "%s.png uses a colour outside the palette at %d,%d" % [icon_name, x, y])
					shape += "#"
					painted += 1
			_expect(painted > 10, "%s.png is almost empty" % icon_name)
			_expect(image.get_pixel(0, 0).a == 0.0, "%s.png does not have a transparent corner" % icon_name)
			var key := "%s|%s" % [size, image.get_data().hex_encode()]
			_expect(not shapes.has(key), "%s.png is identical to %s.png" % [icon_name, shapes.get(key, "")])
			shapes[key] = icon_name
			# A pure palette swap keeps the exact same silhouette and pixel layout.
			var layout_key := "%s|%s" % [size, shape]
			if icon_name != "" and shapes.has(layout_key):
				_errors.append("%s.png has the same silhouette as %s.png" % [icon_name, shapes[layout_key]])
			shapes[layout_key] = icon_name

	_check_status_icons()

	if _errors.is_empty():
		print("ITEM ART CHECK OK")
		get_tree().quit(0)
	else:
		print("ITEM ART CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _palette() -> Dictionary:
	var result := {}
	for line in FileAccess.get_file_as_string(PALETTE_FILE).split("\n"):
		var parts := line.strip_edges().split(" ")
		if parts.size() == 2 and not line.begins_with("#"):
			result[parts[1].to_lower()] = parts[0]
	return result


func _names(map_path: String) -> Array[String]:
	var names: Array[String] = []
	for line in FileAccess.get_file_as_string(map_path).split("\n"):
		if line.begins_with("@"):
			names.append(line.substr(1).split(" ")[0])
	return names


func _check_status_icons() -> void:
	for file in DirAccess.get_files_at(STATUS_FOLDER):
		if not file.ends_with(".tres"):
			continue
		var text := FileAccess.get_file_as_string(STATUS_FOLDER.path_join(file))
		_expect(not text.contains("arte nao tao verdadeira"), "%s still uses a placeholder icon" % file)
