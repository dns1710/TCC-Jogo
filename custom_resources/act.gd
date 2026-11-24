class_name Act
extends Resource
## One act of a run: the content pools its map draws from, how it looks,
## and the lore shown after its boss is beaten.

@export var act_name: String = ""
@export var battle_stats_pool: BattleStatsPool
@export var event_room_pool: EventRoomPool
## Optional. When null the map keeps its default background.
@export var background: Texture2D
## Optional. Background drawn behind this act's battles; null keeps the forest.
@export var battle_background: Texture2D
@export_multiline var transition_text: String = ""

@export_group("Enemy scaling")
## Multiplier on every enemy's maximum health in this act (rounded up). 1.0 leaves enemies as defined.
@export var enemy_health_scale := 1.0
## Flat amount added to every enemy's attack stat in this act (the flat part of its dice rolls).
@export var enemy_attack_bonus := 0
## Extra dice that boss attacks roll in this act, of the attack's own die size.
@export var boss_extra_dice := 0
