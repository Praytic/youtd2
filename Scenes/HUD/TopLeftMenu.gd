extends VBoxContainer


@export var _start_next_wave_button: Button
@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")


func _ready():
	_wave_spawner.all_waves_started.connect(_on_all_waves_started)
	EventBus.game_over.connect(_on_game_over)


func _unhandled_input(event: InputEvent):
	var start_next_wave_keybind_pressed: bool = event.is_action_released("start_next_wave")

	if start_next_wave_keybind_pressed:
		_on_start_next_wave_button_pressed()


func _on_start_next_wave_button_pressed():
	if !Globals.built_at_least_one_tower:
		Messages.add_error("You have to build some towers before you can start a wave!")

		return

	var success: bool = _wave_spawner.force_start_next_wave()
	if !success:
		Messages.add_error("Can't start next wave, wave is still in progress.")


func _on_all_waves_started():
	_start_next_wave_button.disabled = true


func _on_game_over():
	_start_next_wave_button.disabled = true
