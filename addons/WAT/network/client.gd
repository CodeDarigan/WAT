extends "custom_networking.gd"

const IPAddress: String = "127.0.0.1"
var _client: NetworkedMultiplayerENet
signal test_strategy

func _ready() -> void:
	join()
	
func join() -> void:
	_client = NetworkedMultiplayerENet.new()
	var err: int = _client.create_client(IPAddress, ProjectSettings.get_setting("WAT/Port"))
	_client.allow_object_decoding = true
	if err != OK:
		push_warning("Error creating client : %s" % err as String)
	custom_multiplayer.connect("connection_failed", self, "_on_connection_failed")
	custom_multiplayer.network_peer = _client
	
puppet func test_strategy_received(tests: Array, threads: int) -> void:
	emit_signal("test_strategy", tests, threads)
	
puppet func run_completion_confirmed() -> void:
	get_tree().quit()
	
func _on_failed() -> void:
	push_error("Connection failed")

func _on_run_completed(results: Array) -> void:
	rpc_id(1, "_on_run_completed", results)


