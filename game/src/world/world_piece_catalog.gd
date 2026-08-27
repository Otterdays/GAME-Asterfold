class_name WorldPieceCatalog
extends Resource

@export var pieces: Array[WorldPieceDefinition] = []


func has_piece(piece_id: StringName) -> bool:
	return get_definition(piece_id) != null


func get_definition(piece_id: StringName) -> WorldPieceDefinition:
	for piece: WorldPieceDefinition in pieces:
		if piece != null and piece.id == piece_id:
			return piece
	return null


func get_scene(piece_id: StringName) -> PackedScene:
	var definition: WorldPieceDefinition = get_definition(piece_id)
	if definition == null:
		return null
	return definition.scene


func get_pieces_in_family(family: StringName) -> Array[WorldPieceDefinition]:
	var matching: Array[WorldPieceDefinition] = []
	for piece: WorldPieceDefinition in pieces:
		if piece != null and piece.family == family:
			matching.append(piece)
	return matching


func get_piece_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for piece: WorldPieceDefinition in pieces:
		if piece != null:
			ids.append(piece.id)
	return ids


func validate_definition() -> Array[String]:
	var errors: Array[String] = []
	var id_pattern: RegEx = RegEx.new()
	id_pattern.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	var ids: Dictionary[StringName, bool] = {}
	var families: Dictionary[StringName, bool] = {}
	if pieces.size() < 3:
		errors.append("World piece catalog must declare at least three placeable pieces.")
	for piece: WorldPieceDefinition in pieces:
		if piece == null:
			errors.append("World piece catalog contains an empty piece entry.")
			continue
		if id_pattern.search(String(piece.id)) == null:
			errors.append("Piece ID '%s' is not a lowercase namespaced stable ID." % piece.id)
		if not String(piece.id).begins_with("piece."):
			errors.append("Piece ID '%s' must use the piece. namespace." % piece.id)
		if piece.display_name.strip_edges().is_empty():
			errors.append("Piece '%s' is missing a developer display name." % piece.id)
		if piece.scene == null:
			errors.append("Piece '%s' has no scene." % piece.id)
		if ids.has(piece.id):
			errors.append("Duplicate piece ID '%s'." % piece.id)
		ids[piece.id] = true
		families[piece.family] = true
	for required_family: StringName in [&"prop", &"building", &"tree"]:
		if not families.has(required_family):
			errors.append("World piece catalog must include the '%s' family." % required_family)
	return errors
