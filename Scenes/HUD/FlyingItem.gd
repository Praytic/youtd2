class_name FlyingItem extends Control


# Visual effect for item flying from the ground into item
# stash. Has to be a Control because visual's position needs
# to be unaffected by camera movement.

signal finished_flying()

const ANIMATION_DURATION: float = 1.0

var _item_id: int = 0

@onready var _texture_rect: TextureRect = $TextureRect

# NOTE: adding type "BottomMenuBar" to "_bottom_menu_bar"
# variable causes confusing runtime errors. Might be a
# cyclic dependency issue? Thought it was fixed with the
# release of Godot 4.
@onready var _bottom_menu_bar = get_tree().get_root().get_node("GameScene").get_node("UI").get_node("HUD").get_node("BottomMenuBar")


static func create(item_id: int, start_pos: Vector2) -> FlyingItem:
	var scene: PackedScene = load("res://Scenes/HUD/FlyingItem.tscn")
	var flying_item: FlyingItem = scene.instantiate()
	flying_item.position = start_pos
	flying_item._item_id = item_id
	flying_item.scale = Vector2(0.5, 0.5)

	return flying_item


# Called when the node enters the scene tree for the first time.
func _ready():
	var icon: Texture2D = ItemProperties.get_icon(_item_id)
	_texture_rect.texture = icon
	
	var item_menu_button: Control = _bottom_menu_bar.get_item_menu_button()
	var target_pos: Vector2 = item_menu_button.global_position + Vector2(45, 45)

	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position",
		target_pos,
		ANIMATION_DURATION).set_trans(Tween.TRANS_SINE)

	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale",
		Vector2(0, 0),
		0.3 * ANIMATION_DURATION).set_delay(0.7 * ANIMATION_DURATION)

	var finished_tween = create_tween()
	finished_tween.tween_callback(_on_tween_finished).set_delay(ANIMATION_DURATION)


func _on_tween_finished():
	finished_flying.emit()
