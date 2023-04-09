extends Node

# Convenience getters for tower properties. Actual values
# are stored in Properties, this class contains getters.

func get_tier(tower_id: int) -> int:
	return TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.TIER).to_int()


func get_icon_atlas_num(tower_id: int) -> int:
	var icon_atlas_num_string: String = TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.ICON_ATLAS_NUM)

	if !icon_atlas_num_string.is_empty():
		var icon_atlas_num: int = icon_atlas_num_string.to_int()

		return icon_atlas_num
	else:
		return -1


func get_element(tower_id: int) -> Tower.Element:
	var element_string: String = TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.ELEMENT)
	var element: Tower.Element = Tower.Element.get(element_string.to_upper())

	return element


func get_csv_property(tower_id: int, csv_property: Tower.CsvProperty) -> String:
	var properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var value: String = properties[csv_property]

	return value


func get_rarity(tower_id: int) -> String:
	return TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.RARITY)
	

func get_rarity_num(tower_id: int) -> int:
	var rarity: String = TowerProperties.get_rarity(tower_id).to_upper()
	return Constants.Rarity.get(rarity)


func get_display_name(tower_id: int) -> String:
	return get_csv_property(tower_id, Tower.CsvProperty.NAME)


func get_tooltip_text(tower_id: int) -> String:
	var display_name: String = get_display_name(tower_id)
	var tooltip: String = "%s, %s" % [display_name, tower_id]

	return tooltip
