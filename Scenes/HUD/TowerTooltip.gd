extends Control


func _ready():
	pass # Replace with function body.


func get_tower_tooltip_text(tower_id: int) -> String:
	var tower = TowerManager.get_tower_properties(tower_id)

	if !tower.empty():
		return "" \
			+ "Tower ID: %s\n" % tower[Tower.TowerProperty.ID] \
			+ "Element: %s\n" % tower[Tower.TowerProperty.ELEMENT] \
			+ "Attack type: %s\n" % tower[Tower.TowerProperty.ATTACK_TYPE] \
			+ "Cost: %s\n" % tower[Tower.TowerProperty.COST] \
			+ "Description: %s\n" % tower[Tower.TowerProperty.DESCRIPTION] \
			+ ""
	else:
		return "No data for tower id: %d" % tower_id


func set_tower_id(tower_id: int):
	var label_text: String = get_tower_tooltip_text(tower_id)
	$VBoxContainer/Label.text = label_text
