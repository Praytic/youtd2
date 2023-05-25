class_name FlyingItem extends Control


# Visual effect for item flying from the ground into item
# stash. Has to be a Control because visual's position needs
# to be unaffected by camera movement.


var _item_id: int = 0
var _target_pos: Vector2 = Vector2.ZERO

@onready var _texture_rect: TextureRect = $TextureRect


static func create(item_id: int, start_pos: Vector2, target_pos: Vector2) -> FlyingItem:
	var scene: PackedScene = load("res://Scenes/HUD/FlyingItem.tscn")
	var flying_item: FlyingItem = scene.instantiate()
	flying_item.position = start_pos
	flying_item._target_pos = target_pos
	flying_item._item_id = item_id
	flying_item.scale = Vector2(0.5, 0.5)

	return flying_item


# Called when the node enters the scene tree for the first time.
func _ready():
	var icon: Texture2D = ItemProperties.get_icon(_item_id)
	_texture_rect.texture = icon
	
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position",
		_target_pos,
		1.0).set_trans(Tween.TRANS_SINE)

	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale",
		Vector2(0, 0),
		0.3).set_delay(0.7)
