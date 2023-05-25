class_name ItemDrop
extends Unit

# ItemDrop is the visual for the item when it is dropped on
# the ground. Contains item instance inside it.


var _item: Item = null

func _ready():
	super()

	var sprite: Sprite2D = $Base
	if sprite != null:
		_set_unit_sprite(sprite)

	selected.connect(_on_selected)


# NOTE: this must be called once after the itemdrop is created
# but before it's added to game scene.
func set_item(item: Item):
	_item = item


func get_id() -> int:
	return _item.get_id()

# TODO: don't add item to item stash right here. Do it after flying item visual completes
func _on_selected():
	EventBus.emit_item_drop_picked_up(_item)
	EventBus.item_drop_picked_up_2.emit(self)
	queue_free()
