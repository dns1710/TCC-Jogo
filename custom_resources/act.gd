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
