extends Button


signal buff_group_changed(group_number: int, mode: BuffGroup.Mode)


@export var _buff_group_number: int
@onready var _texture_rect: TextureRect = $TextureRect
@onready var _buff_group_none_icon: Texture2D = load("res://Resources/Textures/UI/Icons/buff_group_none.tres")
@onready var _buff_group_incoming_icon: Texture2D = load("res://Resources/Textures/UI/Icons/buff_group_incoming.tres")
@onready var _buff_group_outgoing_icon: Texture2D = load("res://Resources/Textures/UI/Icons/buff_group_outgoing.tres")
@onready var _buff_group_both_icon: Texture2D = load("res://Resources/Textures/UI/Icons/buff_group_both.tres")


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	


func _on_selected_unit_changed(_prev_unit: Unit):
	if SelectUnit.get_selected_unit() is Tower:
		show()
		_update_visual()
	else:
		hide()


func _on_pressed():
	_next_buff_group_mode()
	_update_visual()


func _next_buff_group_mode():
	var previous_mode: BuffGroup.Mode = get_current_mode()
	if previous_mode == BuffGroup.Mode.BOTH:
		BuffGroup.remove_unit_from_buff_group(get_buff_group_number(), BuffGroup.Mode.INCOMING)
		BuffGroup.remove_unit_from_buff_group(get_buff_group_number(), BuffGroup.Mode.OUTGOING)
	elif previous_mode != BuffGroup.Mode.NONE:
		BuffGroup.remove_unit_from_buff_group(get_buff_group_number(), previous_mode)
	
	var mode: BuffGroup.Mode = (previous_mode + 1) % BuffGroup.modes_list.size()
	
	if mode == BuffGroup.Mode.BOTH:
		BuffGroup.add_unit_to_buff_group(get_buff_group_number(), BuffGroup.Mode.INCOMING)
		BuffGroup.add_unit_to_buff_group(get_buff_group_number(), BuffGroup.Mode.OUTGOING)
	elif mode != BuffGroup.Mode.NONE:
		BuffGroup.add_unit_to_buff_group(get_buff_group_number(), mode)


func _update_visual():
	match get_current_mode():
		BuffGroup.Mode.NONE: 
			_texture_rect.texture = _buff_group_none_icon
			tooltip_text = "Activate this buff group for the tower to automatically recieve/apply buffs to other towers in the same buff group."
		BuffGroup.Mode.OUTGOING: 
			_texture_rect.texture = _buff_group_outgoing_icon
			tooltip_text = "This tower will apply buffs other towers in group %s." % _buff_group_number
		BuffGroup.Mode.INCOMING: 
			_texture_rect.texture = _buff_group_incoming_icon
			tooltip_text = "This tower will receive buffs from other towers in group %s." % _buff_group_number
		BuffGroup.Mode.BOTH: 
			_texture_rect.texture = _buff_group_both_icon
			tooltip_text = "This tower will receive and apply buffs to other towers in group %s." % _buff_group_number


func get_current_mode() -> BuffGroup.Mode:
	var current_unit: Unit = SelectUnit.get_selected_unit()
	var current_unit_groups: Array = current_unit.get_buff_groups()
	var current_buff_group_mode: BuffGroup.Mode = BuffGroup.Mode.NONE
	
	for group in current_unit_groups:
		if BuffGroup.is_buff_group(group):
			var group_mode: BuffGroup.Mode = BuffGroup.get_buff_group_mode(group)
			var group_number: int = BuffGroup.get_buff_group_number(group)
			if group_number == _buff_group_number:
				if current_buff_group_mode != BuffGroup.Mode.NONE && current_buff_group_mode != group_mode:
					current_buff_group_mode = BuffGroup.Mode.BOTH
					break
				else:
					current_buff_group_mode = group_mode
	
	return current_buff_group_mode


func get_buff_group_number() -> int:
	return _buff_group_number
