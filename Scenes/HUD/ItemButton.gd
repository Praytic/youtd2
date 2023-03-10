class_name ItemButton 
extends Button


const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const TIER_ICON_SIZE_S = 32
const TIER_ICON_SIZE_M = 64

var tier_icon

var _tier_icon_s: AtlasTexture
var _item_icon_s: AtlasTexture
var _tier_icon_m: AtlasTexture
var _item_icon_m: AtlasTexture

@onready var _item : get = get_item, set = set_item
@onready var _icon_size: String : set = set_icon_size
@onready var _tier_icons_s = preload("res://Assets/Items/tier_icons_s.png")
@onready var _tier_icons_m = preload("res://Assets/Items/tier_icons_m.png")
@onready var _item_icons_s = preload("res://Assets/Items/item_icons_s.png")
@onready var _item_icons_m = preload("res://Assets/Items/item_icons_m.png")
@onready var _item_button_fallback_icon = preload("res://Assets/icon.png")


func _ready():
	set_theme_type_variation("TowerButton")


# TODO: removed drawing of tier for now so that id can be
# drawn, better for testing
func _draw():
	draw_texture(tier_icon, Vector2.ZERO)


func set_icon_size(icon_size: String):
	_icon_size = icon_size
	tier_icon = _get_item_button_tier_icon(icon_size)
	icon = _get_item_button_icon(icon_size)


func set_item(item):
	_item = item

func get_item():
	return _item
	
func _get_item_button_tier_icon(icon_size_letter: String) -> Texture2D:
	var item_tier = _item.get_tier() - 1
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
	
	icon_out.set_region(Rect2(item_tier * icon_size, item_rarity * icon_size, icon_size, icon_size))
	return icon_out

func _get_item_button_icon(icon_size_letter: String) -> Texture2D:
	var icon_atlas_num: int = _item.get_icon_atlas_num()
	var icon_atlas_family: int = _item.get_icon_atlas_family()
	if icon_atlas_num == -1 or icon_atlas_family == -1:
		return _item_button_fallback_icon

	var item_icon = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		item_icon.set_atlas(_item_icons_s)
		icon_size = ICON_SIZE_S
	elif icon_size_letter == "M":
		item_icon.set_atlas(_item_icons_m)
		icon_size = ICON_SIZE_M
	else:
		return _item_button_fallback_icon
	
	var region: Rect2 = Rect2(icon_atlas_num * icon_size, icon_atlas_family * icon_size, icon_size, icon_size)
	item_icon.set_region(region)

	return item_icon

