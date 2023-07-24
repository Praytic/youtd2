class_name TowerButton 
extends UnitButton


static var _tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")


@onready var _tier_icon: TextureRect = $UnitButton/TierContainer/TierIcon
@onready var _tower_icons_m: Texture2D = preload("res://Assets/Towers/tower_icons_m.png")
@onready var _tier_icons_m: Texture2D = preload("res://Assets/Towers/tier_icons_m.png")


@export var _tower_id: int:
	set(value):
		_tower_id = value
		if self.is_node_ready():
			_set_rarity_icon(value)
			_set_tier_icon(value)
			_set_unit_icon(value)


static func make(tower_id: int) -> TowerButton:
	var tower_button: TowerButton = _tower_button_scene.instantiate()
	tower_button._tower_id = tower_id

	return tower_button


func _ready():
	if _tower_id != null:
		_set_rarity_icon(_tower_id)
		_set_tier_icon(_tower_id)
		_set_unit_icon(_tower_id)
	
	_unit_button.mouse_entered.connect(_on_mouse_entered)
	_unit_button.mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

	WaveLevel.changed.connect(_on_wave_or_element_level_changed)
	ElementLevel.changed.connect(_on_wave_or_element_level_changed)
	_on_wave_or_element_level_changed()


func _on_wave_or_element_level_changed():
	_disabled = !TowerProperties.requirements_are_satisfied(_tower_id) || \
		Config.ignore_requirements()


func _set_rarity_icon(tower_id: int):
	if tower_id <= 0:
		_rarity = ""
	else:
		_rarity = TowerProperties.get_rarity(tower_id)


func _set_tier_icon(tower_id: int):
	var tier_icon = AtlasTexture.new()
	# Handle unkown tower ID gracefully:
	# Don't show tier icon at all.
	if tower_id <= 0:
		tier_icon.set_region(Rect2())
	else:
		tier_icon.set_atlas(_tier_icons_m)
		var icon_size = _tier_icons_m.get_height() / Rarity.enm.size()
		var tower_rarity = TowerProperties.get_rarity_num(tower_id)
		var tower_tier = TowerProperties.get_tier(tower_id) - 1
		
		tier_icon.set_region(Rect2(tower_tier * icon_size, \
			tower_rarity * icon_size, icon_size, icon_size))
	_tier_icon.texture = tier_icon


func _set_unit_icon(tower_id: int):
	var unit_icon = AtlasTexture.new()
	# Handle unkown tower ID gracefully
	# Don't show tower icon at all.
	if tower_id <= 0:
		unit_icon.set_region(Rect2())
	else:
		unit_icon.set_atlas(_tower_icons_m)
		var icon_size = _tower_icons_m.get_width() / Element.enm.size()
		var icon_atlas_num: int = TowerProperties.get_icon_atlas_num(_tower_id)
		var tower_element = TowerProperties.get_element(_tower_id)
		
		unit_icon.set_region(Rect2(tower_element * icon_size, \
			icon_atlas_num * icon_size, icon_size, icon_size))
	_unit_button.icon = unit_icon

func _on_mouse_entered():
	EventBus.tower_button_mouse_entered.emit(_tower_id)


func _on_mouse_exited():
	EventBus.tower_button_mouse_exited.emit()


func _on_pressed():
	BuildTower.start(_tower_id)
