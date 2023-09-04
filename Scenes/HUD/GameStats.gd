class_name GameStats extends VBoxContainer


@export var _label: RichTextLabel


func _process(_delta: float):
	var text: String = _get_game_stats_text()
	_label.clear()
	_label.append_text(text)


func _get_game_stats_text() -> String:
	var tower_list: Array[Tower] = _get_tower_list()

	var game_length_string: String = _get_game_length_string()

	var game_mode: GameMode.enm = Globals.game_mode
	var game_mode_string: String = GameMode.convert_to_display_string(game_mode).capitalize()

	var difficulty: Difficulty.enm = Globals.difficulty
	var difficulty_string: String = Difficulty.convert_to_colored_string(difficulty)

# 	TODO: load score value here when scoring is implemented
	var score: int = 0
	var score_string: String = TowerInfo.int_format(score)

	var lives_string: String = PortalLives.get_lives_string()

	var wave_level: float = WaveLevel.get_current()
	var wave_level_string: String = str(wave_level)

	var total_damage: float = Globals.get_total_damage()
	var total_damage_string: String = TowerInfo.int_format(total_damage)

	var gold: float = GoldControl.get_gold()
	var gold_string: String = Utils.format_float(gold, 2)

	var most_damage_tower: Tower = _get_most_damage_tower(tower_list)
	var most_damage_tower_name: String = ""
	var most_damage_value: String = ""
	if most_damage_tower != null:
		most_damage_tower_name = _get_tower_name_colored_by_element(most_damage_tower)
		var most_damage: float = most_damage_tower.get_damage()
		most_damage_value = TowerInfo.int_format(most_damage)

	var tower_with_best_hit: Tower = _get_best_hit_tower(tower_list)
	var best_hit_tower_name: String = ""
	var best_hit_value: String = ""
	if tower_with_best_hit != null:
		best_hit_tower_name = _get_tower_name_colored_by_element(tower_with_best_hit)
		var best_hit: float = tower_with_best_hit.get_best_hit()
		best_hit_value = TowerInfo.int_format(best_hit)

	var most_exp_tower: Tower = _get_most_exp_tower(tower_list)
	var most_exp_tower_name: String = ""
	var most_exp_value: String = ""
	if most_exp_tower != null:
		most_exp_tower_name = _get_tower_name_colored_by_element(most_exp_tower)
		var most_exp: float = most_exp_tower.get_exp()
		most_exp_value = TowerInfo.int_format(most_exp)

	var text: String = ""

	text += "[color=GOLD]%s[/color], [color=GOLD]%s[/color], %s\n" % [game_length_string, game_mode_string, difficulty_string]
	text += " \n"
	text += "[table=5]"
	text += "[cell][color=GOLD]Score[/color][/cell][cell][color=GOLD]Lives[/color][/cell][cell][color=GOLD]Level[/color][/cell][cell][color=GOLD]Total damage[/color][/cell][cell][color=GOLD]Gold[/color][/cell]"
	text += "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [score_string, lives_string, wave_level_string, total_damage_string, gold_string]
	text += "[/table]"
	text += " \n"
	text += " \n"
	text += "[color=GOLD]Best Towers:[/color]\n"
	text += "[table=3]"
	text += "[cell]Most Damage:[/cell][cell]%s[/cell][cell]%s[/cell]" % [most_damage_tower_name, most_damage_value]
	text += "[cell]Best Hit:[/cell][cell]%s[/cell][cell]%s[/cell]" % [best_hit_tower_name, best_hit_value]
	text += "[cell]Most Exp:[/cell][cell]%s[/cell][cell]%s[/cell]" % [most_exp_tower_name, most_exp_value]
	text += "[/table]"

	return text


func _get_game_length_string() -> String:
	var game_length: int = Globals.wave_count
	var game_length_string: String

	match game_length:
		Constants.WAVE_COUNT_TRIAL: game_length_string = "Trial"
		Constants.WAVE_COUNT_FULL: game_length_string = "Full"
		Constants.WAVE_COUNT_NEVERENDING: game_length_string = "Neverending"
		_: "Unknown"

	return game_length_string


func _get_most_damage_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_damage() > b.get_damage()
			)

	return best_tower


func _get_best_hit_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_best_hit() > b.get_best_hit()
			)

	return best_tower


func _get_most_exp_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_exp() > b.get_exp()
			)

	return best_tower


func _get_best_tower_by_criteria(tower_list: Array[Tower], criteria_callable: Callable) -> Tower:
	var best_tower: Tower = null

	for tower in tower_list:
		if best_tower == null:
			best_tower = tower
			continue

		var this_tower_is_better: bool = criteria_callable.call(tower, best_tower)

		if this_tower_is_better:
			best_tower = tower

	return best_tower


func _get_tower_list() -> Array[Tower]:
	var tower_node_list: Array[Node] = get_tree().get_nodes_in_group("towers")
	var tower_list: Array[Tower] = []

	for tower_node in tower_node_list:
		var tower: Tower = tower_node as Tower
		tower_list.append(tower)

	return tower_list


func _get_tower_name_colored_by_element(tower: Tower) -> String:
	var element: Element.enm = tower.get_element()
	var tower_name: String = tower.get_display_name()
	var element_color: Color = Element.get_color(element)
	var tower_name_colored: String = Utils.get_colored_string(tower_name, element_color)

	return tower_name_colored
