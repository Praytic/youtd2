class_name ItemDrop
extends Unit

# ItemDrop represents item after it's dropped but before it's given to a tower.

# TODO: implement giving item to tower. Use id from ItemDrop
# to get create the Item that needs to have


const SELECTION_SIZE = 32


var _id: int = 0 : get = get_id, set = set_id


# NOTE: this must be called once after the itemdrop is created
# but before it's added to game scene.
func set_id(id: int):
	_id = id


func get_id() -> int:
	return _id


func get_selection_size() -> int:
	return SELECTION_SIZE
