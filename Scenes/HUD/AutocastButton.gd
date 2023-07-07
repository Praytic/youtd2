class_name AutocastButton 
extends Button


var _autocast: Autocast = null


func _ready():
	icon = load("res://Assets/icon.png")
	
	var cooldown_indicator_scene: PackedScene = load("res://Scenes/HUD/CooldownIndicator.tscn")
	var cooldown_indicator: CooldownIndicator = cooldown_indicator_scene.instantiate()
	cooldown_indicator.set_autocast(_autocast)
	add_child(cooldown_indicator)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_autocast(autocast: Autocast):
	_autocast = autocast


func _on_mouse_entered():
	EventBus.autocast_button_mouse_entered.emit(_autocast)


func _on_mouse_exited():
	EventBus.autocast_button_mouse_exited.emit()
