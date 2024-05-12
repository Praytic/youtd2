class_name RarityFilter extends VBoxContainer


signal filter_changed()


# NOTE: need to create a new ButtonGroup here so that
# RarityFilter can be used in multiple scenes without
# conflicts.
func _ready():
	var button_group: ButtonGroup = ButtonGroup.new()
	
	var button_node_list: Array[Node] = get_children()
	
	for button_node in button_node_list:
		var button: Button = button_node as Button
		
		if button == null:
			continue
		
		button.set_button_group(button_group)


#########################
###       Public      ###
#########################

func get_filter() -> Array[Rarity.enm]:
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
