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
		var tower: Tower = TowerManager.get_tower(tower_id, player)
		player.add_child(tower)
		var range_data_list: Array[Tower.RangeData] = SaveTowerRangesTool._get_range_data_from_tower(tower)

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
static func _get_range_data_from_tower(tower: Tower) -> Array[Tower.RangeData]:
	var list: Array[Tower.RangeData] = []

	var aura_list: Array[AuraType] = tower.get_aura_types()

	for i in aura_list.size():
		var aura: AuraType = aura_list[i]
		var aura_name: String = "Aura %d" % (i + 1)
		var aura_range: Tower.RangeData = Tower.RangeData.new(aura_name, aura.get_range(tower.get_player()), aura.target_type)
		aura_range.affected_by_builder = true
		list.append(aura_range)

	var ability_list: Array[Tower.RangeData] = tower.get_ability_ranges()

	for ability_range in ability_list:
		list.append(ability_range)

	return list
