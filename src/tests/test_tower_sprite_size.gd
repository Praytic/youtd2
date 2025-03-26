class_name TestTowerSpriteSize extends Node


# Checks if any tower sprite has abnormal size relative to
# other towers of same cost.


const ABNORMAL_HEIGHT_THRESHOLD: float = 0.25
const COST_INTERVAL: int = 500


static var height_map: Dictionary = {}


static func run():
	height_map = generate_height_map()
	
	var cost_list: Array = range(0, 5000, COST_INTERVAL)

	for cost in cost_list:
		var average_height: float = get_average_height_for_towers_of_cost(cost)

		print(" \n \n--------------------------------")
		print("COST = %d, average height = %d" % [cost, average_height])
		
		var tower_list: Array = get_tower_list_for_cost(cost)

		for tower in tower_list:
			var tower_name: String = TowerProperties.get_display_name(tower)
			var tier: int = TowerProperties.get_tier(tower)
			var element: Element.enm = TowerProperties.get_element(tower)
			var element_string: String = Element.get_display_string(element)
			var height: float = height_map[tower]
			var diff_from_average: float = (height - average_height) / average_height
			var height_is_abnormally_short: bool = diff_from_average < 0 && abs(diff_from_average) > ABNORMAL_HEIGHT_THRESHOLD
			var height_is_abnormally_tall: bool = diff_from_average > 0 && abs(diff_from_average) > ABNORMAL_HEIGHT_THRESHOLD

			if height_is_abnormally_short:
				print("Tower sprite for %s (tier %d, %s) is too short. Height of tower = %d." % [tower_name, tier, element_string, height])
			elif height_is_abnormally_tall:
				print("Tower sprite for %s (tier %d, %s) is too tall. Height of tower = %d." % [tower_name, tier, element_string, height])


static func generate_height_map() -> Dictionary:
	var result: Dictionary = {}
	var tower_list: Array = TowerProperties.get_tower_id_list()

	for tower in tower_list:
		var tower_sprite: Sprite2D = TowerSprites.get_sprite(tower)
		var sprite_dimensions: Vector2 = Utils.get_sprite_dimensions(tower_sprite)
		var height: float = sprite_dimensions.y

		result[tower] = height
	
	return result


static func get_tower_list_for_cost(cost: int) -> Array:
	var all_towers: Array = TowerProperties.get_tower_id_list()
	
	var towers_for_cost: Array = all_towers.filter(
		func(tower_id: int) -> bool:
			var tower_cost: int = TowerProperties.get_cost(tower_id)
			var cost_match: bool = cost <= tower_cost && tower_cost < cost + COST_INTERVAL

			return cost_match
	)
	
	return towers_for_cost


static func get_average_height_for_towers_of_cost(cost: int) -> float:
	var tower_list: Array = get_tower_list_for_cost(cost)
	
	if tower_list.is_empty():
		return 0
	
	var height_sum: float = 0
		
	for tower in tower_list:
		var height: float = height_map[tower]
		height_sum += height
	
	var tower_count: int = tower_list.size()
	var average_height: float = height_sum / tower_count
	
	return average_height
