class_name ATBConfig
extends RefCounted
## Single source of truth for turn-bar pacing. Time to act = MAX / rate,
## where rate = speed * slow factor. Lower MAX = faster fights.

const MAX := 20.0
const PLAYER_START_RATIO := 0.5
## Enemies start with a random head start between 0 and this share of MAX.
const ENEMY_START_MAX_RATIO := 1.0 / 3.0
