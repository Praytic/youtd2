class_name TowerItemContainer extends ItemContainer


# This is a subclass of ItemContainer used by Tower.
# Implements additional functionality for storing oils and
# applying item effects on tower when items are in the
# container.


# NOTE: oils go into a separate list which has unlimited
# capacity
var _oil_list: Array[Item] = []
var _tower: Tower


func _init(capacity: int, tower: Tower):
	super(capacity)
	_tower = tower


func add_item(item: Item, slot_index: int = 0):
	item._add_to_tower(_tower)
	
	var is_oil: bool = ItemProperties.get_is_oil(item.get_id())

	if is_oil:
		_oil_list.append(item)
	else:
		super.add_item(item, slot_index)


func remove_item(item: Item):
	item._remove_from_tower()

	var item_id: int = item.get_id()
	var is_oil: bool = ItemProperties.get_is_oil(item_id)

	if is_oil:
		_oil_list.erase(item)
	else:
		super.remove_item(item)


func get_oil_list() -> Array[Item]:
	return _oil_list.duplicate()
