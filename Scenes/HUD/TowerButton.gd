extends Button


class_name TowerButton 


export(int) var tower_id


onready var tier_icon_texture


func _ready():
	var tower_tier = Properties.get_csv_properties(tower_id)[Tower.Property.TIER]
	var texture = ImageTexture.new()
	var image = Image.new()
	image.load("res://Assets/UI/HUD/level%s.png" % tower_tier)
	texture.create_from_image(image)
	texture.set_size_override(Vector2(16, 16))
	tier_icon_texture = texture


func _draw():
	draw_texture(tier_icon_texture, Vector2.ZERO)
