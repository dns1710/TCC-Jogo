class_name EnemyStats
extends Stats

@export var ai: PackedScene
## Groups enemies for pack/frenzy rules (e.g. "wolf", "imp").
@export var tag := ""
## Bosses set this so Freeze never stops their turn bar.
@export var freeze_immune := false
