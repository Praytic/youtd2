class_name UnitButton
extends Control


signal pressed()


@onready var _unit_button: Button = $PanelContainer/UnitButton
@onready var _disabled_lock: TextureRect = $PanelContainer/UnitButton/LockTexture
@onready var _counter: Container = $CounterContainer
@onready var _counter_label: Label = $CounterContainer/CounterLabel

@export var _count: int:
	set(value):
		_count = value
		if self.is_node_ready():
			_set_count(value)
	get:
		return _count

@export var _rarity: String:
	set(value):
		_rarity = value
		if self.is_node_ready():
			_set_rarity(value)
		
	get:
		return _rarity

@export var _disabled: bool:
	set(value):
		_disabled = value
		if self.is_node_ready():
			_set_disabled(value)
		
	get:
		return _disabled


func _ready():
	_set_count(_count)
	_set_rarity(_rarity)
	_set_disabled(_disabled)


func _set_disabled(value):
	if _unit_button == null or _disabled_lock == null:
		return
	
	_unit_button.set_disabled(value)
	if value:
		_disabled_lock.show()
	else:
		_disabled_lock.hide()


func _set_count(value):
	if _counter_label == null:
		return
	
	if value > 1:
		_counter_label.show()
	else:
		_counter_label.hide()
	_counter_label.text = str(value)


func _set_rarity(value):
	if _unit_button == null:
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


func _on_unit_button_pressed():
	pressed.emit()
