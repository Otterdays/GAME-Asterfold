extends TestCase


func suite_name() -> String:
	return "equipment"


func run() -> void:
	_test_slot_and_layer_contract()
	_test_loadout_rules()
	_test_inventory_flow()
	_test_catalog_content()
	_test_layer_composition()
	_test_equipment_action_is_bindable()


func _test_slot_and_layer_contract() -> void:
	_check(EquipmentSlotCatalog.slot_count() == 16, "The v1 slot catalog stays closed at sixteen slots.")
	_check(ActorLayerIds.field_layer_count() == 21, "Field cards use twenty-one body layers.")
	_check(ActorLayerIds.doll_layer_count() == 31, "The paper doll adds ten finger layers.")
	_check(
		EquipmentSlotCatalog.covered_layers(EquipmentSlotCatalog.SLOT_HANDS).size() == 12,
		"A glove set covers both hands and every finger."
	)
	_check(
		EquipmentSlotCatalog.RING_SLOTS.size() == 4,
		"Four rings are equippable."
	)
	_check(
		EquipmentSlotCatalog.focus_slot_for_layer(&"layer.r_ring") == EquipmentSlotCatalog.SLOT_RING_R_RING,
		"A ring finger focuses its own ring slot."
	)
	_check(
		EquipmentSlotCatalog.focus_slot_for_layer(&"layer.r_middle") == EquipmentSlotCatalog.SLOT_HANDS,
		"A non-ring finger focuses the glove set."
	)
	_check(
		EquipmentSlotCatalog.focus_slot_for_layer(&"layer.l_knee") == EquipmentSlotCatalog.SLOT_LEGS,
		"Knees and calves focus the leg slot."
	)
	_check(
		ActorLayerIds.collapse_to_field(&"layer.l_index") == &"layer.l_hand",
		"Field export collapses fingers into their hand."
	)
	var collapsed: Array[StringName] = ActorLayerIds.collapse_to_field_layers(
		EquipmentSlotCatalog.covered_layers(EquipmentSlotCatalog.SLOT_HANDS)
	)
	_check(collapsed.size() == 2, "Collapsed glove coverage reduces to two hand layers.")
	for layer_id: StringName in ActorLayerIds.FIELD_LAYER_ORDER:
		_check(ActorLayerIds.doll_index(layer_id) >= 0, "Field layer '%s' also exists on the doll." % layer_id)


func _test_loadout_rules() -> void:
	var loadout: EquipmentLoadout = EquipmentLoadout.new()
	_check(not loadout.is_occupied(EquipmentSlotCatalog.SLOT_HEAD), "A new loadout starts empty.")
	_check(loadout.set_occupant(EquipmentSlotCatalog.SLOT_HEAD, &"cap").is_empty(), "Equipping an empty slot displaces nothing.")
	var displaced: Array[StringName] = loadout.set_occupant(EquipmentSlotCatalog.SLOT_HEAD, &"helm")
	_check(
		displaced.size() == 1 and displaced[0] == &"cap",
		"A slot holds one occupant and returns the displaced instance."
	)
	_check(loadout.set_occupant(&"slot.nonexistent", &"ghost").is_empty(), "Unknown slots are rejected.")
	loadout.set_occupant(EquipmentSlotCatalog.SLOT_OFF_HAND, &"shield")
	var two_handed_displaced: Array[StringName] = loadout.set_occupant(
		EquipmentSlotCatalog.SLOT_MAIN_HAND,
		&"stave",
		true
	)
	_check(two_handed_displaced.has(&"shield"), "A two-handed main hand displaces the off hand.")
	_check(loadout.is_blocked(EquipmentSlotCatalog.SLOT_OFF_HAND), "The off hand stays blocked, not silently full.")
	_check(not loadout.can_equip(EquipmentSlotCatalog.SLOT_OFF_HAND), "A blocked slot refuses new occupants.")
	loadout.clear_slot(EquipmentSlotCatalog.SLOT_MAIN_HAND)
	_check(not loadout.is_blocked(EquipmentSlotCatalog.SLOT_OFF_HAND), "Removing the two-hander unblocks the off hand.")
	_check(not loadout.content_hash().is_empty(), "An occupied loadout produces a cache key.")
	loadout.clear()
	_check(loadout.content_hash().is_empty(), "A cleared loadout hashes as empty.")
	_check(loadout.to_dictionary().is_empty(), "A cleared loadout serialises as empty.")


