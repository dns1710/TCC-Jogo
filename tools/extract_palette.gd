extends SceneTree
## Prints the colours used by the existing item and status icons, most used first.
## Run: Godot --headless --path . --script res://tools/extract_palette.gd

const FOLDERS := [
	"res://art/verdadeira arte/items",
	"res://art/verdadeira arte/status",
]


func _init() -> void:
	var counts := {}
	var files := 0
	for folder in FOLDERS:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".png") or file.contains("slot_icon") or file.contains("background"):
				continue
			var image := Image.load_from_file(ProjectSettings.globalize_path(folder.path_join(file)))
			if image == null:
				continue
			files += 1
			for y in image.get_height():
				for x in image.get_width():
					var c := image.get_pixel(x, y)
					if c.a < 0.5:
						continue
					var key := c.to_html(false)
					counts[key] = counts.get(key, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	print("files=%d colours=%d" % [files, keys.size()])
	for k in keys.slice(0, 48):
		print("%s %d" % [k, counts[k]])
	quit(0)
