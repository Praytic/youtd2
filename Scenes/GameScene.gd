extends Node


enum GameState {
	PREGAME,
	PLAYING,
	PAUSED,
}


@onready var map_node: Node2D = $Map
@onready var _pregame_hud: Control = $UI/PregameHUD
@onready var _pause_hud: Control = $UI/PauseHUD
@onready var _wave_spawner: WaveSpawner = $Map/WaveSpawner

var _game_state: GameState


@export var creeps_game_over_count: int = 10
@export var ignore_game_over: bool = true


func _ready():
	print_verbose("GameScene has loaded.")

	_game_state = GameState.PREGAME
	get_tree().set_pause(true)

	var show_pregame_settings_menu: bool = Config.show_pregame_settings_menu()

	if show_pregame_settings_menu:
		_pregame_hud.show()
	else:
#		Skip pregame settings menu and load default values
		var default_wave_count: int = Config.default_wave_count()
		var default_game_mode: GameMode.enm = Config.default_game_mode()
		var default_difficulty: Difficulty.enm = Config.default_difficulty()

		_on_pregame_hud_finished(default_wave_count, default_game_mode, default_difficulty)


func _unhandled_input(event: InputEvent):
	var pause_pressed: bool = event.is_action_released("pause")
	
	if pause_pressed:
		match _game_state:
			GameState.PLAYING: _pause_the_game()
			GameState.PAUSED: _unpause_the_game()


func _on_HUD_start_wave(wave_index):
	$Map/CreepSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$Map/CreepSpawner.stop()


func _on_wave_spawner_wave_ended(wave: Wave):
	var wave_level: int = wave.get_level()
	GoldControl.add_income(wave_level)
	KnowledgeTomesManager.add_knowledge_tomes()


# TODO: use game_mode setting
func _on_pregame_hud_finished(wave_count: int, game_mode: GameMode.enm, difficulty: Difficulty.enm):
	_game_state = GameState.PLAYING
	get_tree().set_pause(false)
	
	_pregame_hud.hide()

	var difficulty_string: String = Difficulty.convert_to_string(difficulty).to_upper()


	Messages.add_normal("Welcome to youtd 2!")
	Messages.add_normal("Game settings: %d waves, %s difficulty" % [wave_count, difficulty_string])
	Messages.add_normal("You can pause the game by pressing F10")

	_wave_spawner.generate_waves(wave_count, difficulty)

	Globals.game_mode = game_mode


func _pause_the_game():
#	Cancel any in progress mouse actions
	BuildTower.cancel()
	ItemMovement.cancel()
	SelectTargetForCast.cancel()

	_game_state = GameState.PAUSED
	get_tree().set_pause(true)
	_pause_hud.show()


func _unpause_the_game():
	_game_state = GameState.PLAYING
	get_tree().set_pause(false)
	_pause_hud.hide()


func _on_pause_hud_resume_pressed():
	_unpause_the_game()
