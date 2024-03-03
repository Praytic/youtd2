extends Node

const ICON_SIZE = 128
const MAX_ICONS_PER_FAMILY = 5

@onready var creep_icons: Texture2D = preload("res://Assets/Mobs/creep_icons_atlas.png")


func get_icon_texture(creep: Creep) -> Texture2D:
	var x: int = creep.get_size()
	var y: int = creep.get_category()
	
	assert(x != -1 and y != -1, "Unknown icon for creep [%s]" % creep)

	var icon = AtlasTexture.new()
	icon.set_atlas(creep_icons)
	icon.set_region(Rect2(x * ICON_SIZE, y * ICON_SIZE, ICON_SIZE, ICON_SIZE))

	return icon
