@tool
class_name UnitButton
extends Control


@export var _unit_button: Button
@export var _disabled_lock: TextureRect
@export var _counter: Container
@export var _counter_label: Label
@export var _count: int:
	set(value):
		_count = value
		print_verbose("Unit button [%s] count has changed: %s" % [self.name, value])
		_update_counter(value)
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


const _fallback_icon: Texture2D = preload("res://Assets/icon.png")


func _set_disabled(value):
	_unit_button.set_disabled(value)
	if value:
		_disabled_lock.show()
	else:
		_disabled_lock.hide()


func _set_rarity(value):
	var Rarity = Rarity
	if Engine.is_editor_hint():
		Rarity = preload("res://Singletons/Enums/Rarity.gd").new()
	match Rarity.convert_from_string(value):
		Rarity.enm.COMMON:
			_unit_button.theme_type_variation = "CommonUnitButton"
		Rarity.enm.UNCOMMON:
			_unit_button.theme_type_variation = "UncommonUnitButton"
		Rarity.enm.RARE:
			_unit_button.theme_type_variation = "RareUnitButton"
		Rarity.enm.UNIQUE:
			_unit_button.theme_type_variation = "UniqueUnitButton"
		_:
			_unit_button.theme_type_variation = ""
	print_verbose("Unit button theme is set to [%s]" % _unit_button.theme_type_variation)

func set_count(value: int):
	_counter_label.text = str(value)
	if _count > 1:
		_counter.show()
	else:
		_counter.hide()


func set_unit_icon(value):
	_unit_button.icon = value


func get_button():
	return _unit_button


func _update_counter(value: int):
	if value > 0:
		_counter_label.show()
	else:
		_counter_label.hide()
	_counter_label.text = str(value)
