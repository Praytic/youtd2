class_name ItemDrop
extends Unit

# ItemDrop is the visual for the item when it is dropped on
# the ground. Contains item instance inside it.


var _item: Item = null
@export var _selection_area: Area2D
@export var _visual: Node2D


#########################
###     Built-in      ###
#########################

# NOTE: note calling Unit._set_unit_dimensions() because no
# sprite on base class and dimensions are not important for
# ItemDrop's.
func _ready():
	super()

	_setup_selection_signals(_selection_area)
	_set_visual_node(_visual)

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
