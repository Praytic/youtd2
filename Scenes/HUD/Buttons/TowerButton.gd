class_name TowerButton 
extends UnitButton


static var _tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")

const ICON_SIZE_M = 128
const TIER_ICON_SIZE_M = 64

var _tower_id: int

const _tower_icons_m = preload("res://Assets/Towers/tower_icons_m.png")
const _tier_icons_m = preload("res://Assets/Towers/tier_icons_m.png")

@onready var _tier_icon: TextureRect = $UnitButton/TierContainer/TierIcon


static func make(tower_id: int) -> TowerButton:
	var tower_button: TowerButton = _tower_button_scene.instantiate()
	tower_button._tower_id = tower_id

	return tower_button


func _ready():
	_set_rarity_icon(_tower_id)
	_set_tier_icon(_tower_id)
	_set_unit_icon(_tower_id)

	_unit_button.mouse_entered.connect(_on_mouse_entered)
	_unit_button.mouse_exited.connect(_on_mouse_exited)
	_unit_button.pressed.connect(_on_pressed)

	WaveLevel.changed.connect(_on_wave_or_element_level_changed)
	ElementLevel.changed.connect(_on_wave_or_element_level_changed)
	_on_wave_or_element_level_changed()


func _on_wave_or_element_level_changed():
	var can_build: bool = TowerProperties.requirements_are_satisfied(_tower_id) || Config.ignore_requirements()
	set_disabled(!can_build)


func _set_rarity_icon(tower_id: int):
	var tower_rarity = TowerProperties.get_rarity(tower_id)
	set_rarity(tower_rarity)


func _set_tier_icon(tower_id: int):
	var tower_rarity = TowerProperties.get_rarity_num(tower_id)
	var tower_tier = TowerProperties.get_tier(tower_id) - 1
	var tier_icon = AtlasTexture.new()
	var icon_size: int
	
	tier_icon.set_atlas(_tier_icons_m)
	icon_size = TIER_ICON_SIZE_M
	
	tier_icon.set_region(Rect2(tower_tier * icon_size, tower_rarity * icon_size, icon_size, icon_size))
	_tier_icon.texture = tier_icon


func _set_unit_icon(tower_id: int):
	var icon_atlas_num: int = TowerProperties.get_icon_atlas_num(_tower_id)
	if icon_atlas_num == -1:
		push_error("Could not find an icon for tower id [%s]." % tower_id)
	
	var tower_icon = AtlasTexture.new()
	var icon_size: int
	
	tower_icon.set_atlas(_tower_icons_m)
	icon_size = ICON_SIZE_M
	
	var region: Rect2 = Rect2(TowerProperties.get_element(_tower_id) * icon_size, icon_atlas_num * icon_size, icon_size, icon_size)
	tower_icon.set_region(region)
	set_unit_icon(tower_icon)

func _on_mouse_entered():
	EventBus.tower_button_mouse_entered.emit(_tower_id)


func _on_mouse_exited():
	EventBus.tower_button_mouse_exited.emit()

func _on_pressed():
	BuildTower.start(_tower_id)
