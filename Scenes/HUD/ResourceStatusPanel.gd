tool
extends Panel

export(Texture) var icon_texture
export(String) var default_label_text

onready var _label: Label = $MarginContainer/HBoxContainer/Label


func _ready():
	$MarginContainer/HBoxContainer/Icon.texture = icon_texture
	_label.text = default_label_text


func set_label_text(text: String):
	_label.text = text

