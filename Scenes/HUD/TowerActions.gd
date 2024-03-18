extends Control

# Container for active (autocast) tower specials

@export var _autocasts_container: VBoxContainer


var _tower: Tower


#########################
###       Public      ###
#########################

func set_tower(tower: Tower):
	_tower = tower

	var autocast_list: Array[Autocast] = tower.get_autocast_list()

	for autocast in autocast_list:
		var autocast_button: AutocastButton = Preloads.autocast_button_scene.instantiate()
		autocast_button.set_autocast(autocast)
		_autocasts_container.add_child(autocast_button)
