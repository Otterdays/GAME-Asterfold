class_name LeafDrift
extends Node3D

## Map-maker-placeable leaf fall. The drift owns a standalone LeafFallEmitter that
## sheds from a ring above this node instead of from a grove layout, so a builder can
## add falling leaves over an awning, a gate, or a tree the grove does not own.

const PIECE_ID: StringName = &"piece.leaf_drift"

@export var leaf_fall: LeafFallEmitter


func _ready() -> void:
	add_to_group(NatureAmbience.AMBIENT_MOTION_GROUP)


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	if leaf_fall != null:
		leaf_fall.apply_accessibility_settings(settings)
