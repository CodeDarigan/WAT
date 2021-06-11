extends Button
tool

enum { 
	RUN_ALL, 
	RUN_DIR, 
	RUN_SCRIPT, 
	RUN_TAG, 
	RUN_METHOD, 
	RUN_FAILURES,
	
	DEBUG_ALL,
	DEBUG_DIR,
	DEBUG_SCRIPT,
	DEBUG_TAG,
	DEBUG_METHOD,
	DEBUG_FAILURES, 
	}
	
var FOLDER_ICON: Texture
var FAILED_ICON: Texture
var SCRIPT_ICON: Texture
var PLAY_ICON: Texture
var PLAY_DEBUG_ICON: Texture
var LABEL_ICON: Texture
var FUNCTION_ICON: Texture
const TestGatherer: Script = preload("res://addons/WAT/editor/test_gatherer.gd")
const ABOUT_TO_SHOW: String = "about_to_show"
const IDX_PRESSED: String = "index_pressed"
const ON_IDX_PRESSED: String = "_on_idx_pressed"
onready var Directories: PopupMenu = $Directories
onready var Scripts: PopupMenu = $Directories/Scripts
onready var Methods: PopupMenu = $Directories/Scripts/Methods
onready var Tags: PopupMenu = $Directories/Tags
onready var TagEditor: PopupMenu = $Directories/Scripts/Methods/TagEditor
var test: Dictionary
signal _tests_selected
signal _tests_debug_selected
var pool: Array = []

func _init() -> void:
	test = TestGatherer.new().discover()
	
func _exit_tree() -> void:
	TestGatherer.new().save(test)
	clear()
	
func clear():
	for item in range(pool.size(), -1, 0):
		pool.pop_back().free()
	
func refresh() -> void:
	if ProjectSettings.get_setting("WAT/Auto_Refresh_Tests") or Engine.get_version_info().minor < 3:
		var test_gatherer = TestGatherer.new()
		test_gatherer.save(test)
		test = test_gatherer.discover()
		
func save_metadata() -> void:
	TestGatherer.new().save(test)
	
func _ready() -> void:
	Directories.connect(ABOUT_TO_SHOW, self, "_on_dirs_about_to_show")
	Tags.connect(ABOUT_TO_SHOW, self, "_on_tags_about_to_show")
	Directories.connect(IDX_PRESSED, self, ON_IDX_PRESSED, [Directories])
	Tags.connect(IDX_PRESSED, self, ON_IDX_PRESSED, [Tags])
	
func _on_idx_pressed(idx: int, menu: PopupMenu) -> void:
	var metadata: Dictionary = menu.get_item_metadata(idx)
	select_tests(metadata)
	
func select_tests(metadata: Dictionary) -> void:
	var tests: Array = []
	match metadata.command:
		RUN_TAG, DEBUG_TAG:
			var tag: String = metadata.tag
			for t in test.scripts:
				var container = test.scripts[t]
				if container["tags"].has(tag as String):
					tests.append(container)
		RUN_FAILURES, DEBUG_FAILURES:
			for path in test.scripts:
				var container: Dictionary = test.scripts[path]
				if container.has("passing") and not container["passing"]:
					tests.append(container)
			push_warning("RUN FAILURES NOT IMPLEMENTED")
	clear()
	if metadata.command < DEBUG_ALL:
		# We're in run mode
		emit_signal("_tests_selected", tests)
	else:
		# We're in debug mode
		emit_signal("_tests_debug_selected", tests)
	
func set_last_run_success(results) -> void:
	for result in results:
		test.scripts[result["path"]]["passing"] = result.success
	
func _on_tag_editor_idx_pressed(idx, tagEditor) -> void:
	var container: Dictionary = test.scripts[tagEditor.get_item_metadata(idx)]
	var tag: String = tagEditor.get_item_text(idx)
	if tagEditor.is_item_checked(idx):
		container["tags"].erase(tag)
		tagEditor.set_item_checked(idx, false)
	else:
		container["tags"].append(tag as String)
		tagEditor.set_item_checked(idx, true)
		
func _on_dirs_about_to_show() -> void:
	refresh()
	Directories.clear()
	Directories.set_as_minsize()
	Directories.add_item("Rerun Failures")
	Directories.set_item_icon(0, FAILED_ICON)
	Directories.add_item("Rerun Failures With Debug")
	Directories.set_item_icon(1, FAILED_ICON)
	Directories.add_submenu_item("Tags", "Tags")
	Directories.set_item_icon(2, LABEL_ICON)
	Directories.set_item_metadata(0, {command = RUN_FAILURES})
	Directories.set_item_metadata(1, {command = DEBUG_FAILURES})
	var dirs: Array = test.dirs
	if dirs.empty():
		return
	var idx: int = Directories.get_item_count()
	for dir in dirs:
		if not test[dir].empty():
			var script = Scripts.duplicate(true)
			script.connect(IDX_PRESSED, self, ON_IDX_PRESSED, [script])
			pool.append(script)
			script.name = idx as String
			Directories.add_child(script, true)
			Directories.add_submenu_item(dir, idx as String, idx)
			Directories.set_item_icon(idx, FOLDER_ICON)
			script.connect(ABOUT_TO_SHOW, self, "_on_scripts_about_to_show", [script])
			idx += 1
	
