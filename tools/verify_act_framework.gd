extends Node
## Headless check of the act framework data: acts load with pools, and the
## save file carries the act (legacy saves without it load as Act 1).
## Run: Godot --headless --path . res://tools/verify_act_framework.tscn

const ACT_PATHS := [
	"res://acts/act_1_forest.tres",
	"res://acts/act_2_ice.tres",
	"res://acts/act_3_fire.tres",
]
const TMP_SAVE := "user://act_check_save.tres"
const TMP_LEGACY := "user://act_check_legacy.tres"

var _errors: Array[String] = []


func _ready() -> void:
	for path in ACT_PATHS:
		var act: Act = load(path)
		if act == null:
			_errors.append("cannot load %s" % path)
			continue
		if act.act_name.is_empty() or act.transition_text.is_empty():
			_errors.append("%s: missing name or transition text" % path)
		if act.battle_stats_pool == null or act.event_room_pool == null:
			_errors.append("%s: missing pools" % path)

	# Round trip: act_index survives saving.
	var save := SaveGame.new()
	save.act_index = 2
	ResourceSaver.save(save, TMP_SAVE)
	var loaded := ResourceLoader.load(TMP_SAVE, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	if loaded == null or loaded.act_index != 2:
		_errors.append("act_index did not survive a save round trip")

	# Legacy save: a save file with no act_index field loads as Act 1.
	var script_path: String = SaveGame.resource_path if SaveGame.resource_path != "" else "res://custom_resources/save_game.gd"
	var legacy := FileAccess.open(TMP_LEGACY, FileAccess.WRITE)
	legacy.store_string('[gd_resource type="Resource" script_class="SaveGame" format=3]\n\n[ext_resource type="Script" path="%s" id="1_s"]\n\n[resource]\nscript = ExtResource("1_s")\nfloors_climbed = 3\n' % script_path)
	legacy.close()
	var legacy_loaded := ResourceLoader.load(TMP_LEGACY, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	if legacy_loaded == null or legacy_loaded.act_index != 0 or legacy_loaded.floors_climbed != 3:
		_errors.append("legacy save did not load as Act 1")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_SAVE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_LEGACY))

	if _errors.is_empty():
		print("ACT CHECK OK")
		get_tree().quit(0)
	else:
		print("ACT CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)
