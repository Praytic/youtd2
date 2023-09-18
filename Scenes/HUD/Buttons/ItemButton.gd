class_name ItemButton
extends UnitButton


const ICON_SIZE_M = 128

# NOTE: _test_item_id should be used for testing purposes
# only. For normal gameplay code use Item.make().
@export var _test_item_id: int: set = set_test_item_id, get = get_test_item_id
var _item: Item : set = set_item, get = get_item

@export var _cooldown_indicator: CooldownIndicator
@export var _auto_mode_indicator: AutoModeIndicator
@export var _charges_label: Label

var _show_cooldown_indicator: bool = false
var _show_auto_mode_indicator: bool = false
var _show_charges: bool = false


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
		_auto_mode_indicator.set_autocast(autocast)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_cooldown_indicator.set_visible(_show_cooldown_indicator)
	_auto_mode_indicator.set_visible(_show_auto_mode_indicator)

	_on_item_charges_changed()


func _gui_input(event):
	var pressed_right_click: bool = event.is_action_released("right_click")
	var pressed_shift: bool = Input.is_action_pressed("shift")
	var shift_right_click: bool = pressed_shift && pressed_right_click

	if shift_right_click:
		var autocast: Autocast = _item.get_autocast()
		if autocast != null:
			autocast.toggle_auto_mode()
	elif pressed_right_click:
		var autocast: Autocast = _item.get_autocast()
		if autocast != null:
			autocast.do_cast_manually()

		if _item.is_consumable():
			_item.consume()


func show_cooldown_indicator():
	_show_cooldown_indicator = true


func show_auto_mode_indicator():
	_show_auto_mode_indicator = true


func show_charges():
	_show_charges = true


func get_item() -> Item:
	return _item


func set_item(value: Item):
	_item = value
	_item.charges_changed.connect(_on_item_charges_changed)


func get_test_item_id() -> int:
	if _test_item_id == -1:
		return -1

	assert(_item.get_id() == _test_item_id, "Invalid state")
	return _test_item_id


func set_test_item_id(value: int):
	if value == -1:
		return

	_test_item_id = value
	_item = Item.make(value)
# 	NOTE: normally, item would be parented either to item
# 	bar or tower but this code is running for currently
# 	under construction UnitMenu where item buttons are
# 	assigned items in a weird by calling set_item_id() (via
# 	property setter), inside the UnitMenu.tscn.
	add_child(_item)


func _on_mouse_entered():
	EventBus.item_button_mouse_entered.emit(_item)


func _on_mouse_exited():
	EventBus.item_button_mouse_exited.emit()


func _on_item_charges_changed():
	var charges_count: int = _item.get_charges()
	var charges_text: String = str(charges_count)
	_charges_label.set_text(charges_text)

	var charges_should_be_visible: bool = _item.uses_charges() && _show_charges
	_charges_label.set_visible(charges_should_be_visible)
