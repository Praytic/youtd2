extends Control


# Displays info about selected unit. Display name, health
# and/or mana if they are above 0, currently active buffs.

var _buff_icon_list: Array = []
var _default_buff_icon: Texture2D = preload("res://Assets/Buffs/question_mark.png")

@onready var _label: RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
@onready var _buffs_container: Control = $PanelContainer/VBoxContainer/BuffsContainer

const do_not_update: bool = true


# NOTE: max of 10 buffs are displayed, if the unit has more
# than 10, the extra buffs won't be displayed.
func _ready():
	for i in range(0, 10):
		var buff_icon: TextureRect = TextureRect.new()
		_buff_icon_list.append(buff_icon)
		_buffs_container.add_child(buff_icon)
		buff_icon.texture = _default_buff_icon


func _process(_delta: float):
#	TODO: disabled the panel because selected unit info will be replaced by UnitMenu soon
	if do_not_update:
		return

	_label.clear()

	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if selected_unit == null:
		set_visible(false)

		return

	set_visible(true)

	var label_text: String = ""

	var display_name: String = selected_unit.get_display_name()
	var health: int = floor(selected_unit.get_health())
	var overall_health: int = floor(selected_unit.get_overall_health())
	var mana: int = floor(selected_unit.get_mana())
	var overall_mana: int = floor(selected_unit.get_overall_mana())

	label_text += "[b]%s[/b]\n" % display_name
	label_text += "Health: %d/%d\n" % [health, overall_health]
	label_text += "Mana: %d/%d\n" % [mana, overall_mana]

	if selected_unit is Creep:
		var creep: Creep = selected_unit as Creep
		var category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
		var category_string: String = CreepCategory.convert_to_colored_string(category)
		var armor_type: ArmorType.enm = creep.get_armor_type()
		var armor_type_string: String = ArmorType.convert_to_colored_string(armor_type)
		var armor: int = creep.get_overall_armor()
		var armor_string: String = str(armor)
		var damage_reduction: float = creep.get_current_armor_damage_reduction()
		var damage_reduction_string: String = Utils.format_percent(damage_reduction, 0)

		label_text += "Race: %s\n" % category_string
		label_text += "Armor Type: %s\n" % armor_type_string
		label_text += "Armor: %s\n" % armor_string
		label_text += "Damage Reduction: %s\n" % damage_reduction_string

	label_text += "Status:"

	_label.append_text(label_text)

	var friendly_buff_list: Array[Buff] = selected_unit._get_buff_list(true)
	var unfriendly_buff_list: Array[Buff] = selected_unit._get_buff_list(false)

	var buff_list: Array[Buff] = []
	buff_list.append_array(friendly_buff_list)
	buff_list.append_array(unfriendly_buff_list)

# 	NOTE: remove trigger buffs, they have empty type and
# 	shouldn't be displayed
	var trigger_buff_list: Array[Buff] = []

	for buff in buff_list:
		var is_trigger_buff: bool = buff.get_type().is_empty()
		if is_trigger_buff:
			trigger_buff_list.append(buff)

	for buff in trigger_buff_list:
		buff_list.erase(buff)

# 	NOTE: have to be careful here because if you call
# 	set_visible(false) and then set_visible(true) in the
# 	same frame, the tooltip stops working. Need to call
# 	set_visible() only once and when it's necessary.

	for i in range(0, _buff_icon_list.size()):
		var buff_icon: TextureRect = _buff_icon_list[i]

#		NOTE: hide buff icons that aren't used
		var icon_should_be_visible: bool = i < buff_list.size()
		buff_icon.set_visible(icon_should_be_visible)

		if i < buff_list.size():
			var buff: Buff = buff_list[i]
			var tooltip: String = buff.get_tooltip_text()
			buff_icon.set_tooltip_text(tooltip)

			var texture_path: String = buff.get_buff_icon()

			if !ResourceLoader.exists(texture_path):
				if buff.is_friendly():
					texture_path = "res://Assets/Buffs/buff_plus.png"
				else:
					texture_path = "res://Assets/Buffs/buff_minus.png"

			var texture: Texture2D = load(texture_path)
			buff_icon.texture = texture
