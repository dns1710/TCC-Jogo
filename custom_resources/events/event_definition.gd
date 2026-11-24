class_name EventDefinition
extends Resource
## An event as data: text and choices. Played by the reusable ChoiceEvent scene
## unless a custom_scene is attached for something special.

@export var title := ""
@export_multiline var body := ""
@export var choices: Array[EventChoice] = []
@export var custom_scene: PackedScene
