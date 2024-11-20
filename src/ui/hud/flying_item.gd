class_name FlyingItem extends Control


# Visual effect for item flying from the ground into item
# stash. Has to be a Control because visual's position needs
# to be unaffected by camera movement. Note that item stays
# inside an invisible item during flying.

# NOTE: flying item doesn't affect game state so it's okay
# to use tweens here.


var _item_id: int = 0
var _end_pos: Vector2 = Vector2.ZERO

@export var _button: Button
@export var _rarity_background: RarityBackground


#########################
###     Built-in      ###
#########################

# Called when the node enters the scene tree for the first time.
func _ready():
	var icon: Texture2D = ItemProperties.get_icon(_item_id)
	var rarity: Rarity.enm = ItemProperties.get_rarity(_item_id)
	_button.set_button_icon(icon)
	_rarity_background.set_rarity(rarity)

	var game_speed: int = Globals.get_update_ticks_per_physics_tick()
	var fly_duration_actual: float = Item.FLY_DURATION / float(game_speed)

	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position",
		_end_pos,
		fly_duration_actual).set_trans(Tween.TRANS_SINE)

	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale",
		Vector2(0, 0),
		0.3 * fly_duration_actual).set_delay(0.7 * fly_duration_actual)

	var finished_tween = create_tween()
	finished_tween.tween_callback(_on_tween_finished).set_delay(fly_duration_actual)


#########################
###     Callbacks     ###
#########################

func _on_tween_finished():
	queue_free()


#########################
###       Static      ###
#########################

static func create(item_id: int, start_pos: Vector2, end_pos: Vector2) -> FlyingItem:
	var flying_item: FlyingItem = Preloads.flying_item_scene.instantiate()
	flying_item.position = start_pos
	flying_item._end_pos = end_pos
	flying_item._item_id = item_id

	return flying_item
