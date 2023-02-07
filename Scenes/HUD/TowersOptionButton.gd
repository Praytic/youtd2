extends OptionButton


signal tower_selected(tower_id)

const HUD_SECTION: String = "hud"
const SELECTED_TOWER: String = "selected_tower"
const SETTINGS_PATH: String = "user://settings.cfg"


onready var tower_id_list: Array = Properties.get_tower_id_list()


func _ready():
	var tower_id_list = Properties.get_tower_id_list()
	_populate_TowerOptionButton_list(tower_id_list)
	
	var saved_tower_id: int = _get_saved_tower_id()
	
	if saved_tower_id != -1:
		var saved_tower_index: int = get_item_index(saved_tower_id)
		select(saved_tower_index)


func _get_saved_tower_id() -> int:
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var saved_tower_id = config.get_value(Constants.SettingsSection.HUD, Constants.SettingsKey.SELECTED_TOWER, 0)
	
	if saved_tower_id == null:
		return -1
	else:
		return saved_tower_id


func _on_TowerOptionButton_item_selected(_index):
	var config = ConfigFile.new()
	config.set_value(Constants.SettingsSection.HUD, Constants.SettingsKey.SELECTED_TOWER, get_item_id(_index))
	config.save(SETTINGS_PATH)
	emit_signal("tower_selected", get_item_id(_index))


func _on_RightMenuBar_element_changed(element):
	tower_id_list = Properties.get_tower_id_list_for_element(element)
	_populate_TowerOptionButton_list(tower_id_list)


func _populate_TowerOptionButton_list(tower_id_list):
	clear()
	var tower_name_list: Array = []
	var tower_name_to_id_map: Dictionary = {}

	for tower_id in tower_id_list:
		var tower_properties: Dictionary = Properties.get_csv_properties(tower_id)
		var tower_name: String = tower_properties[Tower.Property.NAME]
	
		tower_name_to_id_map[tower_name] = tower_id
		tower_name_list.append(tower_name)

	tower_name_list.sort()

	for tower_name in tower_name_list:
		var tower_id: int = tower_name_to_id_map[tower_name]
		add_item(tower_name, tower_id)
