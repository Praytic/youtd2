class_name TowerButton 
extends Button


const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const TIER_ICON_SIZE_S = 32
const TIER_ICON_SIZE_M = 64

var tier_icon

var _tier_icon_s: AtlasTexture
var _tower_icon_s: AtlasTexture
var _tier_icon_m: AtlasTexture
var _tower_icon_m: AtlasTexture

onready var _tower setget set_tower, get_tower
onready var _icon_size: String setget set_icon_size
onready var _tier_icons_s = preload("res://Assets/Towers/tier_icons_s.png")
onready var _tier_icons_m = preload("res://Assets/Towers/tier_icons_m.png")
onready var _tower_icons_s = preload("res://Assets/Towers/tower_icons_s.png")
onready var _tower_icons_m = preload("res://Assets/Towers/tower_icons_m.png")
onready var _tower_button_fallback_icon = preload("res://Assets/icon.png")


func _ready():
	set_theme_type_variation("TowerButton")


# TODO: removed drawing of tier for now so that id can be
# drawn, better for testing
func _draw():
	draw_texture(tier_icon, Vector2.ZERO)


func set_icon_size(icon_size: String):
	_icon_size = icon_size
	tier_icon = _get_tower_button_tier_icon(icon_size)
	icon = _get_tower_button_icon(icon_size)


func set_tower(tower):
	_tower = tower

func get_tower():
	return _tower
	
func _get_tower_button_tier_icon(icon_size: String) -> Texture:
	var tower_tier = _tower.get_tier() - 1
	var tower_rarity = _tower.get_rarity_num()
	
	var tier_icon = AtlasTexture.new()
	var size: int
	if icon_size == "S":
		tier_icon.set_atlas(_tier_icons_s)
		size = TIER_ICON_SIZE_S
	elif icon_size == "M":
		tier_icon.set_atlas(_tier_icons_m)
		size = TIER_ICON_SIZE_M
	else:
		return _tower_button_fallback_icon
	
	tier_icon.set_region(Rect2(tower_tier * size, tower_rarity * size, size, size))
	return tier_icon

func _get_tower_button_icon(icon_size: String) -> Texture:
	var icon_atlas_num: int = _tower.get_icon_atlas_num()
	if icon_atlas_num == -1:
		return _tower_button_fallback_icon

	var tower_icon = AtlasTexture.new()
	var size: int
	if icon_size == "S":
		tower_icon.set_atlas(_tower_icons_s)
		size = ICON_SIZE_S
	elif icon_size == "M":
		tower_icon.set_atlas(_tower_icons_m)
		size = ICON_SIZE_M
	else:
		return _tower_button_fallback_icon
	
	var region: Rect2 = Rect2(_tower.get_element() * size, icon_atlas_num * size, size, size)
	tower_icon.set_region(region)

	return tower_icon

