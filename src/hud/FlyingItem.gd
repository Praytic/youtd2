class_name FlyingItem extends Control


# Visual effect for item flying from the ground into item
# stash. Has to be a Control because visual's position needs
# to be unaffected by camera movement. Note that item stays
# inside an invisible item during flying.

# NOTE: flying item doesn't affect game state so it's okay
# to use tweens here.


var _item_id: int = 0

@export var _unit_button: UnitButton


#########################
###     Built-in      ###
#########################

# Called when the node enters the scene tree for the first time.
func _ready():
	var icon: Texture2D = ItemProperties.get_icon(_item_id)
	var rarity: Rarity.enm = ItemProperties.get_rarity(_item_id)
	_unit_button.set_icon(icon)
	_unit_button.set_rarity(rarity)

# 	NOTE: couldn't figure out why unit button is smaller
# 	than it should be. Hackfix by manually changing the
# 	scale.
	_unit_button.scale = Vector2(1.5, 1.5)
	
	var hud: Control = get_tree().get_root().get_node("GameScene/UI/HUD")
	var item_stash_button: Button = hud.get_item_stash_button()
	var target_pos: Vector2 = item_stash_button.global_position + Vector2(45, 45)
	
	var pos_tween = create_tween()
	pos_tween.tween_property(self, "position",
		target_pos,
		Item.FLY_DURATION).set_trans(Tween.TRANS_SINE)

	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale",
		Vector2(0, 0),
		0.3 * Item.FLY_DURATION).set_delay(0.7 * Item.FLY_DURATION)

	var finished_tween = create_tween()
	finished_tween.tween_callback(_on_tween_finished).set_delay(Item.FLY_DURATION)


#########################
###     Callbacks     ###
#########################

func _on_tween_finished():
	queue_free()


#########################
###       Static      ###
#########################

static func create(item_id: int, start_pos: Vector2) -> FlyingItem:
	var flying_item: FlyingItem = Preloads.flying_item_scene.instantiate()
	flying_item.position = start_pos
	flying_item._item_id = item_id
	flying_item.scale = Vector2(0.5, 0.5)

	return flying_item
