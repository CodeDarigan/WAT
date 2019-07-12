extends Reference

# TODO
# We'll probably handle dependecies here
# Something like double(path, inner, depedency array), then using Class.callv("new", dependecy array)
# Depedencies are only to satisfy constructors that lack defaults, we can probably use the constructor size

const Doubler = preload("doubler.gd")
const FILESYSTEM = preload("res://addons/WAT/utils/filesystem.gd")

var count: int = 0

func double(path, inner: String, dependecies: Array, container: Reference, use_container: bool):
	var doubler = Doubler.new()
	var index = FILESYSTEM.file_list("user://WATemp").size() as String
	index += count as String
	count += 1
	var savepath: String = "user://WATemp/R%s.tres" % index as String
	doubler.base_script = path
	doubler.inner = inner
	doubler.index = index
	ResourceSaver.save(savepath, doubler)
	var double = load(savepath)
	double.dependecies = dependecies
	if use_container:
		double.instanced_base = container.resolve(load(path)) # We're doubling an inner so this doesn't exist?
		double.dependecies = container.get_constructor(load(path))
		if inner != "":
			for i in inner.split(".", false):
				double.dependecies = container.get_constructor(double.instanced_base.get(i))
				double.instanced_base = container.resolve(double.instanced_base.get(i))
	elif not use_container:
		double.instanced_base = load(path).new()
		if inner != "":
			for i in inner.split(".", false):
				double.instanced_base = double.instanced_base.get(i).new()
	double.method_args()
	return double