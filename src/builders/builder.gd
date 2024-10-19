class_name Builder extends Node


# Base class for builder instances. Defines functions which
# should be overriden in subclasses. Some of these functions
# will be called once after builder is selected. Other
# functions will be called multiple times during gameplay,
# as callbacks.


var _id: int
var _tower_buff: BuffType
var _creep_buff: BuffType
var _tower_modifier: Modifier
var _creep_modifier: Modifier

var _allow_adjacent_towers: bool = true
var _tower_lvl_bonus: int = 0
var _range_bonus: float = 0.0
var _item_slots_bonus: int = 0
var _adds_extra_recipes: bool = false
var _tower_exp_bonus: float = 0.0


#########################
###     Built-in      ###
#########################

func _ready():
	_tower_buff = _get_tower_buff()
	_creep_buff = _get_creep_buff()
	_tower_modifier = _get_tower_modifier()
	_creep_modifier = _get_creep_modifier()
	
	var builder_name: String = BuilderProperties.get_display_name(_id)

	if _tower_buff != null:
		_tower_buff.set_buff_tooltip("DEBUG Buff from builder %s" % builder_name)
		_tower_buff.set_hidden()
	
	if _creep_buff != null:
		_creep_buff.set_buff_tooltip("DEBUG Buff from builder %s" % builder_name)
		_creep_buff.set_hidden()


#########################
###       Public      ###
#########################

func get_id() -> int:
	return _id


func get_display_name() -> String:
	var display_name: String = BuilderProperties.get_display_name(_id)

	return display_name


func get_allow_adjacent_towers() -> bool:
	return _allow_adjacent_towers


func get_tower_lvl_bonus() -> int:
	return _tower_lvl_bonus


func get_range_bonus() -> float:
	return _range_bonus


func get_item_slots_bonus() -> int:
	return _item_slots_bonus


func get_adds_extra_recipes() -> bool:
	return _adds_extra_recipes

func get_tower_exp_bonus() -> float:
	return _tower_exp_bonus

func apply_effects(unit: Unit):
	var buff: BuffType
	var modifier: Modifier

	if unit is Tower:
		buff = _tower_buff
		modifier = _tower_modifier
	elif unit is Creep:
		buff = _creep_buff
		modifier = _creep_modifier
	else:
		buff = null
		modifier = null

	if buff != null:
		buff.apply_to_unit_permanent(unit, unit, unit.get_level())

	if modifier != null:
		unit.add_modifier(modifier)


#########################
###  Override methods ###
#########################

func apply_to_player(_player: Player):
	pass


func apply_wave_finished_effect(_player: Player):
	pass


func _get_tower_buff() -> BuffType:
	return null


func _get_creep_buff() -> BuffType:
	return null


# NOTE: if your builder needs to modify unit stats, use
# modifiers instead of buffs. This way, modifiers will be
# affected by unit leveling up. Modifiers applied via buffs
# will NOT be affected by level ups.
func _get_tower_modifier() -> Modifier:
	return null


func _get_creep_modifier() -> Modifier:
	return null


#########################
###       Static      ###
#########################


static func create_instance(id: int) -> Builder:
	var script_path: String = BuilderProperties.get_script_path(id)
	var builder_script = load(script_path)
	var builder_instance: Builder = builder_script.new()
	builder_instance._id = id

	return builder_instance
