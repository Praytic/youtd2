extends Node


enum enm {
	NONE = 0,
	BLADEMASTER,
	QUEEN,
	ADVENTURER,
	IRON_MAIDEN,
	FARSEER,
}


const PROPERTIES_PATH: String = "res://Data/builder_properties.csv"

enum CsvProperty {
	ID,
	DISPLAY_NAME,
	SHORT_NAME,
	DESCRIPTION,
}

var _string_map: Dictionary = {}

var _tower_buff_map: Dictionary = {
	Builder.enm.NONE: null,
	Builder.enm.BLADEMASTER: _make_blademaster_tower_bt(),
	Builder.enm.QUEEN: _make_queen_tower_bt(),
	Builder.enm.ADVENTURER: _make_adventurer_tower_bt(),
	Builder.enm.IRON_MAIDEN: null,
	Builder.enm.FARSEER: _make_farseer_tower_bt(),
}

var _creep_buff_map: Dictionary = {
	Builder.enm.NONE: null,
	Builder.enm.BLADEMASTER: null,
	Builder.enm.QUEEN: _make_queen_creep_bt(),
	Builder.enm.ADVENTURER: null,
	Builder.enm.IRON_MAIDEN: null,
	Builder.enm.FARSEER: null,
}

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	Properties._load_csv_properties(PROPERTIES_PATH, _properties, Builder.CsvProperty.ID)

	for builder_id in _properties.keys():
		var builder: Builder.enm = builder_id as Builder.enm
		var short_name: String = get_short_name(builder)

		_string_map[builder] = short_name

	for builder in _tower_buff_map.keys():
		var bt: BuffType = _tower_buff_map[builder]

		if bt == null:
			continue

		var builder_name: String = Builder.get_display_name(builder)
		bt.set_buff_tooltip("Buff from builder %s" % builder_name)

		bt.set_hidden()

	for builder in _creep_buff_map.keys():
		var bt: BuffType = _creep_buff_map[builder]

		if bt == null:
			continue

		var builder_name: String = Builder.get_display_name(builder)
		bt.set_buff_tooltip("Buff from builder %s" % builder_name)

		bt.set_hidden()

	WaveLevel.changed.connect(_on_wave_level_changed)

	PregameSettings.finalized.connect(_on_pregame_settings_finalized)


#########################
###       Public      ###
#########################


func get_list() -> Array[Builder.enm]:
	return [
		Builder.enm.BLADEMASTER,
		Builder.enm.QUEEN,
		Builder.enm.ADVENTURER,
		Builder.enm.IRON_MAIDEN,
		Builder.enm.FARSEER,
	]


func from_string(string: String) -> Builder.enm:
	var key = _string_map.find_key(string)
	
	if key != null:
		return key
	else:
		push_error("Invalid string: \"%s\". Possible values: %s" % [string, _string_map.values()])

		return Builder.enm.NONE


func get_display_name(builder: int) -> String:
	var string: String = _get_property(builder, Builder.CsvProperty.DISPLAY_NAME)

	return string


func get_short_name(builder: int) -> String:
	var string: String = _get_property(builder, Builder.CsvProperty.SHORT_NAME)

	return string


func get_description(builder: int) -> String:
	var string: String = _get_property(builder, Builder.CsvProperty.DESCRIPTION)

	return string


func get_buff_for_unit(unit: Unit) -> BuffType:
	var buff: BuffType

	var selected_builder: Builder.enm = PregameSettings.get_builder()

	if unit is Tower:
		buff = _tower_buff_map.get(selected_builder, null)
	elif unit is Creep:
		buff = _creep_buff_map.get(selected_builder, null)
	else:
		buff = null

	return buff


func apply_bonus_to_range(original_range: float) -> float:
	var selected_builder: Builder.enm = PregameSettings.get_builder()

	if selected_builder != Builder.enm.FARSEER:
		return original_range

	var total_range: float = original_range + 75

	return total_range


#########################
###      Private      ###
#########################

func _get_property(builder: int, property: Builder.CsvProperty) -> String:
	if !_properties.has(builder):
		push_error("No properties for builder: ", builder)

		return ""

	var map: Dictionary = _properties[builder]
	var property_value: String = map[property]

	return property_value


func _make_blademaster_tower_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.08, 0.0)
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.40, 0.0)
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
	bt.set_buff_modifier(mod)

	return bt


func _make_queen_tower_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.30, 0.02)
	bt.set_buff_modifier(mod)

	return bt


func _make_queen_creep_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, false, self)
	bt.add_event_on_create(_queen_creep_bt_on_create)

	return bt


func _queen_creep_bt_on_create(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var creep: Creep = buffed_unit as Creep

	if creep == null:
		return

	var creep_size: CreepSize.enm = creep.get_size()

	if creep_size == CreepSize.enm.AIR:
		creep.modify_property(Modification.Type.MOD_MOVESPEED_ABSOLUTE, -60)


func _make_adventurer_tower_bt() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.15, 0.0)
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.20, 0.0)
	bt.set_buff_modifier(mod)

	return bt


func _make_farseer_tower_bt() -> BuffType:
	var bt: BuffType = MagicalSightBuff.new("", 700, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.10, 0.0)
	bt.set_buff_modifier(mod)

	return bt


func _do_iron_maiden_global_effect():
	PortalLives.modify_portal_lives(50)


#########################
###     Callbacks     ###
#########################

func _on_wave_level_changed():
	var selected_builder: Builder.enm = PregameSettings.get_builder()

	if selected_builder != Builder.enm.IRON_MAIDEN:
		return

	var portal_lives: float = PortalLives.get_current()

# 	NOTE: the tooltip says 50% and 10%, but that is in
# 	absolute terms without considering +50% to base lives
# 	from Iron Maiden. 50% means 50, not 0.5 * 150 = 75. This
# 	is how it works in original game.
	var regen_amount: float
	if portal_lives < 10:
		regen_amount = 1
	elif portal_lives < 50:
		regen_amount = 2
	else:
		regen_amount = 0

	PortalLives.modify_portal_lives(regen_amount)

# 	NOTE: original game doesn't have this message but I
# 	thought that it would be useful to add it.
	if regen_amount != 0:
		var regen_amount_string: String = Utils.format_percent(regen_amount / 100, 1)
		Messages.add_normal("You gain %s lives thanks to the Iron Maiden." % regen_amount_string)


# Apply global effects of selected builder
func _on_pregame_settings_finalized():
	var selected_builder: Builder.enm = PregameSettings.get_builder()

	match selected_builder:
		Builder.enm.IRON_MAIDEN: _do_iron_maiden_global_effect()

