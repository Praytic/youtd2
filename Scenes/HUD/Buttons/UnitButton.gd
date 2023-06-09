class_name UnitButton
extends Control


@onready var _unit_button: TextureButton = get_node("UnitButton")
@onready var _disabled_lock: TextureRect = $UnitButton/LockTexture
@onready var _counter: Container = $UnitButton/CounterContainer
@onready var _counter_label: Label = $UnitButton/CounterContainer/CounterLabel
@onready var _icon_rect: TextureRect = $UnitButton/IconContainer/Icon

const _fallback_icon: Texture2D = preload("res://Assets/icon.png")
const common_unit_button_texture = preload("res://Resources/Textures/UI/common_unit_button.tres")
const uncommon_unit_button_texture = preload("res://Resources/Textures/UI/uncommon_unit_button.tres")
const rare_unit_button_texture = preload("res://Resources/Textures/UI/rare_unit_button.tres")
const unique_unit_button_texture = preload("res://Resources/Textures/UI/unique_unit_button.tres")
const common_unit_button_hover_texture = preload("res://Resources/Textures/UI/common_unit_button_hover.tres")
const uncommon_unit_button_hover_texture = preload("res://Resources/Textures/UI/uncommon_unit_button_hover.tres")
const rare_unit_button_hover_texture = preload("res://Resources/Textures/UI/rare_unit_button_hover.tres")
const unique_unit_button_hover_texture = preload("res://Resources/Textures/UI/unique_unit_button_hover.tres")

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
			_unit_button.texture_normal = common_unit_button_texture
			_unit_button.texture_hover = common_unit_button_hover_texture
		Rarity.enm.UNCOMMON:
			_unit_button.texture_normal = uncommon_unit_button_texture
			_unit_button.texture_hover = uncommon_unit_button_hover_texture
		Rarity.enm.RARE:
			_unit_button.texture_normal = rare_unit_button_texture
			_unit_button.texture_hover = rare_unit_button_hover_texture
		Rarity.enm.UNIQUE:
			_unit_button.texture_normal = unique_unit_button_texture
			_unit_button.texture_hover = unique_unit_button_hover_texture


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
