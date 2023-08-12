@tool
extends TextureButton


const ICON_SIZE_S = 64

@onready var element_atlas = preload("res://Assets/Towers/tower_icons_s.png")

@export var element = Element.enm.ASTRAL # (Element.enm)

var research_mode: bool


func _ready():
	var texture: AtlasTexture = AtlasTexture.new()
	texture.set_atlas(element_atlas)
	texture.set_region(Rect2(element * ICON_SIZE_S, 0, ICON_SIZE_S, ICON_SIZE_S))
	texture_normal = texture


func _make_custom_tooltip(for_text: String) -> Object:
	var label = RichTextLabel.new()
	label.append_text(for_text)
	return label
