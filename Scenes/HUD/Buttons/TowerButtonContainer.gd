class_name TowerButtonContainer
extends UnitButtonContainer


const _tier_icons_m = preload("res://Assets/Towers/tier_icons_m.png")

const TIER_ICON_SIZE_M = 64

@onready var _tier_icon: TextureRect = %TierIcon

var _tower_id: int : set = set_tower_id, get = get_tower_id


static func make(tower_id: int):
	var tower_button_container = Globals.tower_button_container_scene.instantiate()
	tower_button_container.set_tower_id(tower_id)
	return tower_button_container


func _ready():
	set_button(TowerButton.make(_tower_id))
	set_tier_icon(_tower_id)


func set_tier_icon(tower_id: int):
	var tower_rarity = TowerProperties.get_rarity_num(tower_id)
	var tower_tier = TowerProperties.get_tier(tower_id) - 1
	var tier_icon = AtlasTexture.new()
	var icon_size: int
	
	tier_icon.set_atlas(_tier_icons_m)
	icon_size = TIER_ICON_SIZE_M
	
	tier_icon.set_region(Rect2(tower_tier * icon_size, tower_rarity * icon_size, icon_size, icon_size))
	_tier_icon.texture = tier_icon


func get_tower_id() -> int:
	return _tower_id


func set_tower_id(value: int):
	_tower_id = value
