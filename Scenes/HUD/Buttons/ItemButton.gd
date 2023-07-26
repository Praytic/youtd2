class_name ItemButton 
extends UnitButton


var _item: Item = null

@onready var _cooldown_indicator: CooldownIndicator = $UnitButton/IconContainer/CooldownIndicator

var _hide_cooldown_indicator: bool = false


static func make(item: Item) -> ItemButton:
	var item_button: ItemButton = Globals.item_button_scene.instantiate()
	item_button._item = item

	return item_button


func init():
	_set_rarity_icon(_item)
	_set_unit_icon(_item)
	_set_autocast(_item)
	
	_unit_button.mouse_entered.connect(_on_mouse_entered)
	_unit_button.mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_unit_button_clicked)
	
	if _hide_cooldown_indicator:
		_cooldown_indicator.hide()


func _ready():
	if _item != null:
		init()


func hide_cooldown_indicator():
	_hide_cooldown_indicator = true


func _set_autocast(item: Item):
	var autocast: Autocast = item.get_autocast()

	if autocast != null:
		_cooldown_indicator.set_autocast(autocast)


func _set_rarity_icon(item: Item):
	_rarity = ItemProperties.get_rarity(item.get_id()) if item != null else ""


func _set_unit_icon(item: Item):
	if _unit_button == null:
		return
	
	_unit_button.icon = ItemProperties.get_icon(item.get_id() if item != null else 0)


func _on_mouse_entered():
	EventBus.item_button_mouse_entered.emit(_item)


func _on_mouse_exited():
	EventBus.item_button_mouse_exited.emit()


func _on_unit_button_clicked(event):
	if event.is_action_released("right_click"):
		var autocast: Autocast = _item.get_autocast()
		if autocast != null:
			autocast.do_cast_manually()
