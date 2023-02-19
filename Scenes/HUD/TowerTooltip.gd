extends Control


func _ready():
	pass # Replace with function body.


func get_tower_tooltip_text(tower_id: int) -> String:
	var tower: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)

	if !tower.empty():
		return "" \
			+ "Tower ID: %s\n" % tower[Tower.CsvProperty.ID] \
			+ "Element: %s\n" % tower[Tower.CsvProperty.ELEMENT] \
			+ "Attack type: %s\n" % tower[Tower.CsvProperty.ATTACK_TYPE] \
			+ "Cost: %s\n" % tower[Tower.CsvProperty.COST] \
			+ "Description: %s\n" % tower[Tower.CsvProperty.DESCRIPTION] \
			+ ""
	else:
		return "No data for tower id: %d" % tower_id


func set_tower_id(tower_id: int):
	var label_text: String = get_tower_tooltip_text(tower_id)
	$VBoxContainer/Label.text = label_text
