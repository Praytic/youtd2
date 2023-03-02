class_name ItemDrop
extends Unit

# ItemDrop represents item after it's dropped but before it's given to a tower.

# TODO: implement giving item to tower. Use id from ItemDrop
# to get create the Item that needs to have


const SELECTION_SIZE = 32


var _id: int = 0 setget set_id, get_id


# NOTE: this must be called once after the itemdrop is created
# but before it's added to game scene.
func set_id(id: int):
	_id = id


func get_id() -> int:
	return _id


# NOTE: this is an example of how item can be made based on
# id. Actual implementation of transforming an ItemDrop to
# an Item can inline this f-n.
func make_item() -> Item:
	var item_properties: Dictionary = Properties.get_item_csv_properties()[_id]
	var script_name: String = item_properties[Item.CsvProperty.SCRIPT_NAME]
	var script_path: String = "res://Scenes/Items/Instances/%s.gd" % [script_name]
	var item: Item = load(script_path).new()
	item.set_id(_id)

	return item

func get_selection_size() -> int:
	return SELECTION_SIZE
