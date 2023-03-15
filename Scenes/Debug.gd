extends Node


@onready var debug_enabled = OS.is_debug_build()
@onready var debug_control: Control = %DebugControl
@onready var debug_label: Label = %DebugControl/VBoxContainer/Label
@onready var debug_signals: GridContainer = %DebugControl/VBoxContainer/Signals
@onready var signal_arg_edit: LineEdit = %DebugControl/SignalArgEdit

var current_node: Node
var prev_node: Node
#var node_selection_blocked: bool = false
var acc_delta: float = 0


func _ready():
	if not debug_enabled:
		return
	_connect_all_nodes(get_tree().get_root().get_node("GameScene"))
	get_tree().node_added.connect(_on_Node_added)
#	debug_control.gui_input.connect(_on_Gui_input)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_node != prev_node and acc_delta > 1:
		if current_node == null:
			debug_control.hide()
			prev_node = current_node
			return
		
		debug_control.show()
		
		var signal_list = current_node.get_signal_list()
		for old_signals in debug_signals.get_children():
			old_signals.queue_free()
		
		for i in len(signal_list):
			var node_signal = signal_list[i]
			var button = MenuButton.new()
			button.name = "SignalButton"
			button.text = "%s. %s" % [i, node_signal.name]
			for node_signal_arg in signal_list[i]["args"]:
				button.get_popup().add_item(node_signal_arg["name"])
			for node_signal_arg in signal_list[i]["default_args"]:
				button.get_popup().add_item(node_signal_arg["name"])
			if button.get_popup().item_count == 0:
				button.get_popup().add_item("no-args")
			button.get_popup().id_pressed.connect(_on_SignalButton_pressed.bind(button.get_popup(), current_node, node_signal))
			debug_signals.add_child.call_deferred(button)
		debug_label.text = "%s: %s" % [current_node.get_class(), current_node.name]
		acc_delta = 0
	else: 
		acc_delta += delta
	prev_node = current_node


func _on_SignalButton_pressed(id: int, popup: PopupMenu, node, node_signal):
	if popup.get_item_text(id) == "no-args":
		print_debug("Manual signal [%s] was emitted on node [%s] with [no-args]." % [node_signal["name"], node])
		node.emit_signal(node_signal["name"])
	else:
		signal_arg_edit.show()
		signal_arg_edit.clear()
		signal_arg_edit.text_submitted.disconnect(_on_SignalArgEdit_submitted)
		signal_arg_edit.text_submitted.connect(_on_SignalArgEdit_submitted.bind(popup.get_item_text(id), node, node_signal))


func _on_SignalArgEdit_submitted(command, arg_name, node, node_signal):
	var expression = Expression.new()
	var error = expression.parse(command)
	if error != OK:
		print_debug(expression.get_error_text())
		return
	var result = expression.execute()
	
	var arg
	if not expression.has_execute_failed():
		arg = result
	else:
		arg = command
	
	print_debug("Manual signal [%s] was emitted on node [%s] with [%s=%s]." % [node_signal["name"], node, arg_name, arg])
	node.emit_signal(node_signal["name"], arg)
	
	signal_arg_edit.hide()
	signal_arg_edit.clear()


#func _on_Gui_input(event):
#	if event is InputEventMouseButton:
#		if event.get_button_index() == MOUSE_BUTTON_LEFT or event.get_button_index() == MOUSE_BUTTON_RIGHT:
#			node_selection_blocked = true


func _on_Node_added(node: Node):
	if (node is Control or node is CollisionObject2D) and not _is_parent_of(node, debug_control):
		node.mouse_entered.connect(_on_Node_mouse_entered.bind(node))
		node.mouse_exited.connect(_on_Node_mouse_exited.bind(node))


func _on_Node_mouse_entered(node: Node):
#	if not node_selection_blocked:
	current_node = node


func _on_Node_mouse_exited(_node: Node):
	current_node = null


func _connect_all_nodes(node):
	for n in node.get_children():
		if n.get_instance_id() == debug_control.get_instance_id():
			continue
		_on_Node_added(n)
		if n.get_child_count() > 0:
			_connect_all_nodes(n)


func _is_parent_of(node, parent_node) -> bool:
	if node == null:
		return false
	elif node.get_instance_id() == parent_node.get_instance_id():
		return true
	else:
		return _is_parent_of(node.get_parent(), parent_node)
