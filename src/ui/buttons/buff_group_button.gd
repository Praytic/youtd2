@tool
class_name BuffGroupButton extends Button


@export var _buff_group_number: int = 0
@export var _number_label: Label
@export var _texture_rect: TextureRect

const _buff_group_none_icon: Texture2D = preload("res://resources/ui_textures/buff_group_none.tres")
const _buff_group_incoming_icon: Texture2D = preload("res://resources/ui_textures/buff_group_incoming.tres")
const _buff_group_outgoing_icon: Texture2D = preload("res://resources/ui_textures/buff_group_outgoing.tres")
const _buff_group_both_icon: Texture2D = preload("res://resources/ui_textures/buff_group_both.tres")


#########################
###     Built-in      ###
#########################

func _ready():
	_number_label.text = str(_buff_group_number)


#########################
###       Public      ###
#########################

func get_buff_group_number() -> int:
	return _buff_group_number


func set_buff_group_mode(value: BuffGroupMode.enm):
	match value:
		BuffGroupMode.enm.NONE: 
			_texture_rect.texture = _buff_group_none_icon
			tooltip_text = tr("BUFFGROUP_DESCRIPTION_NONE").format({BUFFGROUP_NUMBER = _buff_group_number})
		BuffGroupMode.enm.OUTGOING: 
			_texture_rect.texture = _buff_group_outgoing_icon
			tooltip_text = tr("BUFFGROUP_DESCRIPTION_OUTGOING").format({BUFFGROUP_NUMBER = _buff_group_number})
		BuffGroupMode.enm.INCOMING: 
			_texture_rect.texture = _buff_group_incoming_icon
			tooltip_text = tr("BUFFGROUP_DESCRIPTION_INCOMING").format({BUFFGROUP_NUMBER = _buff_group_number})
		BuffGroupMode.enm.BOTH: 
			_texture_rect.texture = _buff_group_both_icon
			tooltip_text = tr("BUFFGROUP_DESCRIPTION_BOTH").format({BUFFGROUP_NUMBER = _buff_group_number})
