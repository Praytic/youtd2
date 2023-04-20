extends Control


# Displays next wave level how much time is left before it
# starts.


@onready var _label: RichTextLabel = $PanelContainer/RichTextLabel
@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")


func _ready():
	WaveLevel.changed.connect(_update_text)
#	_wave_spawner.wave_start(_on_wave_started)

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
