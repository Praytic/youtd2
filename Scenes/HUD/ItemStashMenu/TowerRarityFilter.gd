class_name TowerRarityFilter extends VBoxContainer


signal filter_changed()


#########################
###       Public      ###
#########################

func get_rarity_list() -> Array[Rarity.enm]:
	var buttons = get_children()
	
	for button in buttons:
		if button.button_pressed:
			var rarity_list: Array[Rarity.enm] = button.rarity_list
			
			return rarity_list
	
	var fallback_rarity_list: Array[Rarity.enm] = [Rarity.enm.COMMON]
	
	return fallback_rarity_list


#########################
###     Callbacks     ###
#########################

func _on_filter_button_pressed(_value):
	filter_changed.emit()
