@tool
class_name ResourceStatusPanel
extends Panel


# NOTE: this file is unused


@export var icon_texture: Texture2D
@export var default_label_text: String
@export var _label: Label
@export var _icon: TextureRect


func _ready():
	_icon.texture = icon_texture
	_label.text = default_label_text


func set_label_text(text: String):
	_label.text = text
