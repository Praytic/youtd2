class_name AutoModeIndicator extends Control


var _autocast: Autocast = null

@onready var _texture_rect: TextureRect = $TextureRect


static func add_to_texture_rect(autocast: Autocast, texture_rect: TextureRect):
	var auto_mode_indicator: AutoModeIndicator = _make_internal(autocast)
	texture_rect.add_child(auto_mode_indicator)

	var icon: Texture2D = texture_rect.texture
	var icon_size: Vector2 = icon.get_size()
	auto_mode_indicator._texture_rect.size = icon_size


static func add_to_button(autocast: Autocast, button: Button):
	var auto_mode_indicator: AutoModeIndicator = _make_internal(autocast)
	button.add_child(auto_mode_indicator)
	
	var icon: Texture2D = button.icon
	var icon_size: Vector2 = icon.get_size()
	auto_mode_indicator._texture_rect.size = icon_size

	var button_stylebox: StyleBox = button.get_theme_stylebox("normal", "Button")
	var icon_offset: Vector2 = button_stylebox.get_offset()

	auto_mode_indicator._texture_rect.position = icon_offset


static func _make_internal(autocast: Autocast) -> AutoModeIndicator:
	var auto_mode_indicator_scene: PackedScene = load("res://Scenes/HUD/AutoModeIndicator.tscn")
	var auto_mode_indicator: AutoModeIndicator = auto_mode_indicator_scene.instantiate()

	auto_mode_indicator._autocast = autocast

	return auto_mode_indicator


func _process(_delta: float):
	visible = _autocast._auto_mode
