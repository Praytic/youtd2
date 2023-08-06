extends Control


# Displays next wave level how much time is left before it
# starts.


@onready var _label: RichTextLabel = $PanelContainer/VBoxContainer/DetailsLabel
@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")
@onready var _start_next_wave_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/StartNextWaveButton
@onready var _timer_label: RichTextLabel = $PanelContainer/VBoxContainer/TimerLabel


func _ready():
	WaveLevel.changed.connect(_update_all_labels)
	_wave_spawner.generated_all_waves.connect(_update_all_labels)
	_wave_spawner.all_waves_started.connect(_on_all_waves_started)

	_update_all_labels()


func _process(_delta: float):
	_update_timer_label()


func _update_all_labels():
	_update_timer_label()
	_update_details_label()


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

		var size_string: String = wave.get_creep_combination_string()

		var armor_type: ArmorType.enm = wave.get_armor_type()
		var armor_string: String = ArmorType.convert_to_colored_string(armor_type)

		var specials_string: String = _get_specials_string(wave)

		text += "[cell]%d[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [level, size_string, race_string, armor_string, specials_string]
	
	text += "[/table]"

	_label.append_text(text)


func _on_start_next_wave_button_pressed():
	var success = _wave_spawner.force_start_next_wave()
	if !success:
		Messages.add_error("Can't start next wave, wave is still in progress.")


func _on_all_waves_started():
	_start_next_wave_button.disabled = true


func _get_specials_string(wave: Wave) -> String:
	var special_list: Array[int] = wave.get_specials()
	var string_list: Array[String] = []

	for special in special_list:
		var string: String = WaveSpecial.get_special_name(special)
		string_list.append(string)

	var specials_string: String = ", ".join(string_list)

	return specials_string
