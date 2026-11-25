class_name ScoutmasterLines
extends Resource
## All the camp-frame text in one place so wording can change without touching code.

## Remarks when the difficulty adjustment makes the game harder.
@export var harder: Array[String] = []
## Remarks when the difficulty adjustment makes the game easier.
@export var easier: Array[String] = []
## Opening lines (at most 4).
@export var opening: Array[String] = []
## Win screen epilogue lines (at most 3).
@export var epilogue: Array[String] = []
