extends Reference

const BLANK: String = ""
const Settings: Script = preload("res://addons/WAT/settings.gd")
var tests: Dictionary

func discover() -> Dictionary:
	tests.clear()
	tests = {dirs = [], scripts = {}, all = []}
	_discover()
	var metadata = _get_metadata()
	for path in tests.scripts:
		if(metadata.has(path)):
			tests.scripts[path]["tags"] = metadata[path]["tags"]
			if(metadata[path].has("passing")):
				tests.scripts[path]["passing"] = metadata[path]["passing"]
	return tests

func _discover(path: String = Settings.test_directory()) -> Array:
	tests.dirs.append(path)
	var scripts: Array = []
	var subdirs: Array = []
	var dir: Directory = Directory.new()
	var err: int = dir.open(path)
	if err != OK:
		push_error("Error discovering tests in %s : %s " % [path, err as String])
		return []
	dir.list_dir_begin(true)
	var current_name = dir.get_next()
	
	while current_name != BLANK:
		var title: String = path + "/" + current_name
		#																	The third slash is for the leading dir
		if (title.ends_with(".gd") or title.ends_with(".gdc")) and load(title).get("TEST") and title != "res:///addons/WAT/core/test/test.gd" and title != "res:///addons/WAT/core/test/test.gdc":
			var script = load(title)
			var test = {"script": script, "path": title, "tags": [], "passing": false}
			scripts.append(test)
			tests.scripts[title] = test
		elif dir.dir_exists(current_name):
			subdirs.append(title)
#			tests.dirs.append(title)
		current_name = dir.get_next()
	dir.list_dir_end()
	
	for subdir in subdirs:
		# Parent Dirs subsume child dirs
		_discover(subdir)
	tests[path] = scripts
	tests.all += scripts
	return scripts
	
func _get_metadata() -> Dictionary:
	var path: String = ProjectSettings.get_setting("WAT/Test_Metadata_Directory") + "/test_metadata.json"
	var file: File = File.new()
	var err: int = file.open(path, File.READ)
	if err != OK:
		push_warning("Error loading test metadata from %s : %s" % [path, err as String])
		return {}
	var metadata: Dictionary = JSON.parse(file.get_as_text()).result
	file.close()
	return metadata
	
func save(data: Dictionary) -> void:
	var path: String = ProjectSettings.get_setting("WAT/Test_Metadata_Directory") + "/test_metadata.json"
	var file: File = File.new()
	var err: int = file.open(path, File.WRITE)
	if err != OK:
		push_warning("Error saving test metadata to %s : %s" % [path, err as String])
	for test in data.scripts:
		var value = data.scripts[test]
		value.erase("script")
	var val: String = JSON.print(data.scripts, "\t")
	file.store_string(val)
	file.close()
