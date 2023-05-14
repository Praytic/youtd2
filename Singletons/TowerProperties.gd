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


func get_element(tower_id: int) -> Element.enm:
	var element_string: String = get_element_string(tower_id)
	var element: Element.enm = Element.from_string(element_string)

	return element


func get_element_string(tower_id: int) -> String:
	var element_string: String = TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.ELEMENT)

	return element_string


func get_csv_property(tower_id: int, csv_property: Tower.CsvProperty) -> String:
	var properties: Dictionary = Properties.get_tower_csv_properties_by_id(tower_id)
	var value: String = properties[csv_property]

	return value


func get_rarity(tower_id: int) -> String:
	return get_csv_property(tower_id, Tower.CsvProperty.RARITY)
	

func get_rarity_num(tower_id: int) -> int:
	var rarity_string: String = get_rarity(tower_id)
	var rarity: Rarity.enm = Rarity.convert_from_string(rarity_string)

	return rarity
	

func get_display_name(tower_id: int) -> String:
	return get_csv_property(tower_id, Tower.CsvProperty.NAME)


func get_tooltip_text(tower_id: int) -> String:
	var display_name: String = get_display_name(tower_id)
	var tooltip: String = "%s, %s" % [display_name, tower_id]

	return tooltip


func get_cost(tower_id: int) -> int:
	var cost: int = get_csv_property(tower_id, Tower.CsvProperty.COST) as int

	return cost


func get_description(tower_id: int) -> String:
	var description: String = get_csv_property(tower_id, Tower.CsvProperty.DESCRIPTION)

	return description


func get_author(tower_id: int) -> String:
	var author: String = get_csv_property(tower_id, Tower.CsvProperty.AUTHOR)

	return author


func get_damage_min(tower_id: int) -> int:
	var damage_min: int = get_csv_property(tower_id, Tower.CsvProperty.ATTACK_DAMAGE_MIN).to_int()

	return damage_min


func get_damage_max(tower_id: int) -> int:
	var damage_max: int = get_csv_property(tower_id, Tower.CsvProperty.ATTACK_DAMAGE_MAX).to_int()

	return damage_max


func get_base_damage(tower_id: int) -> int:
	var base_damage: int = floor((get_damage_min(tower_id) + get_damage_max(tower_id)) / 2.0)

	return base_damage


func get_base_cooldown(tower_id: int) -> float:
	var base_cooldown: float = get_csv_property(tower_id,Tower. CsvProperty.ATTACK_CD).to_float()

	return base_cooldown


func get_attack_type(tower_id: int) -> AttackType.enm:
	var attack_type_string: String = get_attack_type_string(tower_id)
	var attack_type: AttackType.enm = AttackType.from_string(attack_type_string)

	return attack_type


func get_attack_type_string(tower_id: int) -> String:
	var attack_type_string: String = get_csv_property(tower_id,Tower. CsvProperty.ATTACK_TYPE)

	return attack_type_string


func get_range(tower_id: int) -> float:
	var attack_range: float = get_csv_property(tower_id,Tower. CsvProperty.ATTACK_RANGE).to_float()

	return attack_range


func get_required_element_level(tower_id: int) -> int:
	return TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.REQUIRED_ELEMENT_LEVEL).to_int()


func get_required_wave_level(tower_id: int) -> int:
	return TowerProperties.get_csv_property(tower_id, Tower.CsvProperty.REQUIRED_WAVE_LEVEL).to_int()


func requirements_are_satisfied(tower_id: int) -> bool:
	var required_wave_level: int = TowerProperties.get_required_wave_level(tower_id)
	var required_element_level: int = TowerProperties.get_required_element_level(tower_id)
	var element: Element.enm = get_element(tower_id)
	var element_research_level: int = ElementLevel.get_current(element)
	var wave_level: int = WaveLevel.get_current()
	var out: bool = element_research_level >= required_element_level && wave_level >= required_wave_level

	return out
