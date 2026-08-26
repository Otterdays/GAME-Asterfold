extends SceneTree

const REQUIRED_DIRECTORIES: Array[String] = [
	"res://assets",
	"res://content",
	"res://content/actors",
	"res://content/callings",
	"res://content/dialogue",
	"res://content/encounters",
	"res://content/quests",
	"res://content/zones",
]
const ASSET_MANIFEST_PATH: String = "res://assets/asset_manifest.json"

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for directory: String in REQUIRED_DIRECTORIES:
		if DirAccess.open(directory) == null:
			_failures.append("Required content directory is missing: %s" % directory)

	_validate_asset_manifest()

	if _failures.is_empty():
		print("[CONTENT] PASS: scaffold directories and provenance manifest are valid.")
		quit(0)
		return

	for failure: String in _failures:
		push_error("[CONTENT] %s" % failure)
	print("[CONTENT] FAIL: %d validation errors." % _failures.size())
	quit(1)


func _validate_asset_manifest() -> void:
	if not FileAccess.file_exists(ASSET_MANIFEST_PATH):
		_failures.append("Asset provenance manifest is missing: %s" % ASSET_MANIFEST_PATH)
		return

	var file: FileAccess = FileAccess.open(ASSET_MANIFEST_PATH, FileAccess.READ)
	if file == null:
		_failures.append("Asset provenance manifest could not be opened.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_failures.append("Asset provenance manifest must contain a JSON object.")
		return

	var manifest: Dictionary = parsed as Dictionary
	if manifest.get("schema_version") != 1:
		_failures.append("Asset provenance manifest schema_version must be 1.")
	if not manifest.has("assets") or not manifest["assets"] is Array:
		_failures.append("Asset provenance manifest must contain an assets array.")
