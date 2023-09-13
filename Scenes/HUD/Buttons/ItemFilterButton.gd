@tool
extends TextureButton


@export var rarity_filter: Rarity
@export var item_type_filter: ItemType


func _ready():
	var texture: AtlasTexture = AtlasTexture.new()
	texture.set_atlas(item_filter_atlas)
	texture.set_region(Rect2(element * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE))
	texture_normal = texture
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	ElementLevel.changed.connect(_on_element_level_changed)