func _test_inventory_flow() -> void:
	var catalog: ItemCatalog = _catalog()
	if catalog == null:
		_check(false, "The item catalog loads for inventory tests.")
		return
	var inventory: PartyInventory = PartyInventory.create_from_catalog(catalog)
	_check(
		inventory.bag_instances().size() == catalog.starter_item_ids.size(),
		"Starter items arrive in the bag, not pre-equipped."
	)
	var glove_instances: Array[StringName] = inventory.bag_instances_for_slot(EquipmentSlotCatalog.SLOT_HANDS)
	_check(not glove_instances.is_empty(), "The bag offers a glove set.")
	_check(inventory.equip(glove_instances[0]), "Equipping a bagged item succeeds.")
	_check(
		inventory.get_loadout().occupant(EquipmentSlotCatalog.SLOT_HANDS) == glove_instances[0],
		"Gloves occupy the single hands slot."
	)
	_check(not inventory.bag_instances().has(glove_instances[0]), "An equipped instance leaves the bag.")
	_check(not inventory.equip(glove_instances[0]), "An equipped instance cannot be equipped twice.")

	var ring_slots_filled: int = 0
	for ring_slot: StringName in EquipmentSlotCatalog.RING_SLOTS:
		var ring_instances: Array[StringName] = inventory.bag_instances_for_slot(ring_slot)
		if ring_instances.is_empty():
			continue
		if inventory.equip(ring_instances[0]):
			ring_slots_filled += 1
	_check(ring_slots_filled == 4, "All four rings equip independently.")

	_check(inventory.unequip(EquipmentSlotCatalog.SLOT_HANDS), "Unequipping returns the instance to the bag.")
	_check(inventory.bag_instances().has(glove_instances[0]), "The removed glove set is bagged again.")
	_check(not inventory.unequip(EquipmentSlotCatalog.SLOT_HANDS), "Unequipping an empty slot reports failure.")

	var stave_instances: Array[StringName] = inventory.bag_instances_for_slot(EquipmentSlotCatalog.SLOT_MAIN_HAND)
	var shield_instances: Array[StringName] = inventory.bag_instances_for_slot(EquipmentSlotCatalog.SLOT_OFF_HAND)
	if not stave_instances.is_empty() and not shield_instances.is_empty():
		inventory.equip(shield_instances[0])
		inventory.equip(stave_instances[0])
		_check(
			inventory.bag_instances().has(shield_instances[0]),
			"A two-handed weapon returns the off-hand item to the bag."
		)
		_check(
			not inventory.equip(shield_instances[0]),
			"The blocked off hand refuses equipment while the two-hander is held."
		)
	_check(inventory.definition_for_instance(&"missing@1") == null, "Unknown instances resolve to no definition.")


func _test_catalog_content() -> void:
	var catalog: ItemCatalog = _catalog()
	if catalog == null:
		return
	_check(catalog.validate_definition().is_empty(), "The shipped item catalog validates cleanly.")
	for slot_id: StringName in EquipmentSlotCatalog.SLOT_ORDER:
		_check(not catalog.items_for_slot(slot_id).is_empty(), "Slot '%s' has a graybox item." % slot_id)
	var broken: ItemDefinition = ItemDefinition.new()
	broken.id = &"Item.Bad"
	broken.slot = &"slot.nonexistent"
	var errors: Array[String] = broken.validate_definition()
	_check(_errors_mention(errors, "stable ID"), "Item validation rejects non-stable IDs.")
	_check(_errors_mention(errors, "unknown slot"), "Item validation rejects unknown slots.")
	_check(_errors_mention(errors, "localization key"), "Item validation requires a localization key.")


