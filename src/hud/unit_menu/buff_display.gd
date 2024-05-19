class_name BuffDisplay extends PanelContainer


const FALLBACK_BUFF_ICON: String = "res://resources/icons/generic_icons/egg.tres"


@export var _texture_rect: TextureRect
@export var _stacks_label: Label
@export var _time_indicator: TimeIndicator

var _buff: Buff = null


#########################
###     Built-in      ###
#########################

func _process(_delta: float):
	if _buff == null:
		return

	if !is_instance_valid(_buff):
		return

#	NOTE: limit stacks text to 2 digits to stay in side icon
#	bounds
	var stacks: int = _buff.get_displayed_stacks()
	var stacks_text: String
	if stacks == 0:
		stacks_text = ""
	elif stacks <= 99:
		stacks_text = str(stacks)
	else:
		stacks_text = "99"

	_stacks_label.text = stacks_text
	
	var remaining_duration: float = _buff.get_remaining_duration()
	var overall_duration: float = _buff.get_original_duration()
	var elapsed_duration: float = overall_duration - remaining_duration
	var buff_is_permanent: bool = overall_duration < 0

	if !buff_is_permanent:
		_time_indicator.set_time_values(elapsed_duration, overall_duration)


#########################
###       Public      ###
#########################

func set_buff(buff: Buff):
	_buff = buff
	
	if buff == null:
		return

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
