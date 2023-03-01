class_name TowerButton 
extends Button


const tier_icon_size = 32


export(int) var tower_id


onready var tier_icon: AtlasTexture
onready var _tier_icons = preload("res://Assets/UI/HUD/misc.png")


func _ready():
	var tower = TowerManager.get_tower(tower_id)
	var tower_tier = tower.get_tier() - 1
	var tower_rarity = tower.get_rarity_num()
	tier_icon = AtlasTexture.new()
	tier_icon.set_atlas(_tier_icons)
	var x = tower_tier * tier_icon_size
	var y = tower_rarity * tier_icon_size
	tier_icon.set_region(Rect2(x, y, tier_icon_size, tier_icon_size))


# TODO: removed drawing of tier for now so that id can be
# drawn, better for testing
func _draw():
	draw_texture(tier_icon, Vector2.ZERO)
