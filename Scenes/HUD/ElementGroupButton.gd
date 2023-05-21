@tool
extends TextureButton


@export var element = Element.enm.ASTRAL # (Element.enm)


func _ready():
	var texture: AtlasTexture = texture_normal
	var texture_size = texture.region.size.x
	texture.region.position.x = element * texture_size
