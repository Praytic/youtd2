class_name WaveStatus extends VBoxContainer


# Displays next wave level how much time is left before it
# starts.


@export var _label: RichTextLabel
@export var _stats_label: RichTextLabel
@export var _start_game_button: Button
@export var _start_next_wave_button: Button
# NOTE: this timer is used only for display purposes. The timers which drive gameplay logic are located in GameScene.
@export var _display_timer: Timer
@export var _level_label: Label
@export var _game_start_time_container: HBoxContainer
@export var _game_start_time_label: Label
@export var _next_wave_time_container: HBoxContainer
@export var _next_wave_time_label: Label

var _armor_hint_map: Dictionary


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.game_over.connect(_on_game_over)

	_armor_hint_map = _generate_armor_hints()

#	NOTE: remove placeholder text, will be replaced by real
#	text
	show_wave_details([])


func _process(_delta: float):
	var time_string: String = _get_time_string()
	
	if _game_start_time_container.visible:
		_game_start_time_label.text = time_string
	elif _next_wave_time_container.visible:
		_next_wave_time_label.text = time_string


#########################
###      Public       ###
#########################

func show_game_start_time():
	_display_timer.start(Constants.TIME_BEFORE_FIRST_WAVE)
	_game_start_time_container.show()


func hide_game_start_time():
	_game_start_time_container.hide()


func show_next_wave_button():
	_start_game_button.hide()
	_start_next_wave_button.show()


func show_next_wave_time(time: float):
	_display_timer.start(time)
	_next_wave_time_container.show()


func hide_next_wave_time():
	_next_wave_time_container.hide()


func disable_next_wave_button():
	_start_next_wave_button.disabled = true


func show_wave_details(wave_list: Array[Wave]):
	_label.clear()
	
	var text: String = ""
	
	if !wave_list.is_empty():
		var current_wave: Wave = wave_list[0]
		var current_level = current_wave.get_level()
		_level_label.text = str(current_level)

	text += "[table=5]"

	text += "[cell][color=GOLD]Level[/color][/cell][cell][color=GOLD]Size[/color][/cell][cell][color=GOLD]Race[/color][/cell][cell][color=GOLD]Armor[/color][/cell][cell][color=GOLD]Special[/color][/cell]"

	for wave in wave_list:
		var level: int = wave.get_level()
		var race: CreepCategory.enm = wave.get_race()
		var race_string: String = CreepCategory.convert_to_colored_string(race)

		if race == CreepCategory.enm.CHALLENGE:
			race_string = "---"

		var size_string: String = wave.get_creep_combination_string()

		var armor_type: ArmorType.enm = wave.get_armor_type()
		var armor_hint: String = _armor_hint_map[armor_type]
		var armor_string: String = ArmorType.convert_to_colored_string(armor_type)

		var specials_description: String = _get_specials_description(wave)
		var specials_string: String = _get_specials_string_short(wave)

		text += "[cell]%d[/cell][cell]%s[/cell][cell]%s[/cell][cell][hint=%s]%s[/hint][/cell][cell][hint=%s]%s[/hint][/cell]" % [level, size_string, race_string, armor_hint, armor_string, specials_description, specials_string]
	
	text += "[/table]"

	_label.append_text(text)


#########################
###      Private      ###
#########################

func _get_specials_description(wave: Wave) -> String:
	var special_list: Array[int] = wave.get_specials()
	var string_list: Array[String] = []

	for special in special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var special_description: String = WaveSpecialProperties.get_description(special)
		var line: String = "%s - %s" % [special_name, special_description]
		string_list.append(line)

	var specials_string: String = "\n".join(string_list)

	return specials_string


func _get_specials_string_short(wave: Wave) -> String:
	var special_list: Array[int] = wave.get_specials()
	var string_list: Array[String] = []

	for special in special_list:
		var string: String = WaveSpecialProperties.get_short_name(special)
		string_list.append(string)

	var specials_string: String = ", ".join(string_list)

	return specials_string


func _generate_armor_hints() -> Dictionary:
	var out: Dictionary = {}

	for armor_type in ArmorType.get_list():
		var hint: String = ""
		hint += "Damage from:\n"
		hint += ArmorType.get_text_for_damage_taken(armor_type)

		out[armor_type] = hint

	return out


func _get_time_string() -> String:
	var time: int = floor(_display_timer.get_time_left())
	var time_minutes: int = floor(time / 60.0)
	var time_seconds: int = time - time_minutes * 60
	var time_string: String = "%02d:%02d" % [time_minutes, time_seconds]
	
	return time_string


#########################
###     Callbacks     ###
#########################

func _on_update_stats_timer_timeout():
# 	TODO: load score value here when scoring is implemented
	var score: int = 0
	var score_string: String = TowerInfo.int_format(score)

	var lives_string: String = PortalLives.get_lives_string()

	var total_damage: float = Globals.get_total_damage()
	var total_damage_string: String = TowerInfo.int_format(total_damage)

	var gold_farmed: float = GoldControl.get_gold_farmed()
	var gold_farmed_string: String = TowerInfo.int_format(floori(gold_farmed))

	var game_time: float = Utils.get_time()
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


func _on_game_over():
	_start_next_wave_button.disabled = true


func _on_start_next_wave_button_pressed():
	EventBus.player_requested_next_wave.emit()


func _on_start_game_button_pressed():
	EventBus.player_requested_start_game.emit()
