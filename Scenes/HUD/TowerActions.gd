extends Control

# Container for active tower specials

@onready var _autocasts_container: VBoxContainer = $HBoxContainer/AutocastsOuterContainer/AutocastsContainer
@onready var _autocast_button_placeholder: Button = $HBoxContainer/AutocastsOuterContainer/AutocastsContainer/AutocastButtonPlaceholder


var _selling_for_real: bool = false


func _ready():
	_autocast_button_placeholder.queue_free()


func _update_autocasts(tower: Tower):
	for button in _autocasts_container.get_children():
		button.queue_free()

	var autocast_list: Array[Autocast] = tower.get_autocast_list()

	for autocast in autocast_list:
		var autocast_button: AutocastButton = Globals.autocast_button_scene.instantiate()
		autocast_button.set_autocast(autocast)
		_autocasts_container.add_child(autocast_button)
