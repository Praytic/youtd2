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

# 	TODO: calculate correct z index so that item drop is
# 	drawn behind creeps/towers when it should.
	z_index = 100


# NOTE: this must be called once after the itemdrop is created
# but before it's added to game scene.
func set_item(item: Item):
	_item = item


func get_id() -> int:
	return _item.get_id()

func _on_selected():
	_item.fly_to_stash(0.0)
