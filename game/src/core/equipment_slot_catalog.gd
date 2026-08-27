class_name EquipmentSlotCatalog
extends RefCounted

## The closed v1 equipment slot list.
##
## Anatomy and equipment are deliberately two different maps. Fingers are layers;
## rings are slots. A glove set is one slot that covers both hands and every
## finger. Adding or removing a slot is a save and content migration, not an edit.

const SLOT_HEAD: StringName = &"slot.head"
const SLOT_NECK: StringName = &"slot.neck"
const SLOT_SHOULDERS: StringName = &"slot.shoulders"
const SLOT_BACK: StringName = &"slot.back"
const SLOT_TORSO: StringName = &"slot.torso"
const SLOT_ABDOMEN: StringName = &"slot.abdomen"
const SLOT_WAIST: StringName = &"slot.waist"
const SLOT_LEGS: StringName = &"slot.legs"
const SLOT_FEET: StringName = &"slot.feet"
const SLOT_HANDS: StringName = &"slot.hands"
const SLOT_RING_R_INDEX: StringName = &"slot.ring.r_index"
const SLOT_RING_R_RING: StringName = &"slot.ring.r_ring"
const SLOT_RING_L_INDEX: StringName = &"slot.ring.l_index"
const SLOT_RING_L_RING: StringName = &"slot.ring.l_ring"
const SLOT_MAIN_HAND: StringName = &"slot.main_hand"
const SLOT_OFF_HAND: StringName = &"slot.off_hand"

## Presentation order for the equipment screen: head to feet, then jewelry, then held.
const SLOT_ORDER: Array[StringName] = [
	SLOT_HEAD,
	SLOT_NECK,
	SLOT_SHOULDERS,
	SLOT_BACK,
	SLOT_TORSO,
	SLOT_ABDOMEN,
	SLOT_WAIST,
	SLOT_LEGS,
	SLOT_FEET,
	SLOT_HANDS,
	SLOT_RING_R_INDEX,
	SLOT_RING_R_RING,
	SLOT_RING_L_INDEX,
	SLOT_RING_L_RING,
	SLOT_MAIN_HAND,
	SLOT_OFF_HAND,
]

const RING_SLOTS: Array[StringName] = [
	SLOT_RING_R_INDEX,
	SLOT_RING_R_RING,
	SLOT_RING_L_INDEX,
	SLOT_RING_L_RING,
]

const SLOT_LABELS: Dictionary = {
	SLOT_HEAD: "Head",
	SLOT_NECK: "Necklace",
	SLOT_SHOULDERS: "Shoulders",
	SLOT_BACK: "Back",
	SLOT_TORSO: "Torso",
	SLOT_ABDOMEN: "Stomach",
	SLOT_WAIST: "Waist",
	SLOT_LEGS: "Legs",
	SLOT_FEET: "Boots",
	SLOT_HANDS: "Gloves",
	SLOT_RING_R_INDEX: "Ring, right index",
	SLOT_RING_R_RING: "Ring, right ring finger",
	SLOT_RING_L_INDEX: "Ring, left index",
	SLOT_RING_L_RING: "Ring, left ring finger",
	SLOT_MAIN_HAND: "Main hand",
	SLOT_OFF_HAND: "Off hand",
}

## Doll-space layers an occupant of the slot paints or accents.
const SLOT_LAYERS: Dictionary = {
	SLOT_HEAD: [&"layer.head"],
	SLOT_NECK: [&"layer.torso"],
	SLOT_SHOULDERS: [&"layer.l_shoulder", &"layer.r_shoulder"],
	SLOT_BACK: [&"layer.torso"],
	SLOT_TORSO: [&"layer.torso", &"layer.l_upper_arm", &"layer.r_upper_arm"],
	SLOT_ABDOMEN: [&"layer.abdomen"],
	SLOT_WAIST: [&"layer.waist"],
	SLOT_LEGS: [
		&"layer.pelvis",
		&"layer.l_thigh",
		&"layer.r_thigh",
		&"layer.l_knee",
		&"layer.r_knee",
		&"layer.l_calf",
		&"layer.r_calf",
	],
	SLOT_FEET: [&"layer.l_foot", &"layer.r_foot"],
	SLOT_HANDS: [
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
	],
	SLOT_RING_R_INDEX: [&"layer.r_index"],
	SLOT_RING_R_RING: [&"layer.r_ring"],
	SLOT_RING_L_INDEX: [&"layer.l_index"],
	SLOT_RING_L_RING: [&"layer.l_ring"],
	SLOT_MAIN_HAND: [&"layer.r_hand", &"layer.r_forearm"],
	SLOT_OFF_HAND: [&"layer.l_hand", &"layer.l_forearm"],
}

