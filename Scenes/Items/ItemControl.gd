extends Control


signal item_dropped(item_id)
signal item_used(item_id)


@onready var object_ysort: Node2D = get_node("%Map").get_node("ObjectYSort")
@onready var item_bar: GridContainer = get_node("%HUD/RightMenuBar/%ItemBar")


#########################
### Code starts here  ###
#########################

func _on_Creep_death(_event: Event, creep: Creep):
	# TODO: Implement proper item drop chance caclculation
	if Utils.rand_chance(0.5):
		var item_id_list: Array = Properties.get_item_id_list()
		var random_index: int = randi_range(0, item_id_list.size() - 1)
		var item_id: int = item_id_list[random_index]
		var item_properties: Dictionary = Properties.get_item_csv_properties()[item_id]
		var rarity: int = item_properties[Item.CsvProperty.RARITY].to_int()

		var rarity_name: String = ""

		match rarity:
			Constants.Rarity.COMMON: rarity_name = "CommonItem"
			Constants.Rarity.UNCOMMON: rarity_name = "UncommonItem"
			Constants.Rarity.RARE: rarity_name = "RareItem"
			Constants.Rarity.UNIQUE: rarity_name = "UniqueItem"
		
		var item_drop_scene_path: String = "res://Scenes/Items/%s.tscn" % [rarity_name]
		var item_drop_scene = load(item_drop_scene_path)
		var item_drop = item_drop_scene.instantiate()
		item_drop.set_id(item_id)
		item_drop.position = creep.position
		item_drop.selected.connect(_on_Item_selected.bind(item_drop))
		object_ysort.add_child(item_drop, true)
		item_dropped.emit(item_drop.get_id())

func _on_Item_selected(item_drop):
	item_bar.add_item_button(item_drop.get_id())
	item_drop.queue_free()
