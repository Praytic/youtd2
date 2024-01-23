extends Node


enum enm {
	NONE,
	BLADEMASTER,
}


const _string_map: Dictionary = {
	Builder.enm.NONE: "none",
	Builder.enm.BLADEMASTER: "blademaster",
}

const _display_string_map: Dictionary = {
	Builder.enm.NONE: "none",
	Builder.enm.BLADEMASTER: "Blademaster",
}

var _tower_buff_map: Dictionary = {
	Builder.enm.NONE: null,
	Builder.enm.BLADEMASTER: _make_blademaster_tower_bt(),
}

var _creep_buff_map: Dictionary = {
	Builder.enm.NONE: null,
	Builder.enm.BLADEMASTER: null,
}

var _selected_builder: Builder.enm = Builder.enm.NONE


#########################
###     Built-in      ###
#########################

func _ready():
	for builder in _tower_buff_map.keys():
		var bt: BuffType = _tower_buff_map[builder]

		if bt == null:
			continue

		var builder_name: String = Builder.get_display_string(builder)
		bt.set_buff_tooltip("Buff from builder %s" % builder_name)

		bt.set_hidden()

	for builder in _creep_buff_map.keys():
		var bt: BuffType = _creep_buff_map[builder]

		if bt == null:
			continue

		var builder_name: String = Builder.get_display_string(builder)
		bt.set_buff_tooltip("Buff from builder %s" % builder_name)

		bt.set_hidden()


#########################
###       Public      ###
#########################

# This function should be called once at the start of the
# game. It will also apply any global effects of selected
# builder.
func set_selected_builder(builder: Builder.enm):
	_selected_builder = builder


func convert_to_string(type: Builder.enm) -> String:
	return _string_map[type]


func from_string(string: String) -> Builder.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Builder.enm.NONE


func get_display_string(type: Builder.enm) -> String:
	return _display_string_map[type]


func get_buff_for_unit(unit: Unit) -> BuffType:
	var buff: BuffType

	if unit is Tower:
		buff = _tower_buff_map.get(_selected_builder, null)
	elif unit is Creep:
		buff = _creep_buff_map.get(_selected_builder, null)
	else:
		buff = null

	return buff


#########################
###      Private      ###
#########################

func _make_blademaster_tower_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.08, 0.0)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.40, 0.0)
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	bt.set_buff_modifier(mod)

	return bt
