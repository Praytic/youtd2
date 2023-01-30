extends OptionButton


func _ready():
	for tower_name in Properties.tower_id_map.keys():
		var tower_id: int = Properties.tower_id_map[tower_name]
		add_item(tower_name, tower_id)
