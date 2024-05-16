class_name SaveTowerRangesTool extends Node


# Generates range data for all towers and saves them to
# file.


const RESULT_FILENAME: String = "Data/tower_ranges.csv"


static func run(player: Player):
	print("Saving ranges...")
	
	var tower_id_list: Array = TowerProperties.get_tower_id_list()

#	NOTE: sort id's so that diffs for the csv file are not
#	messy
	tower_id_list.sort()

	var result_file: FileAccess = FileAccess.open(RESULT_FILENAME, FileAccess.WRITE)

	var header_line: Array[String] = []
	header_line.resize(TowerProperties.RangeColumn.COUNT)
	header_line[TowerProperties.RangeColumn.TOWER_ID] = "tower_id"
	header_line[TowerProperties.RangeColumn.NAME] = "name"
	header_line[TowerProperties.RangeColumn.RADIUS] = "radius"
	header_line[TowerProperties.RangeColumn.TARGETS_CREEPS] = "targets_creeps"
	header_line[TowerProperties.RangeColumn.AFFECTED_BY_BUILDER] = "affected_by_farseer"
	result_file.store_csv_line(header_line)

	for tower_id in tower_id_list:
		var tower: Tower = Tower.make(tower_id, player)
		player.add_child(tower)
		var range_data_list: Array[RangeData] = SaveTowerRangesTool._get_range_data_from_tower(tower)

		for range_data in range_data_list:
			var range_name: String = range_data.name

			var radius: float = range_data.radius
			var radius_string: String = str(floori(radius))

			var targets_creeps: bool = range_data.targets_creeps
			var targets_creeps_string: String
			if targets_creeps:
				targets_creeps_string = "TRUE"
			else:
				targets_creeps_string = "FALSE"

			var affected_by_builder: bool = range_data.affected_by_builder
			var affected_by_builder_string: String
			if affected_by_builder:
				affected_by_builder_string = "TRUE"
			else:
				affected_by_builder_string = "FALSE"

			var csv_line: Array[String] = []
			csv_line.resize(TowerProperties.RangeColumn.COUNT)
			csv_line[TowerProperties.RangeColumn.TOWER_ID] = str(tower_id)
			csv_line[TowerProperties.RangeColumn.NAME] = range_name
			csv_line[TowerProperties.RangeColumn.RADIUS] = radius_string
			csv_line[TowerProperties.RangeColumn.TARGETS_CREEPS] = targets_creeps_string
			csv_line[TowerProperties.RangeColumn.AFFECTED_BY_BUILDER] = affected_by_builder_string
			result_file.store_csv_line(csv_line)

		tower.queue_free()
	
	print("Done saving ranges. Saved result to:", result_file.get_path_absolute())


# Composes range data which contains name, radius and color
# for each range of tower. This includes attack range,
# auras, extra abilities. Used by tower details and when
# setting up range indicators.
# 
# Each range is assigned a unique color. Attack range is
# always same AQUA color, for consistency.
static func _get_range_data_from_tower(tower: Tower) -> Array[RangeData]:
	var list: Array[RangeData] = []

	var aura_list: Array[AuraType] = tower.get_aura_types()

	for aura in aura_list:
		var aura_range: RangeData = RangeData.new(aura.name, aura.get_range(tower.get_player()), aura.target_type)
#		NOTE: only auras are affected by builders
		aura_range.affected_by_builder = true
		list.append(aura_range)

	var ability_info_list: Array[AbilityInfo] = tower.get_ability_info_list()
	for ability_info in ability_info_list:
		var ability_has_range: bool = ability_info.radius != 0
		if !ability_has_range:
			continue

		var range_data: RangeData = RangeData.new(ability_info.name, ability_info.radius, ability_info.target_type)
		range_data.affected_by_builder = false
		list.append(range_data)

	var autocast_list: Array[Autocast] = tower.get_autocast_list()
	for autocast in autocast_list:
		var autocast_has_range: bool = autocast.cast_range != 0
		if !autocast_has_range:
			continue

		var range_data: RangeData = RangeData.new(autocast.title, autocast.cast_range, autocast.target_type)
		range_data.affected_by_builder = false
		list.append(range_data)

	return list
