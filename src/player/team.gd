class_name Team extends Node

# Represents the player's team. In singleplayer, the player
# simply has a team. In multiplayer it can be 1-2 players
# per team.


signal started_first_wave()
signal game_lose()
signal game_win()
signal level_changed()


var _id: int = -1
var _lives: float = 100
var _level: int = 1
var _player_list: Array[Player] = []
var _finished_the_game: bool = false
var _player_defined_autospawn_time: float = -1

@export var _next_wave_timer: ManualTimer


#########################
###       Public      ###
#########################

func finished_the_game() -> bool:
	return _finished_the_game


func get_next_wave_timer() -> ManualTimer:
	return _next_wave_timer


func start_first_wave():
	_start_wave()
	started_first_wave.emit()


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
	
	player.wave_spawned.connect(_on_player_wave_spawned)
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

	if out_of_lives && !_finished_the_game:
		_do_game_lose()


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


func set_autospawn_time(time: float):
	_player_defined_autospawn_time = time


#########################
###      Private      ###
#########################

func _start_wave():
	_next_wave_timer.stop()
	
	for player in _player_list:
		player.start_wave(_level)


func _do_game_win():
	var game_is_neverending: bool = Globals.game_is_neverending()
	
	if !game_is_neverending:
		_finished_the_game = true
	
	var game_win_message: String
	if game_is_neverending:
		game_win_message = "[color=GOLD]You are a winner... but the waves are[/color] [color=RED]Neverending[/color][color=GOLD]![/color]"
	else:
		game_win_message = "[color=GOLD]You are a winner![/color]"

	for player in _player_list:
		Messages.add_normal(PlayerManager.get_local_player(), game_win_message)

	if is_local():
		_convert_local_player_score_to_exp()

	game_win.emit()

	for i in range(10):
		var effect_count: int = 100 + i * 20
		
		for j in range(effect_count):
			var x: float = Globals.synced_rng.randf_range(-4000, 4000)
			var y: float = Globals.synced_rng.randf_range(-4000, 4000)
			var scale: float = Globals.synced_rng.randf_range(5.0, 10.0)
			var speed: float = Globals.synced_rng.randf_range(0.3, 1.0)

			var effect: int = Effect.create_simple("placeholder path", Vector2(x, y))
			Effect.set_scale(effect, scale)
			Effect.set_animation_speed(effect, speed)
			Effect.destroy_effect_after_its_over(effect)

		await Utils.create_timer(1.0, self).timeout


func _do_game_lose():
	_finished_the_game = true

#	Delete all creeps for this team
	var creep_list: Array[Creep] = Utils.get_creep_list()
	for creep in creep_list:
		var player_match: bool = _player_list.has(creep.get_player())

		if player_match:
			creep.remove_from_game()

	_next_wave_timer.stop()

	for player in _player_list:
		Messages.add_normal(player, "[color=RED]The portal has been destroyed! The game is over.[/color]")

	if is_local():
		_convert_local_player_score_to_exp()

	game_lose.emit()


func _convert_local_player_score_to_exp():
	var old_exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var old_player_exp: int = ExperiencePassword.decode(old_exp_password)
	var old_player_level: int = PlayerExperience.get_level_at_exp(old_player_exp)

	var local_player: Player = PlayerManager.get_local_player()
	var score: int = floori(local_player.get_score())
	var exp_gain: int = floori(score * Constants.SCORE_TO_EXP)

	var new_player_exp: int = old_player_exp + exp_gain
	var new_exp_password: String = ExperiencePassword.encode(new_player_exp)
	var new_player_level: int = PlayerExperience.get_level_at_exp(new_player_exp)
	Settings.set_setting(Settings.EXP_PASSWORD, new_exp_password)
	Settings.flush()

	var old_upgrade_count: int = Utils.get_wisdom_upgrade_count_for_player_level(old_player_level)
	var new_upgrade_count: int = Utils.get_wisdom_upgrade_count_for_player_level(new_player_level)
	var gained_new_wisdom_upgrade_slot: bool = new_upgrade_count > old_upgrade_count

	if exp_gain > 0:
		Messages.add_normal(local_player, "You gained [color=GOLD]%d[/color] experience." % exp_gain)
	elif exp_gain == 0:
		Messages.add_normal(local_player, "Your score is too low! You gained no experience.")
	elif exp_gain < 0:
		push_error("Exp gained is negative!")

	if new_player_level != old_player_level:
		Messages.add_normal(local_player, "You leveled up! You are now level [color=GOLD]%d[/color]." % new_player_level)

	if gained_new_wisdom_upgrade_slot:
		Messages.add_normal(local_player, "You obtained a new wisdom upgrade slot! You can select wisdom upgrades in the [color=GOLD]Profile[/color] menu on the Title screen.")


