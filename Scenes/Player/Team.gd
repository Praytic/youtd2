class_name Team extends Node

# Represents player's team. Two players per team.

# NOTE: Currently team is barely implemented. Will need to
# work on it for multiplayer.

signal game_over()
signal game_win()
signal level_changed()


var _id: int = -1
var _lives: float = 100
var _level: int = 1
var _player_list: Array[Player] = []
var _is_game_over: bool = false

@export var _next_wave_timer: ManualTimer
@export var _extreme_timer: ManualTimer


#########################
###       Public      ###
#########################

func is_game_over() -> bool:
	return _is_game_over


func get_next_wave_timer() -> ManualTimer:
	return _next_wave_timer


func start_first_wave():
	_start_wave()


func start_next_wave():
	_level += 1
	level_changed.emit()
	_start_wave()


func create_player(player_id: int, peer_id: int) -> Player:
	var player: Player = Preloads.player_scene.instantiate()
	player._id = player_id
	player._peer_id = peer_id
	player._team = self

	_player_list.append(player)

#	Add base class Builder as placeholder until the real
#	builder is assigned. This builder will have no effects.
	var placeholder_builder: Builder = Builder.new()
	player._builder = placeholder_builder
	player.add_child(placeholder_builder)
	
	player.wave_finished.connect(_on_player_wave_finished)

	return player


func get_id() -> int:
	return _id


# NOTE: Team.getLivesPercent() in JASS
func get_lives_percent() -> float:
	return _lives


func get_lives_string() -> String:
	var lives_string: String = Utils.format_percent(floori(_lives) / 100.0, 2)

	return lives_string


func modify_lives(amount: float):
	_lives = max(0.0, _lives + amount)

	if Config.unlimited_portal_lives() && _lives == 0:
		_lives = 1

	var out_of_lives: bool = _lives <= 0

	if out_of_lives && !_is_game_over:
		_is_game_over = true
		game_over.emit()

#		Delete all creeps for this team
		var creep_list: Array[Creep] = Utils.get_creep_list()
		for creep in creep_list:
			var player_match: bool = _player_list.has(creep.get_player())

			if player_match:
				creep.remove_from_game()

		_next_wave_timer.stop()
		_extreme_timer.stop()


# Current level is the level of the last started wave.
# Starts at 0 and becomes 1 when the first wave starts.
# NOTE: Team.getLevel() in JASS
func get_level() -> int:
	return _level


func is_local() -> bool:
	var local_player: Player = PlayerManager.get_local_player()
	var contains_local_player: bool = _player_list.has(local_player)

	return contains_local_player


func set_waves_paused(paused: bool):
	_next_wave_timer.set_paused(paused)
	_extreme_timer.set_paused(paused)


#########################
###      Private      ###
#########################

func _start_wave():
	_extreme_timer.stop()
	_next_wave_timer.stop()
	
	for player in _player_list:
		player.start_wave(_level)

	var started_last_wave: bool = _level == Globals.get_wave_count()

	if !started_last_wave && Globals.get_difficulty() == Difficulty.enm.EXTREME:
		_extreme_timer.start(Constants.EXTREME_DELAY_AFTER_PREV_WAVE)


func _do_victory_effects():
	game_win.emit()
	
	for i in range(10):
		var effect_count: int = 100 + i * 20
		
		for j in range(effect_count):
			var x: float = Globals.synced_rng.randf_range(-4000, 4000)
			var y: float = Globals.synced_rng.randf_range(-4000, 4000)
			var scale: float = Globals.synced_rng.randf_range(5.0, 10.0)
			var speed: float = Globals.synced_rng.randf_range(0.3, 1.0)

			var effect: int = Effect.create_simple("placeholder path", x, y)
			Effect.set_scale(effect, scale)
			Effect.set_animation_speed(effect, speed)
			Effect.destroy_effect_after_its_over(effect)

		await Utils.create_timer(1.0, self).timeout


#########################
###     Callbacks     ###
#########################

func _on_extreme_timer_timeout():
	_next_wave_timer.start(Constants.EXTREME_DELAY_BEFORE_NEXT_WAVE)


func _on_next_wave_timer_timeout():
	start_next_wave()


func _on_player_wave_finished(level: int):
	if _is_game_over:
		return

#	NOTE: need to check that *current* level was finished
#	because waves can be finished out of order if they are
#	force spawned by player.
	var current_level: int = get_level()
	var finished_current_level: bool = level == current_level
	
	if !finished_current_level:
		return
	
	var all_players_finished: bool = true
	for player in _player_list:
		if !player.current_wave_is_finished():
			all_players_finished = false
	
	if !all_players_finished:
		return
	
	_extreme_timer.stop()
	
	var finished_last_level: bool = level == Utils.get_max_level()
	
	if finished_last_level:
		_do_victory_effects()
	else:
		_next_wave_timer.start(Constants.TIME_BETWEEN_WAVES)


#########################
###       Static      ###
#########################

static func make(id: int) -> Team:
	var team: Team = Preloads.team_scene.instantiate()
	team._id = id

	return team
