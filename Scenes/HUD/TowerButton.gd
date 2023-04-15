class_name TowerButton 
extends Button


const ICON_SIZE_S = 64
const ICON_SIZE_M = 128
const TIER_ICON_SIZE_S = 32
const TIER_ICON_SIZE_M = 64

var tier_icon

var _tower_id: int
@onready var _icon_size: String : set = set_icon_size
@onready var _tier_icons_s = preload("res://Assets/Towers/tier_icons_s.png")
@onready var _tier_icons_m = preload("res://Assets/Towers/tier_icons_m.png")
@onready var _tower_icons_s = preload("res://Assets/Towers/tower_icons_s.png")
@onready var _tower_icons_m = preload("res://Assets/Towers/tower_icons_m.png")
@onready var _tower_button_fallback_icon = preload("res://Assets/icon.png")


func _ready():
	set_theme_type_variation("TowerButton")

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)


func _draw():
	draw_texture(tier_icon, Vector2.ZERO)


func set_icon_size(icon_size: String):
	_icon_size = icon_size
	tier_icon = _get_tower_button_tier_icon(icon_size)
	icon = _get_tower_button_icon(icon_size)


func set_tower(tower_id: int):
	_tower_id = tower_id


func _get_tower_button_tier_icon(icon_size_letter: String) -> Texture2D:
	var tower_tier = TowerProperties.get_tier(_tower_id) - 1
	var tower_rarity = TowerProperties.get_rarity_num(_tower_id)
	
	var icon_out = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		icon_out.set_atlas(_tier_icons_s)
		icon_size = TIER_ICON_SIZE_S
	elif icon_size_letter == "M":
		icon_out.set_atlas(_tier_icons_m)
		icon_size = TIER_ICON_SIZE_M
	else:
		return _tower_button_fallback_icon
	
	icon_out.set_region(Rect2(tower_tier * icon_size, tower_rarity * icon_size, icon_size, icon_size))
	return icon_out

func _get_tower_button_icon(icon_size_letter: String) -> Texture2D:
	var icon_atlas_num: int = TowerProperties.get_icon_atlas_num(_tower_id)
	if icon_atlas_num == -1:
		return _tower_button_fallback_icon

	var tower_icon = AtlasTexture.new()
	var icon_size: int
	if icon_size_letter == "S":
		tower_icon.set_atlas(_tower_icons_s)
		icon_size = ICON_SIZE_S
	elif icon_size_letter == "M":
		tower_icon.set_atlas(_tower_icons_m)
		icon_size = ICON_SIZE_M
	else:
		return _tower_button_fallback_icon
	
	var region: Rect2 = Rect2(TowerProperties.get_element(_tower_id) * icon_size, icon_atlas_num * icon_size, icon_size, icon_size)
	tower_icon.set_region(region)

	return tower_icon


func _on_mouse_entered():
	EventBus.emit_tower_button_mouse_entered(_tower_id)


func _on_mouse_exited():
	EventBus.emit_tower_button_mouse_exited()


func _on_pressed():
	BuildTower.start_building_tower(_tower_id)
