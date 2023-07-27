class_name ItemButtonContainer
extends UnitButtonContainer


var _item: Item : set = set_item, get = get_item

var _hide_cooldown_indicator: bool = false


static func make(item: Item):
	var item_button_container = Globals.item_button_container_scene.instantiate()
	item_button_container.set_item(item)
	return item_button_container


func _ready():
	super._ready()

	var actual_button: ItemButton = ItemButton.make(_item)

	if _hide_cooldown_indicator:
		actual_button.hide_cooldown_indicator()

	set_button(actual_button)


func get_item() -> Item:
	return _item


func set_item(value: Item):
	_item = value


func hide_cooldown_indicator():
	_hide_cooldown_indicator = true
