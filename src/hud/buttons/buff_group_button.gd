@tool
class_name BuffGroupButton extends Button


@export var _number_label: Label
@export var _buff_group_number: int = 0

@onready var _texture_rect: TextureRect = $TextureRect
@onready var _buff_group_none_icon: Texture2D = load("res://resources/ui_textures/buff_group_none.tres")
@onready var _buff_group_incoming_icon: Texture2D = load("res://resources/ui_textures/buff_group_incoming.tres")
@onready var _buff_group_outgoing_icon: Texture2D = load("res://resources/ui_textures/buff_group_outgoing.tres")
@onready var _buff_group_both_icon: Texture2D = load("res://resources/ui_textures/buff_group_both.tres")

var _tower: Tower = null


#########################
###     Built-in      ###
#########################

func _ready():
	_number_label.text = str(_buff_group_number)


#########################
###       Public      ###
#########################

func set_tower(tower: Tower):
	var prev_tower: Tower = _tower
	if prev_tower != null && prev_tower.buff_group_changed.is_connected(_on_tower_buff_group_changed):
		prev_tower.buff_group_changed.disconnect(_on_tower_buff_group_changed)

	_tower = tower
	
	if tower != null:
		tower.buff_group_changed.connect(_on_tower_buff_group_changed)
		_update_visual()


#########################
###     Callbacks     ###
#########################

func _on_pressed():
	EventBus.player_clicked_tower_buff_group.emit(_tower, _buff_group_number)


func _on_tower_buff_group_changed():
	_update_visual()


func _update_visual():
	var mode: BuffGroupMode.enm = _tower.get_buff_group_mode(_buff_group_number)

	match mode:
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
