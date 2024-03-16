class_name ItemDrop
extends Unit

# ItemDrop is the visual for the item when it is dropped on
# the ground. Contains item instance inside it.


const _item_drop_scene_map: Dictionary = {
	"res://Scenes/Items/CommonItem.tscn": preload("res://Scenes/Items/CommonItem.tscn"),
	"res://Scenes/Items/UncommonItem.tscn": preload("res://Scenes/Items/UncommonItem.tscn"),
	"res://Scenes/Items/RareItem.tscn": preload("res://Scenes/Items/RareItem.tscn"),
	"res://Scenes/Items/UniqueItem.tscn": preload("res://Scenes/Items/UniqueItem.tscn"),
	"res://Scenes/Items/RedOil.tscn": preload("res://Scenes/Items/RedOil.tscn"),
}

var _item: Item = null
@export var _selection_area: Area2D


#########################
###     Built-in      ###
#########################

# NOTE: note calling Unit._set_unit_dimensions() because no
# sprite on base class and dimensions are not important for
# ItemDrop's.
func _ready():
	super()

	_setup_selection_signals(_selection_area)
	_set_visual_node(self)

	selected.connect(_on_selected)
	
# 	TODO: calculate correct z index so that item drop is
# 	drawn behind creeps/towers when it should.
	z_index = 100


#########################
###       Public      ###
#########################

func get_id() -> int:
	return _item.get_id()


#########################
###     Callbacks     ###
#########################

# NOTE: don't allow picking up invisible items
func _on_selected():
	var can_pickup: bool = _item._visible

	if can_pickup:
		_item.fly_to_stash(0.0)


#########################
###       Static      ###
#########################

static func make(item: Item, drop_position: Vector2) -> ItemDrop:
	if item.get_parent() != null:
		push_error("Item must be unparented before being added to ItemDrop.")

		return null

	var item_id: int = item.get_id()
	var rarity: Rarity.enm = ItemProperties.get_rarity(item_id)
	var rarity_string: String = Rarity.convert_to_string(rarity)
	var item_drop_scene_path: String
	if ItemProperties.get_is_oil(item_id):
		item_drop_scene_path = "res://Scenes/Items/RedOil.tscn"
	else:
		item_drop_scene_path = "res://Scenes/Items/%sItem.tscn" % rarity_string.capitalize()
	var item_drop_scene: PackedScene = _item_drop_scene_map[item_drop_scene_path]
	var item_drop: ItemDrop = item_drop_scene.instantiate()
	item_drop.position = drop_position
	item_drop.visible = item._visible
	item_drop.set_player(item.get_player())
	item_drop._item = item
	item_drop.add_child(item)

	Utils.add_object_to_world(item_drop)
	
	return item_drop
