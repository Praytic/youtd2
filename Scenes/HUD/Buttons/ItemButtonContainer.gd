class_name ItemButton 
extends UnitButton


const ICON_SIZE_M = 128

var _item: Item = null : set = set_item, get = get_item


func _ready():
	_set_rarity_icon()
	_set_unit_icon()
	
	_unit_button.mouse_entered.connect(_on_mouse_entered)
	_unit_button.mouse_exited.connect(_on_mouse_exited)


func _set_rarity_icon():
	set_rarity(ItemProperties.get_rarity(_item.get_id()))


func _set_unit_icon():
	set_unit_icon(ItemProperties.get_icon(_item.get_id()))


func set_item(item: Item):
	_item = item


func get_item() -> Item:
	return _item


func _on_mouse_entered():
	EventBus.item_button_mouse_entered.emit(_item)


func _on_mouse_exited():
	EventBus.item_button_mouse_exited.emit()

