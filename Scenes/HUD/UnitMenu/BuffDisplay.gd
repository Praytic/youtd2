class_name BuffDisplay extends PanelContainer


@export var _texture_rect: TextureRect


#########################
###       Public      ###
#########################

func set_buff(buff: Buff):
	var texture_path: String = buff.get_buff_icon()

	if !ResourceLoader.exists(texture_path):
		if buff.is_hidden():
			texture_path = "res://Assets/Buffs/question_mark.png"
		elif buff.is_friendly():
			texture_path = "res://Assets/Buffs/buff_plus.png"
		else:
			texture_path = "res://Assets/Buffs/buff_minus.png"
	
	var texture: Texture2D = load(texture_path)
	_texture_rect.texture = texture

	var tooltip: String = buff.get_tooltip_text()
	set_tooltip_text(tooltip)


#########################
###      Private      ###
#########################

func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = Utils.make_rich_text_tooltip(for_text)

	return label
