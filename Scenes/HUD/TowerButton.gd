extends Button


class_name TowerButton 


export(int) var tower_id


onready var tier_icon: StreamTexture

func _ready():
	var tower_tier = Properties.get_csv_properties(tower_id)[Tower.TowerProperty.TIER]
	var resource_path = "res://Assets/UI/HUD/level%s.png" % tower_tier
	tier_icon = load(resource_path)


func _draw():
	draw_texture(tier_icon, Vector2.ZERO)
