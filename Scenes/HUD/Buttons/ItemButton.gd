class_name ItemButton
extends UnitButton


const ICON_SIZE_M = 128

var _item: Item : set = set_item, get = get_item

@onready var _cooldown_indicator: CooldownIndicator = $%CooldownIndicator

var _hide_cooldown_indicator: bool = false


static func make(item: Item) -> ItemButton:
	var item_button: ItemButton = Globals.item_button_scene.instantiate()
	
	item_button.set_item(item)
	item_button.set_rarity(ItemProperties.get_rarity(item.get_id()))
	item_button.set_icon(ItemProperties.get_icon(item.get_id()))
	
	return item_button


func _ready():
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


func _on_mouse_entered():
	EventBus.item_button_mouse_entered.emit(_item)


func _on_mouse_exited():
	EventBus.item_button_mouse_exited.emit()
