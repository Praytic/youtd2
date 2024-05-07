class_name BuffDisplay extends PanelContainer


const FALLBACK_BUFF_ICON: String = "res://Resources/Icons/GenericIcons/egg.tres"


@export var _texture_rect: TextureRect


#########################
###       Public      ###
#########################

func set_buff(buff: Buff):
	var buff_icon_path: String = buff.get_buff_icon()

	if !ResourceLoader.exists(buff_icon_path):
		buff_icon_path = FALLBACK_BUFF_ICON
	
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
