class_name ItemButton 
extends Button


const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const TIER_ICON_SIZE_S = 32
const TIER_ICON_SIZE_M = 64

var tier_icon

@onready var _item: Item : get = get_item, set = set_item
@onready var _icon_size: String : set = set_icon_size
@onready var _tier_icons_s = preload("res://Assets/Towers/tier_icons_s.png")
@onready var _tier_icons_m = preload("res://Assets/Towers/tier_icons_m.png")
@onready var _item_button_fallback_icon = preload("res://Assets/icon.png")


func _ready():
	set_theme_type_variation("TowerButton")
	icon = Item.get_icon(_item.get_id(), "M")


# NOTE: turn off drawing tier icon so that item's icon gets drawn
# func _draw():
# 	draw_texture(tier_icon, Vector2.ZERO)


func set_icon_size(icon_size: String):
	_icon_size = icon_size
	tier_icon = _get_item_button_tier_icon(icon_size)
	icon = Item.get_icon(_item.get_id(), icon_size)


func set_item(item: Item):
	_item = item

func get_item() -> Item:
	return _item
	
func _get_item_button_tier_icon(icon_size_letter: String) -> Texture2D:
	var item_rarity = _item.get_rarity_num()
	
	var icon_out = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		icon_out.set_atlas(_tier_icons_s)
		icon_size = TIER_ICON_SIZE_S
	elif icon_size_letter == "M":
		icon_out.set_atlas(_tier_icons_m)
		icon_size = TIER_ICON_SIZE_M
	else:
		return _item_button_fallback_icon
	
	icon_out.set_region(Rect2(6 * icon_size, item_rarity * icon_size, icon_size, icon_size))
	return icon_out
