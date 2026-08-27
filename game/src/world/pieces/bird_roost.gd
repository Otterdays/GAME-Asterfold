class_name BirdRoost
extends Node3D

## Map-maker-placeable ambient life. The roost owns a standalone AmbientBirdFlock that
## circles this node instead of a grove, so a builder can put birds anywhere on the
## square. Presentation only; nothing here touches gameplay state.

const PIECE_ID: StringName = &"piece.bird_roost"

@export var flock: AmbientBirdFlock


func _ready() -> void:
	add_to_group(NatureAmbience.AMBIENT_MOTION_GROUP)


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	if flock != null:
		flock.apply_accessibility_settings(settings)
