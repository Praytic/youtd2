extends Node

var _log : Callable

func _ready():
	_mk_log.call_deferred()


func _mk_log():
	var text := TextEdit.new()
	text.name = "Log"
	text.editable = false
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(text)
	var types = ["D: ", "W: ", "E: "]
	_log = func(type, msg):
		text.insert_line_at(text.get_line_count()-1,
			types[clampi(type, 0, types.size() - 1)] + str(msg))
	debug("Logging Start")


func run(script_path: String, data: Dictionary):
	var script := load(script_path) as Script
	if script == null:
		error("Failed to load script:\n%s" % script_path)
		return
	var found = script.get_script_method_list().filter(func(e): return e["name"] == "run_static")
	if found.size() < 1:
		error("Script must contain a 'run_static' static method:\n%s" % script_path)
		return
	var sdk := W4Client.new(data, true)
	sdk.log_function = _log
	add_child(sdk)
	if has_node(^"/root/W4GD"):
		get_node(^"/root/W4GD").service = sdk
	await script.call("run_static", sdk)


func debug(msg):
	if _log.is_valid(): _log.call(0, msg)


func warning(msg):
	if _log.is_valid(): _log.call(1, msg)


func error(msg):
	if _log.is_valid(): _log.call(2, msg)


func fail():
	breakpoint
	pass
