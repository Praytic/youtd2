@tool
class_name ResourceStatusPanel
extends Panel

@export var icon_texture: Texture2D
@export var default_label_text: String

@onready var _label: Label = $MarginContainer/HBoxContainer/Label


func _ready():
	$MarginContainer/HBoxContainer/Icon.texture = icon_texture
	_label.text = default_label_text


func set_label_text(text: String):
	_label.text = text

