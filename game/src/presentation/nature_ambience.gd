class_name NatureAmbience
extends Node3D

## One place for a zone's living-nature presentation: circling birds, drifting leaves,
## and the ground response under the player. It owns no game truth, so it can be
## rebuilt, frozen, or removed without touching saves, quests, or collision.

## Map-maker-placed nature pieces join this group so the zone can reach them without
## knowing where a builder dropped them.
const AMBIENT_MOTION_GROUP: StringName = &"ambient_motion"

@export var bird_flock: AmbientBirdFlock
@export var leaf_fall: LeafFallEmitter
@export var footfall_motes: FootfallMotes


## The zone injects its actor; the ambience never searches the tree for a player.
func configure_actor(actor: CharacterBody3D) -> void:
	if footfall_motes != null:
		footfall_motes.configure_actor(actor)


func apply_accessibility_settings(settings: AccessibilitySettings) -> void:
	if bird_flock != null:
		bird_flock.apply_accessibility_settings(settings)
	if leaf_fall != null:
		leaf_fall.apply_accessibility_settings(settings)
	if footfall_motes != null:
		footfall_motes.apply_accessibility_settings(settings)


func validate_configuration() -> Array[String]:
	var errors: Array[String] = []
	if bird_flock == null:
		errors.append("Nature ambience requires its bird flock.")
	else:
		errors.append_array(bird_flock.validate_configuration())
	if leaf_fall == null:
		errors.append("Nature ambience requires its leaf-fall emitter.")
	else:
		errors.append_array(leaf_fall.validate_configuration())
	if footfall_motes == null:
		errors.append("Nature ambience requires its footfall motes.")
	else:
		errors.append_array(footfall_motes.validate_configuration())
	return errors


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(validate_configuration())
