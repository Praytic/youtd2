extends Node


@onready var debug_enabled = OS.is_debug_build()
@onready var debug_control: Control = %DebugControl
@onready var debug_label: Label = %DebugControl/VBoxContainer/Label
@onready var debug_signals: GridContainer = %DebugControl/VBoxContainer/Signals


var current_node: Node
var prev_node: Node
#var node_selection_blocked: bool = false


func _ready():
	if not debug_enabled:
		return
	_connect_all_nodes(get_tree().get_root().get_node("GameScene"))
	get_tree().node_added.connect(_on_Node_added)
#	debug_control.gui_input.connect(_on_Gui_input)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_node != prev_node:
		if current_node == null:
			debug_control.hide()
			prev_node = current_node
			return
		else:
			debug_control.show()
		
		var signal_list = current_node.get_signal_list()
		for old_signals in debug_signals.get_children():
			old_signals.queue_free()
		
		for i in len(signal_list):
			var node_signal = signal_list[i]
			var button = MenuButton.new()
			button.name = "SignalButton"
			button.text = "%s. %s" % [i, node_signal.name]
			button.pressed.connect(_on_SignalButton_pressed.bind(current_node, node_signal))
			debug_signals.add_child.call_deferred(button)
		debug_label.text = "%s: %s" % [current_node.get_class(), current_node.name]
	prev_node = current_node


func _on_SignalButton_pressed(node, node_signal):
#	node_selection_blocked = false
	node.emit_signal(node_signal["name"], node_signal["args"])


#func _on_Gui_input(event):
#	if event is InputEventMouseButton:
#		if event.get_button_index() == MOUSE_BUTTON_LEFT or event.get_button_index() == MOUSE_BUTTON_RIGHT:
#			node_selection_blocked = true


func _on_Node_added(node: Node):
	if node is MenuButton and node.name == "SignalButton":
		return
	
	if node is Control or node is CollisionObject2D:
		print_debug("Connected [%s] node for debug." % node.name)
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
