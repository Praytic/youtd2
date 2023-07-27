class_name ItemButton 
extends UnitButton

signal right_clicked()


const ICON_SIZE_M = 128

var _item: Item = null

@onready var _cooldown_indicator: CooldownIndicator = $UnitButton/IconContainer/CooldownIndicator

var _hide_cooldown_indicator: bool = false


static func make(item: Item) -> ItemButton:
	var item_button: ItemButton = Globals.item_button_scene.instantiate()
	item_button._item = item

	return item_button


func _ready():
	_set_rarity_icon()
	_set_unit_icon()

	var autocast: Autocast = _item.get_autocast()

	if autocast != null:
		_cooldown_indicator.set_autocast(autocast)
	
	_unit_button.mouse_entered.connect(_on_mouse_entered)
	_unit_button.mouse_exited.connect(_on_mouse_exited)

	if _hide_cooldown_indicator:
		_cooldown_indicator.hide()


func hide_cooldown_indicator():
	_hide_cooldown_indicator = true


func _set_rarity_icon():
	set_rarity(ItemProperties.get_rarity(_item.get_id()))


func _set_unit_icon():
	set_unit_icon(ItemProperties.get_icon(_item.get_id()))


func get_item() -> Item:
	return _item


func _on_mouse_entered():
	EventBus.item_button_mouse_entered.emit(_item)


func _on_mouse_exited():
	EventBus.item_button_mouse_exited.emit()


func _on_unit_button_right_clicked():
	var autocast: Autocast = _item.get_autocast()

	if autocast != null:
		autocast.do_cast_manually()
