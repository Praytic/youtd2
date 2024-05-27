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
			tooltip_text = "This tower is not part of buffgroup %d. Press to change\nmode to CASTER." % _buff_group_number
		BuffGroupMode.enm.OUTGOING: 
			_texture_rect.texture = _buff_group_outgoing_icon
			tooltip_text = "This tower is a CASTER in buffgroup %d. It is forced\nto apply buffs to RECEIVER towers in buffgroup %d.\nPress to change mode to RECEIVER." % [_buff_group_number, _buff_group_number]
		BuffGroupMode.enm.INCOMING: 
			_texture_rect.texture = _buff_group_incoming_icon
			tooltip_text = "This tower is a RECEIVER in buffgroup %d. CASTERS in\nbuffgroup %d are forced to buff this tower.\nPress to change mode to BOTH." % [_buff_group_number, _buff_group_number]
		BuffGroupMode.enm.BOTH: 
			_texture_rect.texture = _buff_group_both_icon
			tooltip_text = "This tower is a both a CASTER and a RECEIVER in\nbuffgroup %d. It is forced to apply buffs to RECEIVER\ntowers in buffgroup %d. In addition, CASTERS in\nbuffgroup %d are forced to buff this tower.\nPress to change mode to NONE." % [_buff_group_number, _buff_group_number, _buff_group_number]
