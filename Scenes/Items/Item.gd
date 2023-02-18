extends KinematicBody2D


enum {
#	Properties below should be defined in the .csv file and
# 	the integer values must match the columns in csv file.
	FILENAME = 0,
	NAME = 1,
	ID = 2,
	FAMILY_ID = 3,
	AUTHOR = 4,
	RARITY = 5,
	COST = 6,
	DESCRIPTION = 7,
	REQUIRED_WAVE_LEVEL = 8,

	CSV_COLUMN_COUNT = 9,
}


export(int) var id


var _item_properties: Dictionary = {
	ID: 0,
	NAME: "unknown",
	FAMILY_ID: 0,
	AUTHOR: "unknown",
	RARITY: Constants.Rarity.COMMON,
	COST: 0,
	DESCRIPTION: "unknown",
	REQUIRED_WAVE_LEVEL: 0,
}


func _ready():
#	NOTE: Load properties from csv first, then load from
#	subclass script to add additional values or override csv
#	values
	var scene_path: String = filename
	var scene_file: String = scene_path.get_file()
	var scene_filename: String = scene_file.trim_suffix(".tscn")

	var csv_properties: Dictionary = Properties \
		.get_csv_properties_by_filter(Tower.TowerProperty.FILENAME, scene_filename)

	for property in csv_properties.keys():
		_tower_properties[property] = csv_properties[property]

# 	NOTE: tower properties may omit keys for convenience, so
# 	need to iterate over keys in properties to avoid
# 	triggering "invalid key" error
	
	# Most properties should be defined in the .csv file.
	var base_properties: Dictionary = _get_base_properties()

	for property in base_properties.keys():
		_tower_properties[property] = base_properties[property]

	_apply_properties_to_scene_children()

	$AreaOfEffect.hide()

	_attack_cooldown_timer.connect("timeout", self, "_on_AttackCooldownTimer_timeout")
	_attack_cooldown_timer.one_shot = true

	_targeting_area.connect("body_entered", self, "_on_TargetingArea_body_entered")
	_targeting_area.connect("body_exited", self, "_on_TargetingArea_body_exited")

	_attack_sound.set_stream(attack_sound)
	add_child(_attack_sound)
