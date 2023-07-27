class_name ItemButtonContainer
extends UnitButtonContainer


static func make(item: Item):
	var item_button_container = Globals.item_button_container_scene.instantiate()
	item_button_container.set_button(ItemButton.make(item))
	return item_button_container
