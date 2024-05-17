class_name CreepMenu extends PanelContainer


# This has been replaced with UnitMenu. Delete this file soon.


enum Tabs {
	MAIN = 0,
	DETAILS = 1
}

@export var _tab_container: TabContainer
@export var _creep_button: UnitButton
@export var _title_label: Label
@export var _level_label: Label
@export var _info_label: RichTextLabel
@export var _details_tab: ScrollContainer
@export var _specials_scroll_container: ScrollContainer
@export var _special_list: VBoxContainer
@export var _buff_container: BuffContainer
@export var _details: CreepDetails

var _creep: Creep = null


#########################
###     Built-in      ###
#########################

func _process(_delta: float):
	if _creep == null:
		return

# 	NOTE: need to update info label every frame because it
# 	displays creep's armor stat which is not constant
	_info_label.text = RichTexts.get_creep_info(_creep)


#########################
###       Public      ###
#########################

func set_creep(creep: Creep):
	var prev_creep: Creep = _creep
	_creep = creep

	_details.set_creep(creep)

#	Reset all scroll positions when switching to a different unit
	Utils.reset_scroll_container(_specials_scroll_container)
	Utils.reset_scroll_container(_details_tab)

	if prev_creep != null:
		prev_creep.buff_list_changed.disconnect(_on_buff_list_changed)
	
#	NOTE: properties below are skipped if tower is null because they can't be loaded
	if creep == null:
		return
	
	creep.buff_list_changed.connect(_on_buff_list_changed.bind(creep))
	_on_buff_list_changed(creep)

	var creep_name: String = creep.get_display_name()
	_title_label.text = creep_name

	var tooltip_for_info_label: String = _get_tooltip_for_info_label()
	_info_label.set_tooltip_text(tooltip_for_info_label)
	
	var icon: Texture2D = UnitIcons.get_creep_icon(creep)
	_creep_button.set_icon(icon)

	var level_text: String = str(creep.get_spawn_level())
	_level_label.text = level_text

	var special_list: Array[int] = _creep.get_special_list()
	for special in _special_list.get_children():
		special.queue_free()

	for special in special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var special_description: String = WaveSpecialProperties.get_description(special)
		var special_icon: TextureRect = WaveSpecialProperties.get_special_icon(special)
		var creep_special: SpecialContainer = SpecialContainer.make(special_name, special_icon, special_description)
		
		_special_list.add_child(creep_special)


#########################
###      Private      ###
#########################

func _get_tooltip_for_info_label() -> String:
	var armor_type: ArmorType.enm = _creep.get_armor_type()
	var armor_type_name: String = ArmorType.convert_to_colored_string(armor_type)
	var text_for_damage_taken: String = ArmorType.get_rich_text_for_damage_taken(armor_type)

	var tooltip: String = ""
	tooltip += "%s armor takes this much damage from attacks:\n" % armor_type_name
	tooltip += text_for_damage_taken

	return tooltip


#########################
###     Callbacks     ###
#########################

func _on_buff_list_changed(unit: Unit):
	_buff_container.load_buffs_for_unit(unit)


func _on_close_button_pressed():
	hide()


func _on_details_button_pressed():
	var new_tab: int
	if _tab_container.current_tab == Tabs.MAIN:
		new_tab = Tabs.DETAILS
	else:
		new_tab = Tabs.MAIN
		
	_tab_container.set_current_tab(new_tab)