## Which slot the equipment screen focuses when the player selects a body region.
## Ring fingers reach their ring; every other finger reaches the glove set.
const LAYER_FOCUS_SLOT: Dictionary = {
	&"layer.head": SLOT_HEAD,
	&"layer.l_shoulder": SLOT_SHOULDERS,
	&"layer.r_shoulder": SLOT_SHOULDERS,
	&"layer.torso": SLOT_TORSO,
	&"layer.abdomen": SLOT_ABDOMEN,
	&"layer.waist": SLOT_WAIST,
	&"layer.pelvis": SLOT_LEGS,
	&"layer.l_upper_arm": SLOT_TORSO,
	&"layer.r_upper_arm": SLOT_TORSO,
	&"layer.l_forearm": SLOT_OFF_HAND,
	&"layer.r_forearm": SLOT_MAIN_HAND,
	&"layer.l_hand": SLOT_HANDS,
	&"layer.r_hand": SLOT_HANDS,
	&"layer.l_thumb": SLOT_HANDS,
	&"layer.l_index": SLOT_RING_L_INDEX,
	&"layer.l_middle": SLOT_HANDS,
	&"layer.l_ring": SLOT_RING_L_RING,
	&"layer.l_little": SLOT_HANDS,
	&"layer.r_thumb": SLOT_HANDS,
	&"layer.r_index": SLOT_RING_R_INDEX,
	&"layer.r_middle": SLOT_HANDS,
	&"layer.r_ring": SLOT_RING_R_RING,
	&"layer.r_little": SLOT_HANDS,
	&"layer.l_thigh": SLOT_LEGS,
	&"layer.r_thigh": SLOT_LEGS,
	&"layer.l_knee": SLOT_LEGS,
	&"layer.r_knee": SLOT_LEGS,
	&"layer.l_calf": SLOT_LEGS,
	&"layer.r_calf": SLOT_LEGS,
	&"layer.l_foot": SLOT_FEET,
	&"layer.r_foot": SLOT_FEET,
}

## Overlay accents need a deterministic anchor inside the covered layer bounds.
const ANCHOR_TOP: StringName = &"top"
const ANCHOR_CENTER: StringName = &"center"

const SLOT_OVERLAY_ANCHORS: Dictionary = {
	SLOT_HEAD: ANCHOR_TOP,
	SLOT_NECK: ANCHOR_TOP,
	SLOT_BACK: ANCHOR_CENTER,
	SLOT_MAIN_HAND: ANCHOR_CENTER,
	SLOT_OFF_HAND: ANCHOR_CENTER,
	SLOT_RING_R_INDEX: ANCHOR_CENTER,
	SLOT_RING_R_RING: ANCHOR_CENTER,
	SLOT_RING_L_INDEX: ANCHOR_CENTER,
	SLOT_RING_L_RING: ANCHOR_CENTER,
}


static func has_slot(slot_id: StringName) -> bool:
	return SLOT_ORDER.has(slot_id)


static func slot_count() -> int:
	return SLOT_ORDER.size()


static func label(slot_id: StringName) -> String:
	return str(SLOT_LABELS.get(slot_id, String(slot_id)))


static func covered_layers(slot_id: StringName) -> Array[StringName]:
	var layers: Array[StringName] = []
	for layer_id: Variant in SLOT_LAYERS.get(slot_id, []):
		layers.append(StringName(layer_id))
	return layers


static func focus_slot_for_layer(layer_id: StringName) -> StringName:
	return StringName(LAYER_FOCUS_SLOT.get(layer_id, &""))


static func is_ring(slot_id: StringName) -> bool:
	return RING_SLOTS.has(slot_id)


static func overlay_anchor(slot_id: StringName) -> StringName:
	return StringName(SLOT_OVERLAY_ANCHORS.get(slot_id, ANCHOR_CENTER))
