class_name TowerItemContainer extends ItemContainer


# This is a subclass of ItemContainer used by Tower.
# Implements additional functionality for storing oils and
# applying item effects on tower when items are in the
# container.


# NOTE: oils go into a separate list which has unlimited
# capacity
var _oil_list: Array[Item] = []
var _tower: Tower


#########################
###     Built-in      ###
#########################

func _init(capacity: int, tower: Tower):
	set_capacity(capacity)
	_tower = tower


#########################
###       Public      ###
#########################

func add_item(item: Item, insert_index: int = -1):
	var is_oil: bool = ItemProperties.get_is_oil(item.get_id())

	if is_oil:
		_oil_list.append(item)
		add_child(item)
	else:
		super.add_item(item, insert_index)

#	NOTE: order is important here. Need to call add_item()
#	to do add_child() before calling _add_to_tower()
	item._add_to_tower(_tower)

# 	NOTE: hackfix alert! The _is_oil_and_was_applied_already
# 	flag is used to know when we are transferring oils from
# 	one tower to another, either when towers get upgraded or
# 	transformed. In such cases, we do not show the application
# 	Effect again.
	if is_oil && !item._is_oil_and_was_applied_already:
		var effect_pos: Vector3 = _tower.get_position_wc3()
		effect_pos.z += Constants.TILE_SIZE_WC3 * 0.25	
		var effect_id: int = Effect.create_animated("res://src/effects/bdragon_519_expanding_puff.tscn", effect_pos, 0)
		Effect.set_scale(effect_id, 2)
		Effect.destroy_effect_after_its_over(effect_id)

		item._is_oil_and_was_applied_already = true


# NOTE: order is important here. Need to call
# _remove_from_tower() last so that item properties like
# _carrier are available before that point.
# _remove_from_tower() clears those properties.
func remove_item(item: Item):
	var item_id: int = item.get_id()
	var is_oil: bool = ItemProperties.get_is_oil(item_id)

	if is_oil:
		_oil_list.erase(item)
		remove_child(item)
	else:
		super.remove_item(item)
	
	item._remove_from_tower()


func get_oil_list() -> Array[Item]:
	return _oil_list.duplicate()


# NOTE: if item is oil, then we don't care about item space
# - can add unlimited amount of oils
func can_add_item(item: Item) -> bool:
	var item_id: int = item.get_id()
	var is_oil: bool = ItemProperties.get_is_oil(item_id)
	var can_add: bool = have_item_space() || is_oil

	return can_add
