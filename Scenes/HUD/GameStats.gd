class_name GameStats extends VBoxContainer


@export var _settings_label: RichTextLabel

@export var _builder_label: Label

@export var _player_stats_label: RichTextLabel

@export var _most_damage_tower: Label
@export var _most_damage_value: Label
@export var _best_hit_tower: Label
@export var _best_hit_value: Label
@export var _most_exp_tower: Label
@export var _most_exp_value: Label
@export var _most_kills_tower: Label
@export var _most_kills_value: Label


#########################
###     Built-in      ###
#########################

func _process(_delta: float):
	var tower_list: Array[Tower] = Utils.get_tower_list()

	var most_damage_tower: Tower = _get_most_damage_tower(tower_list)
	var most_damage_tower_name: String = ""
	var most_damage_value: String = ""
	if most_damage_tower != null:
		most_damage_tower_name = most_damage_tower.get_display_name()
		var most_damage: float = most_damage_tower.get_damage()
		most_damage_value = TowerDetails.int_format(most_damage)

	var tower_with_best_hit: Tower = _get_best_hit_tower(tower_list)
	var best_hit_tower_name: String = ""
	var best_hit_value: String = ""
	if tower_with_best_hit != null:
		best_hit_tower_name = tower_with_best_hit.get_display_name()
		var best_hit: float = tower_with_best_hit.get_best_hit()
		best_hit_value = TowerDetails.int_format(best_hit)

	var most_exp_tower: Tower = _get_most_exp_tower(tower_list)
	var most_exp_tower_name: String = ""
	var most_exp_value: String = ""
	if most_exp_tower != null:
		most_exp_tower_name = most_exp_tower.get_display_name()
		var most_exp: float = most_exp_tower.get_exp()
		most_exp_value = TowerDetails.int_format(most_exp)

	var most_kills_tower: Tower = _get_most_kills_tower(tower_list)
	var most_kills_tower_name: String = ""
	var most_kills_value: String = ""
	if most_kills_tower != null:
		most_kills_tower_name = most_kills_tower.get_display_name()
		var most_kills: float = most_kills_tower.get_kills()
		most_kills_value = TowerDetails.int_format(most_kills)

	_most_damage_tower.text = most_damage_tower_name
	_most_damage_value.text = most_damage_value
	var most_damage_color: Color = _get_tower_color(most_damage_tower)
	_most_damage_tower.set("theme_override_colors/font_color", most_damage_color)

	_best_hit_tower.text = best_hit_tower_name
	_best_hit_value.text = best_hit_value
	var best_hit_color: Color = _get_tower_color(tower_with_best_hit)
	_best_hit_tower.set("theme_override_colors/font_color", best_hit_color)

	_most_exp_tower.text = most_exp_tower_name
	_most_exp_value.text = most_exp_value
	var most_exp_color: Color = _get_tower_color(most_exp_tower)
	_most_exp_tower.set("theme_override_colors/font_color", most_exp_color)

	_most_kills_tower.text = most_kills_tower_name
	_most_kills_value.text = most_kills_value
	var most_kills_color: Color = _get_tower_color(most_kills_tower)
	_most_kills_tower.set("theme_override_colors/font_color", most_kills_color)


#########################
###       Public      ###
#########################

func set_pregame_settings(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm):
	var game_length_string: String = _get_game_length_string(wave_count)

	var game_mode_string: String = GameMode.convert_to_display_string(game_mode).capitalize()

	var difficulty_string: String = Difficulty.convert_to_colored_string(difficulty)
	
	var settings_string: String = "[color=GOLD]%s[/color], [color=GOLD]%s[/color], %s\n" % [game_length_string, game_mode_string, difficulty_string]

	_settings_label.text = settings_string


func set_local_builder_name(builder_name: String):
	_builder_label.text = builder_name


func load_player_stats(player_list: Array[Player]):
	var text: String = ""

	text += "[table=6]"
	text += "[cell][color=GOLD]Name[/color][/cell][cell][color=GOLD]Score[/color][/cell][cell][color=GOLD]Lives[/color][/cell][cell][color=GOLD]Level[/color][/cell][cell][color=GOLD]Total damage[/color][/cell][cell][color=GOLD]Gold[/color][/cell]"

	player_list.sort_custom(
		func(a, b) -> bool:
			var id_a: int = a.get_id()
			var id_b: int = b.get_id()
			
			return id_a < id_b
	)

	for player in player_list:
		var player_name: String = player.get_player_name()

		var score: float = player.get_score()
		var score_string: String = TowerDetails.int_format(floori(score))

		var lives_string: String = player.get_team().get_lives_string()

		var wave_level: float = player.get_team().get_level()
		var wave_level_string: String = str(wave_level)

		var total_damage: float = player.get_total_damage()
		var total_damage_string: String = TowerDetails.int_format(total_damage)

		var gold: float = player.get_gold()
		var gold_string: String = Utils.format_float(gold, 2)
		
		text += "[cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [player_name, score_string, lives_string, wave_level_string, total_damage_string, gold_string]

	text += "[/table]"
	
	_player_stats_label.clear()
	_player_stats_label.append_text(text)


#########################
###      Private      ###
#########################

func _get_game_length_string(wave_count: int) -> String:
	var game_length_string: String

	match wave_count:
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


func _get_most_kills_tower(tower_list: Array[Tower]) -> Tower:
	var best_tower: Tower = _get_best_tower_by_criteria(tower_list,
		func(a: Tower, b: Tower) -> bool:
			return a.get_kills() > b.get_kills()
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


func _get_tower_color(tower: Tower) -> Color:
	if tower == null:
		return Color.WHITE

	var element: Element.enm = tower.get_element()
	var element_color: Color = Element.get_color(element)

	return element_color
