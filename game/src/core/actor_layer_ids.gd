class_name ActorLayerIds
extends RefCounted

## Canonical humanoid layer identities for 2D actor cards.
##
## Both orders are draw orders, back to front, and they double as atlas indices.
## The generator in `tools/generate_mara_layers.ps1` writes atlas rows in exactly
## these orders, so changing a list is a content regeneration, not a text edit.

## World cards collapse fingers into their hand because 32 px/m cannot resolve them.
const FIELD_LAYER_ORDER: Array[StringName] = [
	&"layer.l_thigh",
	&"layer.r_thigh",
	&"layer.l_knee",
	&"layer.r_knee",
	&"layer.l_calf",
	&"layer.r_calf",
	&"layer.l_foot",
	&"layer.r_foot",
	&"layer.pelvis",
	&"layer.waist",
	&"layer.abdomen",
	&"layer.torso",
	&"layer.l_upper_arm",
	&"layer.r_upper_arm",
	&"layer.l_forearm",
	&"layer.r_forearm",
	&"layer.l_hand",
	&"layer.r_hand",
	&"layer.l_shoulder",
	&"layer.r_shoulder",
	&"layer.head",
]

## The paper doll draws at UI density, so every finger is an addressable layer.
const DOLL_LAYER_ORDER: Array[StringName] = [
	&"layer.l_thigh",
	&"layer.r_thigh",
	&"layer.l_knee",
	&"layer.r_knee",
	&"layer.l_calf",
	&"layer.r_calf",
	&"layer.l_foot",
	&"layer.r_foot",
	&"layer.pelvis",
	&"layer.waist",
	&"layer.abdomen",
	&"layer.torso",
	&"layer.l_upper_arm",
	&"layer.r_upper_arm",
	&"layer.l_forearm",
	&"layer.r_forearm",
	&"layer.l_hand",
	&"layer.r_hand",
	&"layer.l_thumb",
	&"layer.l_index",
	&"layer.l_middle",
	&"layer.l_ring",
	&"layer.l_little",
	&"layer.r_thumb",
	&"layer.r_index",
	&"layer.r_middle",
	&"layer.r_ring",
	&"layer.r_little",
	&"layer.l_shoulder",
	&"layer.r_shoulder",
	&"layer.head",
]

const FINGER_LAYERS: Array[StringName] = [
	&"layer.l_thumb",
	&"layer.l_index",
	&"layer.l_middle",
	&"layer.l_ring",
	&"layer.l_little",
	&"layer.r_thumb",
	&"layer.r_index",
	&"layer.r_middle",
	&"layer.r_ring",
	&"layer.r_little",
]


static func field_layer_count() -> int:
	return FIELD_LAYER_ORDER.size()


static func doll_layer_count() -> int:
	return DOLL_LAYER_ORDER.size()


static func field_index(layer_id: StringName) -> int:
	return FIELD_LAYER_ORDER.find(layer_id)


static func doll_index(layer_id: StringName) -> int:
	return DOLL_LAYER_ORDER.find(layer_id)


static func is_finger(layer_id: StringName) -> bool:
	return FINGER_LAYERS.has(layer_id)


## Maps a doll layer onto the field layer that actually paints it.
static func collapse_to_field(layer_id: StringName) -> StringName:
	if not is_finger(layer_id):
		return layer_id
	return &"layer.l_hand" if String(layer_id).begins_with("layer.l_") else &"layer.r_hand"


static func collapse_to_field_layers(layer_ids: Array[StringName]) -> Array[StringName]:
	var collapsed: Array[StringName] = []
	for layer_id: StringName in layer_ids:
		var field_layer: StringName = collapse_to_field(layer_id)
		if not collapsed.has(field_layer):
			collapsed.append(field_layer)
	return collapsed
