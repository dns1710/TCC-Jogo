extends SceneTree
## Renders a contact sheet of every icon built from art/src, each at native size and at 6x,
## on the three act-like backgrounds, so icons can be reviewed in context.
## Run: Godot --headless --path . --script res://tools/icon_review.gd -- <output.png>

const MAP_FILES := {
	"res://art/src/items.pix": "res://art/verdadeira arte/items",
	"res://art/src/statuses.pix": "res://art/verdadeira arte/status",
}
const BACKGROUNDS := [Color("#3f2631"), Color("#8b9bb4"), Color("#5a2a1c")]
const SCALE := 6
const CELL := 16 * SCALE + 8


func _init() -> void:
	var out_path := "user://icon_review.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = args[0]
	var icons: Array[Image] = []
	for map_path in MAP_FILES:
		for line in FileAccess.get_file_as_string(map_path).split("\n"):
			if line.begins_with("@"):
				var name := line.substr(1).split(" ")[0]
				var image := Image.load_from_file(ProjectSettings.globalize_path(MAP_FILES[map_path].path_join(name + ".png")))
				if image:
					icons.append(image)
	var columns := 6
	var rows := ceili(icons.size() / float(columns))
	var sheet := Image.create(columns * CELL, rows * CELL * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#222222"))
	for i in icons.size():
		var cx := (i % columns) * CELL
		var cy := (i / columns) * CELL * 2
		var icon := icons[i]
		for b in 2:
			var bg: Color = BACKGROUNDS[b]
			sheet.fill_rect(Rect2i(cx + 2, cy + b * CELL + 2, CELL - 4, CELL - 4), bg)
			for y in icon.get_height():
				for x in icon.get_width():
					var c := icon.get_pixel(x, y)
					if c.a < 0.5:
						continue
					sheet.fill_rect(Rect2i(cx + 4 + x * SCALE, cy + b * CELL + 4 + y * SCALE, SCALE, SCALE), c)
	sheet.save_png(out_path if out_path.begins_with("user:") == false else ProjectSettings.globalize_path(out_path))
	print("SHEET %d icons -> %s" % [icons.size(), out_path])
	quit(0)
