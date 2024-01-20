extends PanelContainer


@export var _start_next_wave_button: Button
@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")


func _on_start_next_wave_button_pressed():
	if !Globals.built_at_least_one_tower:
		Messages.add_error("You have to build some towers before you can start a wave!")

		return

	var success: bool = _wave_spawner.force_start_next_wave()
	if !success:
		Messages.add_error("Can't start next wave, wave is still in progress.")
