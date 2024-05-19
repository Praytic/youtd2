class_name ItemDrop extends Unit


# ItemDrop is the storage for the item when it is dropped on
# the ground. Contains item instance as child. Note that
# this class is basically a vestigial thing from original
# youtd because in youtd2 it's always invisible. In original
# youtd, items could be moved around on the ground but in
# youtd2, items are always either in item stash or tower
# inventory. The only functional thing this class does in
# youtd2 is storing the item while it's flying to item stash
# and also if it somehow becomes visible then that's a
# signal that something went wrong.


@export var _visual: Node2D


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	_set_visual_node(_visual)

# 	NOTE: use 100 so that item drops is drawn in front of
# 	all units. Not important because ItemDrops are almost
# 	never visible.
	z_index = 100


#########################
###       Static      ###
#########################

static func make(item: Item, drop_pos: Vector3) -> ItemDrop:
	if item.get_parent() != null:
		push_error("ItemDrop.make() was called on an item which still has a parent. Item must be unparented before being added to ItemDrop. Forcefully removing item from parent to proceed.")
		item.get_parent().remove_child(item)
	
	var item_drop_scene: PackedScene = preload("res://src/items/item_drop.tscn")
	var item_drop: ItemDrop = item_drop_scene.instantiate()
	item_drop.set_position_wc3(drop_pos)
#	NOTE: in youtd2, item drops are always invisible
	item_drop.visible = false
	item_drop.set_player(item.get_player())
	item_drop.add_child(item)

	return item_drop
