class_name ItemButton
extends UnitButton


signal right_clicked()
signal shift_right_clicked()
signal ctrl_right_clicked()


var _item: Item

@export var _cooldown_indicator: CooldownIndicator
@export var _auto_mode_indicator: AutoModeIndicator
@export var _charges_label: Label
@export var _lock_texture: TextureRect

var _show_cooldown_indicator: bool = false
var _show_auto_mode_indicator: bool = false
var _show_charges: bool = false
var _horadric_lock_display_is_enabled: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
	super._ready()
	set_rarity(ItemProperties.get_rarity(_item.get_id()))
	set_icon(ItemProperties.get_icon(_item.get_id()))
	
	var autocast: Autocast = _item.get_autocast()

	if autocast != null:
		_cooldown_indicator.set_autocast(autocast)
		_auto_mode_indicator.set_autocast(autocast)
	
	mouse_entered.connect(_on_mouse_entered)

	_cooldown_indicator.set_visible(_show_cooldown_indicator)
	_auto_mode_indicator.set_visible(_show_auto_mode_indicator)

	_item.charges_changed.connect(_on_item_charges_changed)
	_on_item_charges_changed()

	_item.horadric_lock_changed.connect(_on_item_horadric_lock_changed)
	_on_item_horadric_lock_changed()


func _gui_input(event):
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

# NOTE: need this because ItemButtons should display
# horadric lock only when they are in item stash. Not in
# tower inventory or horadric stash.
func enable_horadric_lock_display():
	_horadric_lock_display_is_enabled = true


func show_cooldown_indicator():
	_show_cooldown_indicator = true


func show_auto_mode_indicator():
	_show_auto_mode_indicator = true


func show_charges():
	_show_charges = true


func get_item() -> Item:
	return _item


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered():
	var tooltip: String = RichTexts.get_item_text(_item)
	ButtonTooltip.show_tooltip(self, tooltip)


func _on_item_charges_changed():
	var charges_count: int = _item.get_charges()
	var charges_text: String = str(charges_count)
	_charges_label.set_text(charges_text)

	var charges_should_be_visible: bool = _item.uses_charges() && _show_charges
	_charges_label.set_visible(charges_should_be_visible)


func _on_item_horadric_lock_changed():
	var horadric_lock_is_enabled: bool = _item.get_horadric_lock_is_enabled()
	_lock_texture.visible = _horadric_lock_display_is_enabled && horadric_lock_is_enabled


#########################
###       Static      ###
#########################

static func make(item: Item) -> ItemButton:
	var item_button: ItemButton = Preloads.item_button_scene.instantiate()
	item_button._item = item

	return item_button
