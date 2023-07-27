class_name ItemButtonContainer
extends UnitButtonContainer


var _item: Item : set = set_item, get = get_item


static func make(item: Item):
	var item_button_container = Globals.item_button_container_scene.instantiate()
	item_button_container.set_item(item)
	return item_button_container


func _ready():
	super._ready()
	set_button(ItemButton.make(_item))


func get_item() -> Item:
	return _item


func set_item(value: Item):
	_item = value
