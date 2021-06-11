extends "custom_networking.gd"

# Ran By The GUI when running in Editor
# Otherwise ignored (e.g Running GUI as a scene or exported scene)
# Since we're talking to localhost from localhost, we allow object decoding

var _server: NetworkedMultiplayerENet
var tests: Array = []
var threads: int = 1
signal run_completed

func _ready() -> void:
	host()
	
func host() -> void:
	close()
	_server = NetworkedMultiplayerENet.new()
	var err: int = _server.create_server(ProjectSettings.get_setting("WAT/Port"))
	_server.allow_object_decoding = true
	if err != OK:
		push_warning("Error creating server : %s" % err as String)
	custom_multiplayer.network_peer = _server
	custom_multiplayer.connect("network_peer_connected", self, "_on_peer_connected")
	
func _on_peer_connected(id: int) -> void:
	rpc_id(id, "test_strategy_received", tests, threads)

master func _on_run_completed(results: Array) -> void:
	rpc_id(multiplayer.get_rpc_sender_id(), "run_completion_confirmed")
	emit_signal("run_completed", results)
	
func close() -> void:
	if is_instance_valid(_server):
		_server.close_connection()
		_server = null
