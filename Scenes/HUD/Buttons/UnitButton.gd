class_name UnitButton 
extends TextureButton


@onready var _fallback_icon: Texture2D = preload("res://Assets/icon.png")
@onready var _disabled_lock: TextureRect = $LockTexture
@onready var _counter: Container = $CounterContainer
@onready var _counter_label: Label = $CounterContainer/CounterLabel
@onready var _icon_rect: TextureRect = $IconContainer/Icon

@onready var common_unit_button_texture = preload("res://Resources/Textures/UI/common_unit_button.tres")
@onready var uncommon_unit_button_texture = preload("res://Resources/Textures/UI/uncommon_unit_button.tres")
@onready var rare_unit_button_texture = preload("res://Resources/Textures/UI/rare_unit_button.tres")
@onready var unique_unit_button_texture = preload("res://Resources/Textures/UI/unique_unit_button.tres")
@onready var common_unit_button_hover_texture = preload("res://Resources/Textures/UI/common_unit_button_hover.tres")
@onready var uncommon_unit_button_hover_texture = preload("res://Resources/Textures/UI/uncommon_unit_button_hover.tres")
@onready var rare_unit_button_hover_texture = preload("res://Resources/Textures/UI/rare_unit_button_hover.tres")
@onready var unique_unit_button_hover_texture = preload("res://Resources/Textures/UI/unique_unit_button_hover.tres")

@export var unit_icon: Texture2D : set = set_unit_icon
@export var rarity: String : set = set_rarity
@export var count: int: set = set_count


func _ready():
	if unit_icon == null:
		_icon_rect.texture = _fallback_icon
	else:
		_icon_rect.texture = unit_icon


func _process(delta):
	if is_disabled():
		_disabled_lock.show()
	else:
		_disabled_lock.hide()
	
	if count > 0:
		_counter.show()
	else:
		_counter.hide()


func set_rarity(value):
	rarity = value
	match Rarity.convert_from_string(value):
		Rarity.enm.COMMON:
			texture_normal = common_unit_button_texture
			texture_hover = common_unit_button_hover_texture
		Rarity.enm.UNCOMMON:
			texture_normal = uncommon_unit_button_texture
			texture_hover = uncommon_unit_button_hover_texture
		Rarity.enm.RARE:
			texture_normal = rare_unit_button_texture
			texture_hover = rare_unit_button_hover_texture
		Rarity.enm.UNIQUE:
			texture_normal = unique_unit_button_texture
			texture_hover = unique_unit_button_hover_texture


func set_count(value):
	count = value
	_counter_label.text = value


func set_unit_icon(value):
	_icon_rect.texture = value
	unit_icon = value

