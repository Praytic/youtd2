extends Button


class_name TowerButton 


export(int) var tower_id


onready var tier_icon: StreamTexture

func _ready():
	var tower_tier = Properties.get_tower_csv_properties_by_id(tower_id)[Tower.CsvProperty.TIER]
	var resource_path = "res://Assets/UI/HUD/level%s.png" % tower_tier
	tier_icon = load(resource_path)


# TODO: removed drawing of tier for now so that id can be
# drawn, better for testing
func _draw():
	pass
	# draw_texture(tier_icon, Vector2.ZERO)
