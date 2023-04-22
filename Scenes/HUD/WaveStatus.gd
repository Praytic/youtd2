extends Control


# Displays next wave level how much time is left before it
# starts.


@onready var _label: RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")


func _ready():
	WaveLevel.changed.connect(_update_text)

	_update_text()


func _process(_delta: float):
	_update_text()


func _update_text():
	_label.clear()
	
	var text: String = ""

	var next_wave_level: int = WaveLevel.get_current() + 1
	var wave_time: int = floor(_wave_spawner.get_time_left())
	var wave_time_minutes: int = floor(wave_time / 60.0)
	var wave_time_seconds: int = wave_time - wave_time_minutes * 60

	text += "Wave %d in %02d:%02d\n" % [next_wave_level, wave_time_minutes, wave_time_seconds]

	_label.append_text(text)



func _on_start_next_wave_button_pressed():
	if _wave_spawner.wave_is_in_progress():
		Globals.error_message_label.add("Can't start next wave, wave is still in progress.")

		return

	_wave_spawner.force_start_next_wave()
