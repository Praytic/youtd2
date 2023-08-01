class_name ItemButton
extends UnitButton


const ICON_SIZE_M = 128

@export var _item_id: int: set = set_item_id, get = get_item_id
var _item: Item : set = set_item, get = get_item

@onready var _cooldown_indicator: CooldownIndicator = %CooldownIndicator

var _hide_cooldown_indicator: bool = false


static func make(item: Item) -> ItemButton:
	var item_button: ItemButton = Globals.item_button_scene.instantiate()
	item_button.set_item(item)
	return item_button


func _ready():
	super._ready()
	set_rarity(ItemProperties.get_rarity(_item.get_id()))
	set_icon(ItemProperties.get_icon(_item.get_id()))
	
	var autocast: Autocast = _item.get_autocast()

	if autocast != null:
		_cooldown_indicator.set_autocast(autocast)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if _hide_cooldown_indicator:
		_cooldown_indicator.hide()


func _gui_input(event):
	var pressed_right_click: bool = event.is_action_released("right_click")

	if pressed_right_click:
		var autocast: Autocast = _item.get_autocast()
		if autocast != null:
			autocast.do_cast_manually()


func hide_cooldown_indicator():
	_hide_cooldown_indicator = true


func get_item() -> Item:
	return _item


func set_item(value: Item):
	_item = value


func get_item_id() -> int:
	assert(_item.get_id() == _item_id, "Invalid state")
	return _item_id


func set_item_id(value: int):
	_item_id = value
	_item = Item.make(value)
# 	NOTE: normally, item would be parented either to item
# 	bar or tower but this code is running for currently
# 	under construction TowerMenu where item buttons are
# 	assigned items in a weird by calling set_item_id() (via
# 	property setter), inside the TowerMenu.tscn.
	add_child(item)


func _on_mouse_entered():
	EventBus.item_button_mouse_entered.emit(_item)


func _on_mouse_exited():
	EventBus.item_button_mouse_exited.emit()
