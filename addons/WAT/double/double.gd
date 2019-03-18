extends Node
class_name WATDouble

const TOKENIZER = preload("res://addons/WAT/double/tokenizer.gd")
const REWRITER = preload("res://addons/WAT/double/rewriter.gd")
const METHOD = preload("method.gd")
var _methods: Dictionary = {}
var instance: Object # May need to change if doubling scenes?

func _init(script):
	var source = TOKENIZER.start(script)
	for method in source.methods:
		_add_method(method.name)
	instance = REWRITER.start(source)
	instance.set_meta("double", self)

func _add_method(_name: String) -> void:
	var method: METHOD = METHOD.new(_name)
	_methods[_name] = method

func get_retval(id: String, arguments: Dictionary):
	return _methods[id].get_retval(arguments)

func stub(id: String, arguments: Dictionary, retval) -> void:
	_methods[id].stub(arguments, retval)

func call_count(method: String) -> int:
	return _methods[method].call_count
	
func calls(method) -> Array:
	return _methods[method].calls

