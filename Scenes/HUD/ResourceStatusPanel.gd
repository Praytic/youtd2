tool
extends Panel

export(Texture) var icon_texture
export(String) var label_text

func _ready():
	$MarginContainer/HBoxContainer/Icon.texture = icon_texture
	$MarginContainer/HBoxContainer/Label.text = label_text
