class_name BuffDisplay extends PanelContainer


const BUFF_ICON_DIR: String = "res://Resources/Textures/Buffs"


@export var _texture_rect: TextureRect


#########################
###       Public      ###
#########################

func set_buff(buff: Buff):
	var buff_icon_filename: String = buff.get_buff_icon()
	var buff_icon_path: String = "%s/%s" % [BUFF_ICON_DIR, buff_icon_filename]

	if !ResourceLoader.exists(buff_icon_path):
		buff_icon_path = "%s/egg.tres" % BUFF_ICON_DIR
	
	var texture: Texture2D = load(buff_icon_path)
	_texture_rect.texture = texture

	var tooltip: String = buff.get_tooltip_text()
	set_tooltip_text(tooltip)

	var color: Color = buff.get_buff_icon_color()
	_texture_rect.modulate = color


#########################
###      Private      ###
#########################

func _make_custom_tooltip(for_text: String) -> Object:
	var label: RichTextLabel = Utils.make_rich_text_tooltip(for_text)

	return label
