tool
extends EditorPlugin

const RUN_CURRENT_SCENE_GODOT_3_2: int = 39
const RUN_CURRENT_SCENE_GODOT_3_1: int = 33
const Title: String = "Tests"
const Settings: Script = preload("res://addons/WAT/settings.gd")
const GUI: PackedScene = preload("res://addons/WAT/gui.tscn")
const Docker: Script = preload("res://addons/WAT/ui/scripts/docker.gd")
const PluginAssetsRegistry: Script = preload("res://addons/WAT/ui/scripts/plugin_assets_registry.gd")
var instance: Control
var docker: Docker
var script_editor: ScriptEditor
var assets_registry = PluginAssetsRegistry.new(self)

func _ready():
	# Editor assets must be setup at ready time to give GUI scripts a chance to 
	# ready themselves first and store references to other nodes, which will be 
	# needed to call_setup_editor_assets() on.
	instance._setup_editor_assets(assets_registry)

func _enter_tree():
	Settings.initialize()
	_initialize_metadata()
	instance = GUI.instance()
	docker = Docker.new(self, instance)
	script_editor = get_editor_interface().get_script_editor()
	instance.connect("launched_via_editor", self, "_on_launched_via_editor")
	instance.connect("function_selected", self, "_on_function_selected")
	add_child(docker)
	yield(get_tree().create_timer(0.5), "timeout")
	if Engine.get_version_info().minor > 2:
		var filedock = get_editor_interface().call("get_file_system_dock")
		observe_filesystem(filedock, instance.TestMenu)
	if not is_connected("resource_saved", instance.TestMenu, "_on_resource_saved"):
		connect("resource_saved", instance.TestMenu, "_on_resource_saved")
	
func _exit_tree():
	if is_connected("resource_saved", instance.TestMenu, "_on_resource_saved"):
		disconnect("resource_saved", instance.TestMenu, "_on_resource_saved")
	if Engine.get_version_info().minor > 2:
		var filedock = get_editor_interface().call("get_file_system_dock")	
		stop_observing_filesystem(filedock, instance.TestMenu)
	docker.free()
	instance.free()
	
func _on_launched_via_editor() -> void:
	var version = Engine.get_version_info()
	if get_editor_interface().has_method("play_custom_scene"):
		print("launch?")
		get_editor_interface().play_custom_scene("res://addons/WAT/core/test_runner/TestRunner.tscn")
	elif version.major == 3 and version.minor == 1:
		print("branch 2")
		get_editor_interface().open_scene_from_path("res://addons/WAT/core/test_runner/TestRunner.tscn")
		get_editor_interface().get_parent()._menu_option(RUN_CURRENT_SCENE_GODOT_3_1)
	elif version.major == 3 and version.minor == 2:
		print("branch 3")
		get_editor_interface().open_scene_from_path("res://addons/WAT/core/test_runner/TestRunner.tscn")
		get_editor_interface().get_parent()._menu_option(RUN_CURRENT_SCENE_GODOT_3_2)
	else:
		print("branch 4")
	make_bottom_panel_item_visible(instance)
	
func _on_function_selected(file: String, function: String) -> void:
	var script: Script = load(file)
	get_editor_interface().edit_resource(script)
	var idx: int = 0
	for line in script.source_code.split("\n"):
		idx += 1
		if function in line and line.begins_with("func"):
			script_editor.goto_line(idx)
			return

func _initialize_metadata() -> void:
	# Check if file exists!
	var path: String = ProjectSettings.get_setting("WAT/Test_Metadata_Directory") + "/test_metadata.json"
	if Directory.new().file_exists(path):
		return
	var file: File = File.new()
	var err: int = file.open(path, File.WRITE)
	if err != OK:
		push_warning("Error saving test metadata to %s : %s" % [path, err as String])
		return
	file.store_string("{}")
	file.close()
	
func observe_filesystem(filesystem, menu: Button) -> void:
	if not filesystem.is_connected("folder_moved", menu, "_on_folder_moved"):
		filesystem.connect("folder_moved", menu, "_on_folder_moved")
	if not filesystem.is_connected("folder_removed", menu, "_on_folder_removed"):
		filesystem.connect("folder_removed", menu, "_on_folder_removed")
	if not filesystem.is_connected("files_moved", menu, "_on_file_moved"):
		filesystem.connect("files_moved", menu, "_on_file_moved")
	if not filesystem.is_connected("file_removed", menu, "_on_file_removed"):
		filesystem.connect("file_removed", menu, "_on_file_removed")
	

func stop_observing_filesystem(filesystem, menu: Button) -> void:
	if filesystem.is_connected("folder_moved", menu, "_on_folder_moved"):
		filesystem.disconnect("folder_moved", menu, "_on_folder_moved")
	if filesystem.is_connected("folder_removed", menu, "_on_folder_removed"):
		filesystem.disconnect("folder_removed", menu, "_on_folder_removed")
	if filesystem.is_connected("files_moved", menu, "_on_file_moved"):
		filesystem.disconnect("files_moved", menu, "_on_file_moved")
	if filesystem.is_connected("file_removed", menu, "_on_file_removed"):
		filesystem.disconnect("file_removed", menu, "_on_file_removed")
