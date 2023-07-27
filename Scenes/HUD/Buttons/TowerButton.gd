class_name TowerButton
extends UnitButton


@onready var _disabled_lock: TextureRect = %LockTexture

var _tower_id: int: get = get_tower_id, set = set_tower_id

static func make(tower_id: int):
	var tower_button = Globals.tower_button_scene.instantiate()
	tower_button.set_tower_id(tower_id)
	return tower_button


func _ready():
	set_rarity(TowerProperties.get_rarity(_tower_id))
	set_icon(TowerProperties.get_icon_texture(_tower_id))
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

	WaveLevel.changed.connect(_on_wave_or_element_level_changed)
	ElementLevel.changed.connect(_on_wave_or_element_level_changed)
	_on_wave_or_element_level_changed()


func get_tower_id() -> int:
	return _tower_id


func set_tower_id(value: int):
	_tower_id = value


func _on_wave_or_element_level_changed():
	var can_build: bool = TowerProperties.requirements_are_satisfied(_tower_id) || Config.ignore_requirements()
	set_disabled(!can_build)
	if !can_build:
		_disabled_lock.show()
	else:
		_disabled_lock.hide()


func _on_mouse_entered():
	EventBus.tower_button_mouse_entered.emit(_tower_id)


func _on_mouse_exited():
	EventBus.tower_button_mouse_exited.emit()


func _on_pressed():
	BuildTower.start(_tower_id)
