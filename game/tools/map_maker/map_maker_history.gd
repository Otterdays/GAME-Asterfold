class_name MapMakerHistory
extends RefCounted

## Snapshot undo stack for the map maker. Placement counts are small enough that whole-world
## snapshots stay cheaper to reason about than per-edit inverse operations.

const MAX_DEPTH: int = 64

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []


## Call with the world state as it was *before* the edit.
func record(previous: Dictionary) -> void:
	_undo_stack.append(previous)
	if _undo_stack.size() > MAX_DEPTH:
		_undo_stack.remove_at(0)
	_redo_stack.clear()


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


## Returns the snapshot to restore, or an empty dictionary when there is nothing to undo.
func undo(current: Dictionary) -> Dictionary:
	if _undo_stack.is_empty():
		return {}
	var snapshot: Dictionary = _undo_stack.pop_back()
	_redo_stack.append(current)
	if _redo_stack.size() > MAX_DEPTH:
		_redo_stack.remove_at(0)
	return snapshot


func redo(current: Dictionary) -> Dictionary:
	if _redo_stack.is_empty():
		return {}
	var snapshot: Dictionary = _redo_stack.pop_back()
	_undo_stack.append(current)
	if _undo_stack.size() > MAX_DEPTH:
		_undo_stack.remove_at(0)
	return snapshot


func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()


func undo_depth() -> int:
	return _undo_stack.size()


func redo_depth() -> int:
	return _redo_stack.size()
