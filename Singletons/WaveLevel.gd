extends Node


# Stores the wave level of the most recent wave that has
# been spawned. Wave level changes when a wave is cleared.


signal changed()


@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")


func _ready():
	_wave_spawner.wave_started.connect(_on_wave_started)


# Current level is the level of the last started wave.
# Starts at 0.
func get_current():
	var current_level: int = _wave_spawner.get_current_wave_level()

	return current_level


func _on_wave_started(_wave: Wave):
	changed.emit()