func _test_layer_composition() -> void:
	var kit: ActorLayerKit = load("res://content/actors/mara_layer_kit.tres") as ActorLayerKit
	if kit == null:
		_check(false, "The Mara layer kit loads.")
		return
	_check(kit.validate_definition().is_empty(), "The Mara layer kit matches the runtime layer contract.")
	var compositor: SpriteLayerCompositor = SpriteLayerCompositor.new()
	_check(compositor.configure(kit), "The compositor slices both packed atlases.")
	var bare: ImageTexture = compositor.compose_field_sheet([] as Array[ItemDefinition])
	_check(bare != null, "An unequipped field sheet composes.")
	if bare == null:
		return
	_check(
		bare.get_size() == Vector2(kit.field_sheet_size()),
		"The composed sheet keeps the authored 6x5 frame layout."
	)
	var catalog: ItemCatalog = _catalog()
	if catalog == null:
		return
	var equipped: Array[ItemDefinition] = [
		catalog.get_item(&"item.armor.orchard_boots"),
		catalog.get_item(&"item.jewelry.chime_ring"),
	]
	var dressed: ImageTexture = compositor.compose_field_sheet(equipped)
	_check(dressed != null, "An equipped field sheet composes.")
	_check(
		dressed != null and dressed.get_image().get_data() != bare.get_image().get_data(),
		"Equipment changes the composed world card."
	)
	_check(
		compositor.compose_field_sheet(equipped) == dressed,
		"Identical loadouts reuse the cached sheet."
	)
	var doll: ImageTexture = compositor.compose_doll(equipped)
	_check(doll != null and doll.get_size() == Vector2(kit.doll_frame_size()), "The paper doll composes at UI density.")
	var highlight: ImageTexture = compositor.compose_doll_highlight(
		EquipmentSlotCatalog.covered_layers(EquipmentSlotCatalog.SLOT_LEGS)
	)
	_check(highlight != null, "Focus highlights compose for a slot's body regions.")
	var empty_compositor: SpriteLayerCompositor = SpriteLayerCompositor.new()
	_check(not empty_compositor.configure(null), "A missing kit configures to a disabled compositor.")
	_check(not empty_compositor.is_ready(), "A disabled compositor reports itself unusable.")


func _test_equipment_action_is_bindable() -> void:
	var bindable: Array = input_router.call(&"get_bindable_actions") as Array
	_check(bindable.has(&"equipment"), "Equipment appears in the remappable action list.")
	_check(
		String(input_router.call(&"get_action_label", &"equipment")) == "Equipment",
		"The controls list labels the equipment action."
	)
	_check(InputMap.has_action(&"equipment"), "The project declares a semantic equipment action.")
	_check(String(input_router.call(&"get_prompt", &"equipment")) == "I", "Equipment defaults to I on keyboard.")
	_check(
		String(input_router.call(&"get_prompt", &"fold_right")) == "E",
		"World Turn right keeps E."
	)
	var original: Dictionary = input_router.call(&"serialize_bindings") as Dictionary
	var new_key: InputEventKey = InputEventKey.new()
	new_key.physical_keycode = KEY_J
	_check(bool(input_router.call(&"rebind_action", &"equipment", new_key, false)), "Equipment can be rebound.")
	_check(String(input_router.call(&"get_prompt", &"equipment")).contains("J"), "Rebinding equipment updates its prompt.")
	input_router.call(&"apply_serialized_bindings", original)
	_check(String(input_router.call(&"get_prompt", &"equipment")) == "I", "Stored bindings restore the equipment default.")


func _catalog() -> ItemCatalog:
	return load("res://content/items/item_catalog.tres") as ItemCatalog
