extends SceneTree


func _init() -> void:
	_report.call_deferred()


func _report() -> void:
	await process_frame
	var devices: Array[Dictionary] = []
	for device_id: int in Input.get_connected_joypads():
		devices.append({
			"id": device_id,
			"name": Input.get_joy_name(device_id),
			"guid": Input.get_joy_guid(device_id),
		})
	print("[INPUT] %s" % JSON.stringify({"connected_gamepads": devices.size(), "devices": devices}))
	quit(0)
