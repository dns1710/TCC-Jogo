extends Node
## Headless check of the combat-statuses spec on both an enemy and the player:
## combined slows, Freeze timing/immunity, Brittle, Scorch, Ashen, Sunder, tooltips.
## Run: Godot --headless --path . res://tools/verify_combat_statuses.tscn

const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SPEED_DOWN := preload("res://statuses/status_speed_down.tres")
const STATUS_PATHS := {
	"Freeze": "res://statuses/status_freeze.tres",
	"Brittle": "res://statuses/status_brittle.tres",
	"Scorch": "res://statuses/status_scorch.tres",
	"Ashen": "res://statuses/status_ashen.tres",
	"Sunder": "res://statuses/status_sunder.tres",
}
const STEP := 0.05

var _errors: Array[String] = []


func _ready() -> void:
	await _run_checks()
	if _errors.is_empty():
		print("COMBAT STATUSES CHECK OK")
		get_tree().quit(0)
	else:
		print("COMBAT STATUSES CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _near(value: float, expected: float, tolerance: float, message: String) -> void:
	_expect(absf(value - expected) <= tolerance, "%s (expected %.2f, got %.2f)" % [message, expected, value])


func _frames(count := 2) -> void:
	for i in count:
		await get_tree().process_frame


func _make_actor(kind: String) -> Node:
	if kind == "player":
		var player := PLAYER_SCENE.instantiate() as Player
		add_child(player)
		player.stats = load("res://characters/player/player.tres").create_instance()
		player.stats.max_health = 100
		player.stats.health = 100
		player.stats.block = 0
		return player
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	enemy.stats = load("res://enemies/zscout/zscout.tres")
	enemy.stats.max_health = 100
	enemy.stats.health = 100
	enemy.stats.block = 0
	return enemy


func _status(status_name: String, stacks := 0) -> Status:
	var path: String = STATUS_PATHS[status_name]
	if not ResourceLoader.exists(path):
		_errors.append("missing status resource: %s" % path)
		return null
	var status: Status = load(path).duplicate()
	if stacks > 0:
		status.stacks = stacks
	return status


func _apply(actor: Node, status_name: String, stacks := 0) -> void:
	var status := _status(status_name, stacks)
	if status:
		actor.status_handler.add_status(status)


func _has(actor: Node, id: String) -> bool:
	var status: Status = actor.status_handler._get_status(id)
	if not status:
		return false
	if status.can_expire and status.duration <= 0:
		return false
	return true


func _advance(actor: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		actor.add_atb(STEP)
		t += STEP


func _run_checks() -> void:
	for status_name in STATUS_PATHS:
		if not ResourceLoader.exists(STATUS_PATHS[status_name]):
			_errors.append("missing status resource: %s" % STATUS_PATHS[status_name])
	if not _errors.is_empty():
		return
	for kind in ["enemy", "player"]:
		await _check_actor(kind)
	_check_tooltips()


func _check_actor(kind: String) -> void:
	var tag := " [%s]" % kind

	# Combined slows: Speed Down plus Freeze, independent endings.
	var a := _make_actor(kind)
	await _frames()
	var slow: Status = SPEED_DOWN.duplicate()
	slow.stacks = 2
	a.status_handler.add_status(slow)
	_near(a.atb_rate_multiplier, pow(0.85, 2), 0.001, "speed down rate" + tag)
	_apply(a, "Freeze")
	_near(a.atb_rate_multiplier, 0.0, 0.0001, "frozen rate is zero" + tag)
	_advance(a, 1.6)
	_near(a.atb_rate_multiplier, pow(0.85, 2), 0.001, "after freeze rate returns to speed down rate" + tag)

	# Freeze: bar stays put 1.5s, then resumes; no refreeze during immunity.
	var b := _make_actor(kind)
	await _frames()
	b.atb = 8.0
	_apply(b, "Freeze")
	_advance(b, 1.4)
	_near(b.atb, 8.0, 0.001, "bar frozen at 40%" + tag)
	_advance(b, 0.3)
	_expect(b.atb > 8.0, "bar resumes after 1.5s" + tag)
	_advance(b, 0.3)
	await _frames()
	_apply(b, "Freeze")
	_expect(not b.atb_mods.is_frozen(), "no chain freeze during immunity" + tag)
	_advance(b, 3.7)
	await _frames()
	_apply(b, "Freeze")
	_expect(b.atb_mods.is_frozen(), "freeze works again after immunity" + tag)

	# Boss immunity.
	if kind == "enemy":
		var boss := _make_actor("enemy")
		await _frames()
		boss.atb_mods.freeze_immune = true
		_apply(boss, "Freeze")
		_near(boss.atb_rate_multiplier, 1.0, 0.0001, "immune boss unaffected" + tag)

	# Brittle: a d6 hit of 8 rolls one more d6 once (9..14), then Brittle ends; reapply does not stack.
	var c := _make_actor(kind)
	await _frames()
	_apply(c, "Brittle")
	_apply(c, "Brittle")
	var hp: int = c.stats.health
	c.take_damage(8, Modifier.Type.DMG_TAKEN, null, 6)
	await get_tree().create_timer(0.4).timeout
	var dealt: int = hp - c.stats.health
	_expect(dealt >= 9 and dealt <= 14, "brittle hit deals 9 to 14, got %d%s" % [dealt, tag])
	_expect(not _has(c, "Brittle"), "brittle consumed" + tag)
	hp = c.stats.health
	c.take_damage(8, Modifier.Type.DMG_TAKEN, null, 6)
	await get_tree().create_timer(0.4).timeout
	_expect(hp - c.stats.health == 8, "second hit deals 8, got %d%s" % [hp - c.stats.health, tag])

	# Scorch: 3,2,1 then removal; stacking 2 onto 1 gives 3.
	var d := _make_actor(kind)
	await _frames()
	d.stats.max_health = 100
	d.stats.health = 100
	_apply(d, "Scorch", 3)
	var seen: Array[int] = []
	for i in 3:
		var before: int = d.stats.health
		d.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)
		await get_tree().create_timer(0.6).timeout
		seen.append(before - d.stats.health)
	_expect(seen == [3, 2, 1], "scorch damage 3,2,1 got %s%s" % [str(seen), tag])
	await _frames()
	_expect(not _has(d, "Scorch"), "scorch removed at 0 stacks" + tag)
	var d2 := _make_actor(kind)
	await _frames()
	_apply(d2, "Scorch", 1)
	_apply(d2, "Scorch", 2)
	var scorch: Status = d2.status_handler._get_status("Scorch")
	_expect(scorch != null and scorch.stacks == 3, "stacking 2 onto 1 gives 3" + tag)

	# Ashen: 9 block becomes 4; normal after 3 actions.
	var e := _make_actor(kind)
	await _frames()
	_apply(e, "Ashen")
	var block := BlockEffect.new()
	block.amount = 9
	var targets: Array[Node] = [e]
	e.stats.block = 0
	block.execute(targets)
	_expect(e.stats.block == 4, "ashen halves 9 to 4, got %d%s" % [e.stats.block, tag])
	for i in 3:
		if kind == "player":
			Events.player_action_completed.emit()
		else:
			Events.enemy_action_completed.emit(e)
	await _frames()
	e.stats.block = 0
	block.execute(targets)
	_expect(e.stats.block == 9, "ashen over after 3 actions, got %d%s" % [e.stats.block, tag])
	_expect(not _has(e, "Ashen"), "ashen status removed" + tag)

	# Sunder: 10 block, 6 damage goes to health, block kept; next hit is blocked.
	var f := _make_actor(kind)
	await _frames()
	f.stats.block = 10
	_apply(f, "Sunder")
	hp = f.stats.health
	f.take_damage(6, Modifier.Type.DMG_TAKEN)
	await get_tree().create_timer(0.4).timeout
	_expect(hp - f.stats.health == 6, "sunder hit reaches health, got %d%s" % [hp - f.stats.health, tag])
	_expect(f.stats.block == 10, "sunder leaves block untouched, got %d%s" % [f.stats.block, tag])
	_expect(not _has(f, "Sunder"), "sunder consumed" + tag)
	hp = f.stats.health
	f.take_damage(6, Modifier.Type.DMG_TAKEN)
	await get_tree().create_timer(0.4).timeout
	_expect(hp == f.stats.health and f.stats.block == 4, "next hit blocked normally%s (hp %d->%d block %d)" % [tag, hp, f.stats.health, f.stats.block])


func _check_tooltips() -> void:
	for status_name in STATUS_PATHS:
		var status := _status(status_name, 2)
		if status:
			_expect(status.get_tooltip().strip_edges() != "", "tooltip for %s must not be empty" % status_name)
			_expect(status.icon != null, "icon for %s must be set" % status_name)
	var brittle := _status("Brittle")
	if brittle:
		_expect(brittle.get_tooltip().contains("extra die"), "brittle tooltip must state the extra die")
