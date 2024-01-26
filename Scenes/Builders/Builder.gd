class_name Builder extends Node


# Base class for builder instances. Defines functions which
# should be overriden in subclasses. Some of these functions
# will be called once after builder is selected. Other
# functions will be called multiple times during gameplay,
# as callbacks.


var _id: int
var _tower_buff: BuffType
var _creep_buff: BuffType


#########################
###     Built-in      ###
#########################

func _ready():
	_tower_buff = _get_tower_buff()
	_creep_buff = _get_creep_buff()
	
	var builder_name: String = BuilderProperties.get_display_name(_id)

	if _tower_buff != null:
		_tower_buff.set_buff_tooltip("Buff from builder %s" % builder_name)
		_tower_buff.set_hidden()
	
	if _creep_buff != null:
		_creep_buff.set_buff_tooltip("Buff from builder %s" % builder_name)
		_creep_buff.set_hidden()


#########################
###       Public      ###
#########################

func apply_buff(unit: Unit):
	var buff: BuffType

	if unit is Tower:
		buff = _tower_buff
	elif unit is Creep:
		buff = _creep_buff
	else:
		buff = null

	if buff != null:
		buff.apply(unit, unit, unit.get_level())


#########################
###  Override methods ###
#########################

func _get_tower_buff() -> BuffType:
	return null


func _get_creep_buff() -> BuffType:
	return null


#########################
###       Static      ###
#########################


static func create_instance(id: int) -> Builder:
	var script_name: String = BuilderProperties.get_script_name(id)
	var script_path: String = "res://Scenes/Builders/Instances/%s.gd" % script_name
	var builder_script = load(script_path)
	var builder_instance: Builder = builder_script.new()
	builder_instance._id = id

	return builder_instance
