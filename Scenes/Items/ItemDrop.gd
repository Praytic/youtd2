class_name ItemDrop
extends Unit

# ItemDrop represents item after it's dropped but before it's given to a tower.

# TODO: implement giving item to tower. Use id from ItemDrop
# to get create the Item that needs to have


var _id: int = 0 : get = get_id, set = set_id

func _ready():
	super()

	var sprite: Sprite2D = $Base
	if sprite != null:
		_setup_selection_shape_from_sprite(sprite)

	selected.connect(_on_selected)


# NOTE: this must be called once after the itemdrop is created
# but before it's added to game scene.
func set_id(id: int):
	_id = id


func get_id() -> int:
	return _id


func _on_selected():
	EventBus.emit_item_drop_picked_up(_id)
	queue_free()
