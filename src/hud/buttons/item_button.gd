class_name ItemButton
extends UnitButton


signal right_clicked()
signal shift_right_clicked()
signal ctrl_right_clicked()
signal horadric_lock_changed()


var _item: Item

@export var _time_indicator: TimeIndicator
@export var _auto_mode_indicator: AutoModeIndicator
@export var _charges_label: Label
@export var _lock_texture: TextureRect

var _show_charges: bool = false
var _horadric_lock_display_is_enabled: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
	super._ready()

	_set_item_internal(null)


func _gui_input(event):
	if _item == null:
		return

	var pressed_right_click: bool = event.is_action_released("right_click")
	var pressed_shift: bool = Input.is_action_pressed("shift")
	var pressed_ctrl: bool = Input.is_action_pressed("ctrl")
	var shift_right_click: bool = pressed_shift && pressed_right_click
	var ctrl_right_click: bool = pressed_ctrl && pressed_right_click

	if shift_right_click:
		shift_right_clicked.emit()
	elif ctrl_right_click:
		ctrl_right_clicked.emit()
	elif pressed_right_click:
		right_clicked.emit()


#########################
###       Public      ###
#########################

# NOTE: button becomes transparent if item is null
func set_item(item: Item):
	var item_changed: bool = item != _item

	if item_changed:
		_set_item_internal(item)


# NOTE: need this because ItemButtons should display
# horadric lock only when they are in item stash. Not in
# tower inventory or horadric stash.
func set_horadric_lock_visible(value: bool):
	_horadric_lock_display_is_enabled = value


func set_cooldown_indicator_visible(value: bool):
	_time_indicator.visible = value


func set_auto_mode_indicator_visible(value: bool):
	_auto_mode_indicator.visible = value


func set_charges_visible(value: bool):
	_show_charges = value


func get_item() -> Item:
	return _item


#########################
###      Private      ###
#########################

# NOTE: need this sub f-n to be able to set initial item to
# null. set_item() only executes if item changed and
# null->null is detected as no change.
func _set_item_internal(item: Item):
	var prev_item: Item = _item

	_item = item

	var button_color: Color
	if item != null:
		button_color = Color.WHITE
	else:
		button_color = Color.TRANSPARENT
	modulate = button_color

	if item != null:
		var item_id: int = _item.get_id()
		
		var item_icon: Texture2D = ItemProperties.get_icon(item_id)
		set_icon(item_icon)
		
		var item_rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
		set_rarity(item_rarity)

	var autocast: Autocast
	if item != null:
		autocast = _item.get_autocast()
	else:
		autocast = null

	_time_indicator.set_autocast(autocast)
	_auto_mode_indicator.set_autocast(autocast)

	if prev_item != null:
		prev_item.charges_changed.disconnect(_on_item_charges_changed)
		prev_item.horadric_lock_changed.disconnect(_on_item_horadric_lock_changed)

	if item != null:
		_item.charges_changed.connect(_on_item_charges_changed)
		_on_item_charges_changed()

		_item.horadric_lock_changed.connect(_on_item_horadric_lock_changed)
		_on_item_horadric_lock_changed()


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	if _item == null:
		return

	var tooltip: String = RichTexts.get_item_text(_item)
	ButtonTooltip.show_tooltip(self, tooltip, _tooltip_location)


func _on_item_charges_changed():
	if _item == null:
		return
	
	var charges_count: int = _item.get_charges()
	var charges_text: String = str(charges_count)
	_charges_label.set_text(charges_text)

	var charges_should_be_visible: bool = _item.uses_charges() && _show_charges
	_charges_label.set_visible(charges_should_be_visible)


func _on_item_horadric_lock_changed():
	if _item == null:
		return
	
	var horadric_lock_is_enabled: bool = _item.get_horadric_lock_is_enabled()
	_lock_texture.visible = _horadric_lock_display_is_enabled && horadric_lock_is_enabled

	horadric_lock_changed.emit()


#########################
###       Static      ###
#########################

static func make() -> ItemButton:
	var item_button: ItemButton = Preloads.item_button_scene.instantiate()

	return item_button
