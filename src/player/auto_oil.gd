class_name AutoOil


# Class for managing autooil assignments.


const OIL_TYPE_MAP: Dictionary = {
	"sharpness": [1001, 1002, 1003],
	"magic": [1004, 1005, 1006],
	"accuracy": [1007, 1008, 1009],
	"swiftness": [1010, 1011, 1012],
	"sorcery": [1013, 1014, 1015],
	"exuberance": [1016, 1017],
	"seeker": [1018, 1019],
	"lore": [1020, 1021],
	"tears": [1022],
	"aether": [1023],
	"wizard": [1024],
}

const OIL_TYPE_SYNONYMS: Dictionary = {
	"sharpness": ["damage", "dmg"],
	"magic": ["mana"],
	"accuracy": ["critical"],
	"swiftness": ["speed"],
	"sorcery": ["spell"],
	"exuberance": ["bounty"],
	"seeker": ["item"],
	"lore": ["experience"],
}

var _data: Dictionary = {}


#########################
###       Public      ###
#########################

# Returns a string describing current autooil assignments
func get_status() -> String:
	var text: String = ""
	
	var oil_type_list: Array = OIL_TYPE_MAP.keys()
	oil_type_list.sort()
	
	for oil_type in oil_type_list:
		var oil_type_is_assigned: bool = _data.has(oil_type)
		if !oil_type_is_assigned:
			continue
		
		var tower: Tower = _data[oil_type]
		if tower == null:
			continue
		
		var tower_name: String = tower.get_display_name()
		text += tr("AUTOOIL_STATUS").format({OIL_TYPE = oil_type, TOWER = tower_name})
		text += "\n"

	if text.is_empty():
		text += tr("AUTOOIL_STATUS_NONE")
	
	return text


# Assigns tower to be autooiled by given oil type
func set_tower(given_oil_type: String, tower: Tower):
	var oil_type: String = AutoOil.convert_short_type_to_full(given_oil_type)
	
	var oil_type_is_valid: bool = oil_type != ""
	if !oil_type_is_valid:
		return
	
	var prev_tower: Tower = _data.get(oil_type, null)
	if prev_tower != null:
		_disconnect_tower(tower)
	
	if tower != null && !tower.tree_exited.is_connected(_on_tower_tree_exited):
		tower.tree_exited.connect(_on_tower_tree_exited.bind(tower))
	
	_data[oil_type] = tower


# Returns tower which is assigned to be autooiled by given oil
func get_tower(oil_id: int) -> Tower:
	var matching_oil_type: String = ""
	
	for oil_type in OIL_TYPE_MAP.keys():
		var oil_list: Array = OIL_TYPE_MAP[oil_type]
		var oil_type_matches: bool = oil_list.has(oil_id)
		
		if oil_type_matches:
			matching_oil_type = oil_type
	
	if matching_oil_type != "":
		var tower: Tower = _data.get(matching_oil_type, null)
		
		return tower
	else:
		return null


# Transfers autooil settings from one tower to another. Used
# when tower is upgraded or transformed, otherwise autooil
# assignments would be lost!
func transfer_autooils(prev_tower: Tower, new_tower: Tower):
	for oil_type in _data.keys():
		var assigned_tower: Tower = _data[oil_type]
		
		if assigned_tower == prev_tower:
			_data[oil_type] = new_tower


func clear_all():
	for tower in _data.values():
		_disconnect_tower(tower)
	
	_data.clear()


func clear_for_tower(tower: Tower):
	for oil_type in _data.keys():
		var assigned_tower: Tower = _data[oil_type]
		
		if assigned_tower == tower:
			_data[oil_type] = null
	
	_disconnect_tower(tower)


#########################
###      Private      ###
#########################

func _disconnect_tower(tower: Tower):
	if !tower.tree_exited.is_connected(_on_tower_tree_exited):
		return
	
	tower.tree_exited.disconnect(_on_tower_tree_exited)


#########################
###     Callbacks     ###
#########################

func _on_tower_tree_exited(tower: Tower):
	clear_for_tower(tower)


#########################
###       Static      ###
#########################

static func get_oil_type_list() -> Array:
	var list: Array = OIL_TYPE_MAP.keys()
	list.sort()
	
	return list


static func get_oil_type_is_valid(given_oil_type: String) -> bool:
	var oil_type: String = AutoOil.convert_short_type_to_full(given_oil_type)
	var is_valid: bool = oil_type != ""
	
	return is_valid


# Returns empty string if conversion is not possible
static func convert_short_type_to_full(short_oil_type: String) -> String:
	if short_oil_type in OIL_TYPE_MAP:
		return short_oil_type
	
	var matching_type_count: int = 0
	var matching_oil_type: String = ""
	
	var oil_type_list: Array = OIL_TYPE_MAP.keys()
	
	for oil_type in oil_type_list:
		var matches: bool = oil_type.begins_with(short_oil_type)
		
		if not matches and oil_type in OIL_TYPE_SYNONYMS:
			for synonym in OIL_TYPE_SYNONYMS[oil_type]:
				if synonym.begins_with(short_oil_type):
					matches = true
					break
		
		if matches:
			matching_type_count += 1
			matching_oil_type = oil_type
	
	var more_than_one_match: bool = matching_type_count > 1
	
	if more_than_one_match:
		return ""
	else:
		return matching_oil_type
