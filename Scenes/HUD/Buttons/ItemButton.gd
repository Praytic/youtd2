class_name ItemButton 
extends UnitButton

signal right_clicked()


static var _item_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/ItemButton.tscn")

@export var _item_id: int = 0:
	set(value):
		_item_id = value
		if value != 0:
			_item = Item.make(value)
		else:
			_item = null
	get:
		return _item_id

var _item: Item = null:
	set(value):
		_item = value
		if self.is_node_ready():
			_set_rarity_icon(value)
			_set_unit_icon(value)
			_set_autocast(value)
	get:
		return _item

@onready var _cooldown_indicator: CooldownIndicator = $PanelContainer/UnitButton/CooldownIndicator

var _hide_cooldown_indicator: bool = false


static func make(item: Item) -> ItemButton:
	var item_button: ItemButton = _item_button_scene.instantiate()
	item_button._item = item

	return item_button


func _ready():
	if _item != null:
		_set_rarity_icon(_item)
		_set_unit_icon(_item)
		_set_autocast(_item)
	
	_unit_button.mouse_entered.connect(_on_mouse_entered)
	_unit_button.mouse_exited.connect(_on_mouse_exited)

	if _hide_cooldown_indicator:
		_cooldown_indicator.hide()


func hide_cooldown_indicator():
	_hide_cooldown_indicator = true


func _set_autocast(item: Item):
	var autocast: Autocast = item.get_autocast()

	if autocast != null:
		_cooldown_indicator.set_autocast(autocast)


func _set_rarity_icon(item: Item):
	_rarity = ItemProperties.get_rarity(item.get_id()) if item != null else ""


func _set_unit_icon(item: Item):
	if _unit_button == null:
		return
	
	_unit_button.icon = ItemProperties.get_icon(item.get_id() if item != null else 0)


func _on_mouse_entered():
	EventBus.item_button_mouse_entered.emit(_item)


func _on_mouse_exited():
	EventBus.item_button_mouse_exited.emit()


func _on_unit_button_right_clicked():
	var autocast: Autocast = _item.get_autocast()

	if autocast != null:
		autocast.do_cast_manually()
