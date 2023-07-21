class_name UnitButton
extends Control


@export var _unit_button: Button
@export var _disabled_lock: TextureRect
@export var _counter: Container
@export var _counter_label: Label
@export var _icon_rect: TextureRect

const _fallback_icon: Texture2D = preload("res://Assets/icon.png")

var _unit_icon: Texture2D = _fallback_icon : set = set_unit_icon
var _rarity: String: set = set_rarity
var _count: int : set = set_count
var _disabled: bool: set = set_disabled


func set_disabled(value):
	_disabled = value
	_unit_button.set_disabled(value)
	if value:
		_disabled_lock.show()
	else:
		_disabled_lock.hide()


func set_rarity(value):
	_rarity = value
	match Rarity.convert_from_string(value):
		Rarity.enm.COMMON:
			_unit_button.theme_type_variation = "CommonUnitButton"
		Rarity.enm.UNCOMMON:
			_unit_button.theme_type_variation = "UncommonUnitButton"
		Rarity.enm.RARE:
			_unit_button.theme_type_variation = "RareUnitButton"
		Rarity.enm.UNIQUE:
			_unit_button.theme_type_variation = "UniqueUnitButton"


func set_count(value: int):
	_count = value
	_counter_label.text = str(value)
	if _count > 1:
		_counter.show()
	else:
		_counter.hide()


func set_unit_icon(value):
	_icon_rect.texture = value
	_unit_icon = value


func get_button():
	return _unit_button
