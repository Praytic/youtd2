class_name ItemDrop
extends Unit

# ItemDrop is the visual for the item when it is dropped on
# the ground. Contains item instance inside it.

enum ItemDropState {
	SPAWNING,
	STILL,
	GATHERING,
	NONE
}

@onready var _sprite = $Base
@onready var _state: ItemDropState = ItemDropState.SPAWNING

var _item: Item = null


func _ready():
	super()
	
	if _sprite != null:
		_set_unit_sprite(_sprite)
		if _sprite is AnimatedSprite2D:
			_sprite.animation_finished.connect(_change_state)
	
	selected.connect(_on_selected)
	
# 	TODO: calculate correct z index so that item drop is
# 	drawn behind creeps/towers when it should.
	z_index = 100

func _change_state():
	_state += 1
	if _state == ItemDropState.STILL:
		_sprite.animation = "still"

func _process(delta):
	if _sprite is AnimatedSprite2D:
		_sprite.play()

# NOTE: this must be called once after the itemdrop is created
# but before it's added to game scene.
func set_item(item: Item):
	_item = item


func get_id() -> int:
	return _item.get_id()

func _on_selected():
	_item.fly_to_stash(0.0)
