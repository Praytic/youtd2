@tool
class_name UnitButton
extends Control


@onready var _unit_button: Button = $PanelContainer/UnitButton
@onready var _disabled_lock: TextureRect = $PanelContainer/UnitButton/LockTexture
@onready var _counter: Container = $CounterContainer
@onready var _counter_label: Label = $CounterContainer/CounterLabel

@export var _count: int:
	set(value):
		_count = value
		print_verbose("Unit button [%s] count has changed: %s" % [self.name, value])
		_set_count(value)
	get:
		return _count
@export var _rarity: String:
	set(value):
		_rarity = value
		print_verbose("Unit button [%s] rarity has changed: %s" % [self.name, value])
		_set_rarity(value)
	get:
		return _rarity
@export var _disabled: bool:
	set(value):
		_disabled = value
		print_verbose("Unit button [%s] has been %s" % [self.name, "enabled" if value else "disabled"])
		_set_disabled(value)
	get:
		return _disabled


func _set_disabled(value):
	if _counter_label == null:
		print_verbose("Update failed. %s is not yet initialized." % _unit_button)
		return
	if _counter_label == null:
		print_verbose("Update failed. %s is not yet initialized." % _disabled_lock)
		return
	
	_unit_button.set_disabled(value)
	if value:
		_disabled_lock.show()
	else:
		_disabled_lock.hide()


func _set_rarity(value):
	if _unit_button == null:
		print_verbose("Update failed. %s is not yet initialized." % _unit_button)
		return
	
	var rarity
	if Engine.is_editor_hint():
		rarity = preload("res://Singletons/Enums/Rarity.gd").new()
	else:
		rarity = Rarity
	
	match rarity.convert_from_string(value):
		rarity.enm.COMMON:
			_unit_button.theme_type_variation = "CommonUnitButton"
		rarity.enm.UNCOMMON:
			_unit_button.theme_type_variation = "UncommonUnitButton"
		rarity.enm.RARE:
			_unit_button.theme_type_variation = "RareUnitButton"
		rarity.enm.UNIQUE:
			_unit_button.theme_type_variation = "UniqueUnitButton"
		_:
			_unit_button.theme_type_variation = ""
	
	print_verbose("Unit button theme is set to [%s]" % _unit_button.theme_type_variation)


func set_unit_icon(value):
	if _unit_button == null:
		print_verbose("Update failed. %s is not yet initialized." % _unit_button)
		return
	
	_unit_button.icon = value


func get_button():
	return _unit_button


func _set_count(value: int):
	if _counter_label == null:
		print_verbose("Update failed. %s is not yet initialized." % _counter_label)
		return
	
	if value > 1:
		_counter_label.show()
	else:
		_counter_label.hide()
	_counter_label.text = str(value)
