extends VBoxContainer


# Displays next wave level how much time is left before it
# starts.


@export var _label: RichTextLabel
@export var _stats_label: RichTextLabel
@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")
@export var _timer_label: RichTextLabel


func _ready():
	WaveLevel.changed.connect(_update_all_labels)
	_wave_spawner.generated_all_waves.connect(_update_all_labels)

	_update_all_labels()
	_on_update_stats_timer_timeout()


func _process(_delta: float):
	_update_timer_label()


func _update_all_labels():
	_update_timer_label()
	_update_details_label()
	_update_tooltip()


func _update_timer_label():
	_timer_label.clear()

	var current_wave_level: int = WaveLevel.get_current()

	var text: String = ""

	if _wave_spawner.wave_is_in_progress():
		text += "Wave [color=GOLD]%d[/color]\n" % current_wave_level
	else:
		var next_wave_level: int = current_wave_level + 1
		var wave_time: int = floor(_wave_spawner.get_time_left())
		var wave_time_minutes: int = floor(wave_time / 60.0)
		var wave_time_seconds: int = wave_time - wave_time_minutes * 60

		text += "Wave [color=GOLD]%d[/color] in %02d:%02d\n" % [next_wave_level, wave_time_minutes, wave_time_seconds]

	_timer_label.append_text(text)


func _update_details_label():
	_label.clear()
	
	var text: String = ""

	var current_wave_level: int = WaveLevel.get_current()

	text += "[table=5]"

	text += "[cell][color=GOLD]Level[/color][/cell][cell][color=GOLD]Size[/color][/cell][cell][color=GOLD]Race[/color][/cell][cell][color=GOLD]Armor[/color][/cell][cell][color=GOLD]Special[/color][/cell]"

	var first_wave_index: int
	if current_wave_level > 0:
		first_wave_index = current_wave_level
	else:
		first_wave_index = 1

	for level in range(first_wave_index, first_wave_index + 5):
		var wave: Wave = _wave_spawner.get_wave(level)

		if wave == null:
			break

		var race: CreepCategory.enm = wave.get_race()
		var race_string: String = CreepCategory.convert_to_colored_string(race)

		if race == CreepCategory.enm.CHALLENGE:
			race_string = "---"

		var size_string: String = wave.get_creep_combination_string()

		var armor_type: ArmorType.enm = wave.get_armor_type()
		var armor_string: String = ArmorType.convert_to_colored_string(armor_type)

		var specials_string: String = _get_specials_string_short(wave)

		text += "[cell]%d[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [level, size_string, race_string, armor_string, specials_string]
	
	text += "[/table]"

	_label.append_text(text)


func _update_tooltip():
	var tooltip: String = ""

	tooltip += "Wave specials:\n"

	var current_wave_level: int = WaveLevel.get_current()
	
	var first_wave_index: int
	if current_wave_level > 0:
		first_wave_index = current_wave_level
	else:
		first_wave_index = 1

	for level in range(first_wave_index, first_wave_index + 5):
		var wave: Wave = _wave_spawner.get_wave(level)

		if wave == null:
			break

		var specials_string: String = _get_specials_string(wave)

		tooltip += "Wave %d: %s\n" % [level, specials_string]

	_label.set_tooltip_text(tooltip)


func _get_specials_string(wave: Wave) -> String:
	var special_list: Array[int] = wave.get_specials()

	if special_list.is_empty():
		return "None"

	var string_list: Array[String] = []

	for special in special_list:
		var string: String = WaveSpecial.get_special_name(special)
		string_list.append(string)

	var specials_string: String = ", ".join(string_list)

	return specials_string


func _get_specials_string_short(wave: Wave) -> String:
	var special_list: Array[int] = wave.get_specials()
	var string_list: Array[String] = []

	for special in special_list:
		var string: String = WaveSpecial.get_short_name(special)
		string_list.append(string)

	var specials_string: String = ", ".join(string_list)

	return specials_string


func _on_update_stats_timer_timeout():
# 	TODO: load score value here when scoring is implemented
	var score: int = 0
	var score_string: String = TowerInfo.int_format(score)

	var lives_string: String = PortalLives.get_lives_string()

	var total_damage: float = Globals.get_total_damage()
	var total_damage_string: String = TowerInfo.int_format(total_damage)

	var gold_farmed: float = GoldControl.get_gold_farmed()
	var gold_farmed_string: String = TowerInfo.int_format(floori(gold_farmed))

	var game_time: float = Utils.get_game_time()
	var game_time_hours: int = floori(game_time / 3600)
	var game_time_minutes: int = floori((game_time - game_time_hours * 3600) / 60)
	var game_time_seconds: int = floori(game_time - game_time_hours * 3600 - game_time_minutes * 60)
	var game_time_string: String
	if game_time_hours > 0:
		game_time_string = "%02d:%02d:%02d" % [game_time_hours, game_time_minutes, game_time_seconds]
	else:
		game_time_string = "%02d:%02d" % [game_time_minutes, game_time_seconds]

	var text: String = ""
	text += " \n"
	text += "[table=6]"
	text += "[cell][color=GOLD]Score:[/color][/cell][cell]%s[/cell][cell][color=GOLD]Lives:[/color][/cell][cell]%s[/cell][cell][color=GOLD]Game time:[/color][/cell][cell]%s[/cell]\n" % [score_string, lives_string, game_time_string]
	text += "[/table]\n"
	text += "[table=4]"
	text += "[cell][color=GOLD]Total damage:[/color][/cell][cell]%s[/cell][cell][color=GOLD]Gold Farmed:[/color][/cell][cell]%s[/cell]" % [total_damage_string, gold_farmed_string]
	text += "[/table]\n"

	_stats_label.clear()
	_stats_label.append_text(text)
