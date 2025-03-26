class_name WaveStatus extends VBoxContainer


# Displays next wave level how much time is left before it
# starts.


@export var _label: RichTextLabel
@export var _start_game_button: Button
@export var _start_next_wave_button: Button
@export var _level_label: Label
@export var _game_start_time_container: HBoxContainer
@export var _game_start_time_label: Label
@export var _next_wave_time_container: HBoxContainer
@export var _next_wave_time_label: Label
@export var _score_label: Label
@export var _game_time_label: Label
@export var _total_damage_label: Label
@export var _gold_farmed_label: Label

var _armor_hint_map: Dictionary
var _game_start_timer: ManualTimer = null


#########################
###     Built-in      ###
#########################

func _ready():
	_armor_hint_map = _generate_armor_hints()

#	NOTE: remove placeholder text, will be replaced by real
#	text
	_show_wave_list([])


func _process(_delta: float):
	var local_player: Player = PlayerManager.get_local_player()

	if local_player == null:
		return

	var local_team: Team = local_player.get_team()
	var next_wave_timer: ManualTimer = local_team.get_next_wave_timer()
	var next_wave_time_string: String = _get_time_string(next_wave_timer)
	_next_wave_time_container.visible = !next_wave_timer.is_stopped()
	_next_wave_time_label.text = next_wave_time_string

	var game_start_time_string: String = _get_time_string(_game_start_timer)
	_game_start_time_container.visible = !_game_start_timer.is_stopped()
	_game_start_time_label.text = game_start_time_string

	var gold_farmed: float = local_player.get_gold_farmed()
	var gold_farmed_string: String = TowerDetails.int_format(floori(gold_farmed))
	_gold_farmed_label.text = gold_farmed_string

	var level: int = local_player.get_team().get_level()
	_level_label.text = str(level)
	
	var total_damage: float = local_player.get_total_damage()
	var total_damage_string: String = TowerDetails.int_format(floori(total_damage))
	_total_damage_label.text = total_damage_string
	
	var score: float = local_player.get_score()
	var score_string: String = TowerDetails.int_format(floori(score))
	_score_label.text = score_string
	
	var game_time: float = Utils.get_time()
	var game_time_string: String = Utils.convert_time_to_string(game_time)
	_game_time_label.text = game_time_string


#########################
###      Public       ###
#########################

func connect_to_local_player(local_player: Player):
	var local_team: Team = local_player.get_team()
	local_team.level_changed.connect(_on_wave_level_changed)
	local_team.started_first_wave.connect(_on_started_first_wave)
	_on_wave_level_changed()

	local_player.generated_waves.connect(_on_local_player_generated_waves)


func set_game_start_timer(timer: ManualTimer):
	_game_start_timer = timer


#########################
###      Private      ###
#########################

func _update_wave_details():
	var local_player: Player = PlayerManager.get_local_player()
	var wave_list: Array[Wave] = local_player.get_next_5_waves()
	_show_wave_list(wave_list)


func _show_wave_list(wave_list: Array[Wave]):
	_label.clear()
	
	var text: String = ""

	text += "[table=5]"

	text += "[cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell][cell][color=GOLD]%s[/color][/cell]" % [tr("WAVE_STATUS_COLUMN_LEVEL"), tr("WAVE_STATUS_COLUMN_SIZE"), tr("WAVE_STATUS_COLUMN_RACE"), tr("WAVE_STATUS_COLUMN_ARMOR"), tr("WAVE_STATUS_COLUMN_SPECIAL")]

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


# NOTE: not using rich text versions of these texts because
# it doesn't work with RichTextLabel's "hint" system
func _generate_armor_hints() -> Dictionary:
	var out: Dictionary = {}

	for armor_type in ArmorType.get_list():
		var hint: String = ""
		hint += "%s\n" % tr("WAVE_STATUS_DAMAGE_FROM")
		hint += ArmorType.get_text_for_damage_taken(armor_type)

		out[armor_type] = hint

	return out


func _get_time_string(timer: ManualTimer) -> String:
	if timer.is_paused():
		return tr("WAVE_STATUS_PAUSED")

	var time: int = floori(timer.get_time_left())
	var time_minutes: int = floor(time / 60.0)
	var time_seconds: int = time - time_minutes * 60
	var time_string: String = "%02d:%02d" % [time_minutes, time_seconds]
	
	return time_string


#########################
###     Callbacks     ###
#########################

func _on_local_player_generated_waves():
	_update_wave_details()


func _on_started_first_wave():
	_start_game_button.hide()
	_start_next_wave_button.show()


func _on_wave_level_changed():
	_update_wave_details()


func _on_start_next_wave_button_pressed():
	EventBus.player_requested_next_wave.emit()


func _on_start_game_button_pressed():
	EventBus.player_requested_start_game.emit()