# This function starts the timer only if it's not already
# running or if new duration is shorter


# NOTE: it's possible for timer to already be running if the
# difficulty is extreme and the timer has been started
# automatically. In such cases, start timer only if new
# timer is shorter.
func _start_timer_before_next_wave(duration: float):
	var timer_already_running: bool = !_next_wave_timer.is_stopped()
	var new_duration_is_shorter: bool = duration < _next_wave_timer.get_time_left()
	var need_to_start_timer: bool = !timer_already_running || new_duration_is_shorter

	if need_to_start_timer:
		_next_wave_timer.start(duration)


# On extreme difficulty, there's built-in autospawn. This
# f-n calculates the autospawn time.
# Sample values:
# lvl 1 = 25s
# lvl 30 = 40s
# lvl 100 = 40s
# lvl 120 = 40s
# lvl 240 = 34s
# Goes up, stays at 40s, then goes down
func _get_extreme_autospawn_time(level: int) -> float:
	var time: float = min(25 + 0.5 * level, 40) + 6 - max(0.05 * level, 6)
#	NOTE: prevent negative value
	time = max(time, 1)

	return time


func _get_bonus_wave_autospawn_time(level: int) -> float:
	const START_TIME: float = 20.0
	const MIN_TIME: float = 1.0
	const REDUCTION_PER_LEVEL: float = 0.25

	var autospawn_time: float = START_TIME - max(0, level - Constants.WAVE_COUNT_NEVERENDING) * REDUCTION_PER_LEVEL
	autospawn_time = max(autospawn_time, MIN_TIME)

	return autospawn_time


#########################
###     Callbacks     ###
#########################

func _on_next_wave_timer_timeout():
	start_next_wave()


func _on_player_wave_spawned(level: int):
	var started_last_wave: bool = level == Globals.get_wave_count()
	var difficulty_is_extreme: bool = Globals.get_difficulty() == Difficulty.enm.EXTREME
	var game_is_neverending: bool = Globals.game_is_neverending()
	var bonus_waves_in_progress: bool = Utils.wave_is_bonus(level)
	var autospawn_time_is_defined: bool = _player_defined_autospawn_time > 0
	var extreme_autospawn_time: float = _get_extreme_autospawn_time(level)

#	NOTE: pick shortest autospawn time out of all possible
#	sources
	var autospawn_time_list: Array[float] = []
	if autospawn_time_is_defined:
		autospawn_time_list.append(_player_defined_autospawn_time)
	if difficulty_is_extreme && !started_last_wave:
		autospawn_time_list.append(extreme_autospawn_time)
	if game_is_neverending && bonus_waves_in_progress:
		var bonus_wave_autospawn_time: float = _get_bonus_wave_autospawn_time(level)
		autospawn_time_list.append(bonus_wave_autospawn_time)

	if !autospawn_time_list.is_empty():
		var autospawn_time: float = autospawn_time_list.min()
		_start_timer_before_next_wave(autospawn_time)


func _on_player_wave_finished(level: int):
	if _finished_the_game:
		return

#	NOTE: need to check that *current* level was finished
#	because waves can be finished out of order if they are
#	force spawned by player. If player finished not-current
#	level, then we don't need to do any reactions.
	var current_level: int = get_level()
	var finished_current_level: bool = level == current_level
	
	if !finished_current_level:
		return

	var all_players_finished: bool = true
	for player in _player_list:
		if !player.current_wave_is_finished():
			all_players_finished = false
		
	var player_finished_last_level: bool = level == Utils.get_max_level()
	var team_achieved_victory: bool = player_finished_last_level && all_players_finished

	if team_achieved_victory:
		_do_game_win()

	var game_is_neverending: bool = Globals.game_is_neverending()
	var need_to_start_next_wave_timer: bool = !player_finished_last_level || game_is_neverending
	if need_to_start_next_wave_timer:
		_start_timer_before_next_wave(Constants.TIME_BETWEEN_WAVES)


#########################
###       Static      ###
#########################

static func make(id: int) -> Team:
	var team: Team = Preloads.team_scene.instantiate()
	team._id = id

	return team