func _on_scripts_about_to_show(scripts) -> void:
	refresh()
	scripts.clear()
	scripts.set_as_minsize()

#	scripts.add_item("Run All")
	var currentdir: String = Directories.get_item_text(scripts.name as int)
#	scripts.set_item_metadata(0, {command = RUN_DIR, path = currentdir})
#	scripts.set_item_icon(0,FOLDER_ICON)
#
#	scripts.add_item("Run All With Debug")
#	scripts.set_item_metadata(1, {command = DEBUG_DIR, path = currentdir})
#	scripts.set_item_icon(1, PLAY_DEBUG_ICON)
#	if not Engine.is_editor_hint():
#		scripts.set_item_disabled(1, true)

	var scriptlist: Array = test[currentdir]
	if scriptlist.empty():
		return
	var idx: int = scripts.get_item_count()
	for child in scripts.get_children():
		child.name += "Thrash"
	for script in scriptlist:
		var method = Methods.duplicate(true)
		method.connect(IDX_PRESSED, self, ON_IDX_PRESSED, [method])
		pool.append(method)
		method.name = idx as String
		scripts.add_child(method, true)
		scripts.add_submenu_item(script["path"], method.name, idx)
		scripts.set_item_icon(idx, SCRIPT_ICON)
		method.connect(ABOUT_TO_SHOW, self, "_on_methods_about_to_show", [method, scripts])
		idx += 1
	
func _on_methods_about_to_show(methods, scripts) -> void:
	refresh()
	methods.clear()
	methods.set_as_minsize()
	var tag_editor = TagEditor.duplicate(true)
	pool.append(tag_editor)
	tag_editor.name = "tagEditor"
	methods.add_child(tag_editor)
	methods.add_submenu_item("Edit Tags", tag_editor.name)
	tag_editor.connect(ABOUT_TO_SHOW, self, "_on_tag_editor_about_to_show", [tag_editor, scripts])
	methods.set_item_metadata(0, {command = RUN_TAG, tag = "?"})
	methods.set_item_icon(0, LABEL_ICON)

func _on_tags_about_to_show() -> void:
	refresh()
	var tags: PoolStringArray = ProjectSettings.get_setting("WAT/Tags")
	Tags.clear()
	Tags.set_as_minsize()
	var idx: int = Tags.get_item_count()
	for taglabel in tags:
		Tags.add_item(taglabel)
		Tags.set_item_metadata(idx, {command = RUN_TAG, tag = taglabel})
		idx += 1
		Tags.add_item(taglabel + " (Debug) ")
		Tags.set_item_metadata(idx, {command = DEBUG_TAG, tag = taglabel})
		idx += 1
		
		
func _on_tag_editor_about_to_show(tagEditor, scripts) -> void:
	refresh()
	tagEditor.clear()
	tagEditor.set_as_minsize()
	var currentScript: String = scripts.get_item_text(scripts.name as int)
	var container = test.scripts[currentScript]
	var tags: PoolStringArray = ProjectSettings.get_setting("WAT/Tags")
	var idx: int = tagEditor.get_item_count()
	if not tagEditor.is_connected(IDX_PRESSED, self, "_on_tag_editor_idx_pressed"):
		tagEditor.connect(IDX_PRESSED, self, "_on_tag_editor_idx_pressed", [tagEditor])
	for tag in tags:
		tagEditor.add_check_item(tag)
		tagEditor.set_item_checked(idx, container["tags"].has(tag))
		tagEditor.set_item_metadata(idx, currentScript)
		tagEditor.set_item_as_checkable(idx, true)
		idx += 1
		
func _pressed() -> void:
	var position = rect_global_position
	position.y += rect_size.y
	Directories.rect_global_position = position
	Directories.rect_size = Vector2(rect_size.x, 0)
	Directories.grab_focus()
	Directories.popup()

func _add_test_dirs_recursively(path: String) -> void:
	var subdirs: Array = []
	test.dirs.append(path)
	test[path] = []
	var dir: Directory = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true)
	var current_name: String = dir.get_next()
	var title: String = path + "/" + current_name
	if title.ends_with(".gd") and load(title).get("TEST"):
		var script = load(title)
		var t = {"script": script, "path": title, "tags": []}
		test.scripts[title] = t
		test[path].append(t)
		test.all.append(t)
	elif dir.dir_exists(title):
		subdirs.append(title)
	for subdir in subdirs:
		_add_test_dirs_recursively(subdir)

# Loads scaled assets like icons and fonts
func _setup_editor_assets(assets_registry):
	FOLDER_ICON = assets_registry.load_asset("assets/folder.png")
	FAILED_ICON = assets_registry.load_asset("assets/failed.png")
	SCRIPT_ICON = assets_registry.load_asset("assets/script.png")
	PLAY_ICON = assets_registry.load_asset("assets/play.png")
	PLAY_DEBUG_ICON = assets_registry.load_asset("assets/play_debug.png")
	LABEL_ICON = assets_registry.load_asset("assets/label.png")
	FUNCTION_ICON = assets_registry.load_asset("assets/function.png")