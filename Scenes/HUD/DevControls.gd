extends Control


@onready var dev_control_buttons = get_tree().get_nodes_in_group("dev_control_button")
@onready var dev_controls = get_tree().get_nodes_in_group("dev_control")
@onready var positional_control: PopupMenu = $PositionalControl
@onready var oil_ids: Array = []
@onready var item_ids: Array = []
@onready var position_info_label: Label = $PositionInfoLabel

@onready var _map = get_tree().get_root().get_node("GameScene/Map")

func _ready():
	for dev_control in dev_controls:
		dev_control.close_requested.connect(func (): dev_control.hide())
	
	for dev_control_button in dev_control_buttons:
		dev_control_button.button_up.connect(_on_DevControlButton_button_up.bind(dev_control_button))
	
	_init_oils_and_items_controls()


func _process(delta):
	position_info_label.position = get_global_mouse_position()
	var accumulated_info = {}
	accumulated_info["global_mouse_position"] = get_global_mouse_position()
	accumulated_info["mouse_pos_on_tilemap_clamped"] = _map.get_mouse_pos_on_tilemap_clamped()
	accumulated_info["mouse_pos_on_tilemap"] = _map.get_mouse_world_pos()
	position_info_label.text = _dict_join(accumulated_info)


func _dict_join(accumulated_info: Dictionary, separator = "\n") -> String:
	var output = "";
	for pos_type in accumulated_info.keys():
		output += "%s %s%s" % [pos_type, accumulated_info[pos_type], separator]
	output = output.left( output.length() - separator.length() )
	return output


func _init_oils_and_items_controls():
	oil_ids = Properties.get_item_id_list_by_filter(Item.CsvProperty.IS_OIL, "TRUE")
	item_ids = Properties.get_item_id_list_by_filter(Item.CsvProperty.IS_OIL, "FALSE")
	
	assert(oil_ids.size() > 0 and item_ids.size() > 0, \
	"Data file for items and oils probably has been updated.")
	
	var oil_submenu = PopupMenu.new()
	oil_submenu.set_name("oil_submenu")
	positional_control.add_child(oil_submenu)
	
	var item_submenu = PopupMenu.new()
	item_submenu.set_name("item_submenu")
	positional_control.add_child(item_submenu)
	
	for oil_id in oil_ids:
		var oil_name = ItemProperties.get_item_name(oil_id)
		oil_submenu.add_item(oil_name, oil_id)
	
	for item_id in item_ids:
		var item_name = ItemProperties.get_item_name(item_id)
		item_submenu.add_item(item_name, item_id)
	
	positional_control.add_submenu_item("Spawn Oil", "oil_submenu")
	positional_control.add_submenu_item("Spawn Item", "item_submenu")
	oil_submenu.id_pressed.connect(_on_PositionalControl_id_pressed)
	item_submenu.id_pressed.connect(_on_PositionalControl_id_pressed)


func _unhandled_input(event):
	if event is InputEventMouse:
		var right_click: bool = event.is_action_released("right_click")
		if right_click:
			positional_control.show()
			positional_control.position = event.position
		else:
			positional_control.hide()

func _on_DevControlButton_button_up(button: Button):
	var control_name = button.get_name().replace("Button", "")
	for dev_control in dev_controls:
		if dev_control.get_name() == control_name:
			dev_control.show()
			break

func _on_PositionalControl_id_pressed(id):
	if oil_ids.has(id) or item_ids.has(id):
		var clicked_pos: Vector2 = positional_control.position
		var hud_to_world: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
		var clicked_pos_in_world: Vector2 = hud_to_world * clicked_pos
		Item.create_without_player(id, clicked_pos_in_world)
