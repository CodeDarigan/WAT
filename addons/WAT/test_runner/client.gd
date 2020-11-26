extends Node

enum {
	COMMAND
	CONNECTED
	STRATEGY
	RESULTS
}

const DO_NOT_ALLOW_FULL_OBJECTS: bool = false
signal StrategyReceived
var is_connected_to_client: bool = false
const DEFAULT_PORT = 6000
const IP_ADDRESS: String = "127.0.0.1"
var client: StreamPeerTCP

func join() -> void:
	client = StreamPeerTCP.new()
	var p: int = get_port()
	client.connect_to_host(IP_ADDRESS, p)
	
func _process(delta: float) -> void:
	if client != null and client.is_connected_to_host() and client.get_available_bytes() > 0:
		_process_command(client.get_var(DO_NOT_ALLOW_FULL_OBJECTS))
		
func _process_command(cmd: Dictionary) -> void:
	match cmd[COMMAND]:
		STRATEGY:
			emit_signal("StrategyReceived", cmd["strategy"])
		RESULTS:
			pass
		_:
			pass # NoValidCommandFound (Error?)
		
func send_results(results: Array) -> void:
	if client.is_connected_to_host():
		var x = {COMMAND: RESULTS, "results": results}
		client.put_var(x)
		
func get_port() -> int:
	if ProjectSettings.has_setting("WAT/Port"):
		return ProjectSettings.get_setting("WAT/Port")
	return DEFAULT_PORT
	
func quit() -> void:
	client.disconnect_from_host()