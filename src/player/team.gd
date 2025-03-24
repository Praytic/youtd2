class_name Team extends Node

# Represents the player's team. In singleplayer, the player
# simply has a team. In multiplayer it can be 1-2 players
# per team.


signal started_first_wave()
signal game_lose()
signal game_win()
signal level_changed()


const PORTAL_DAMAGE_SFX_COOLDOWN: float = 0.5
const START_WAVE_ACTION_COOLDOWN: float = 2.0


var _id: int = -1
var _lives: float = 100
var _level: int = 1
var _player_list: Array[Player] = []
var _finished_the_game: bool = false
var _player_defined_autospawn_time: float = -1
var _allow_shared_build_space: bool = false

@export var _next_wave_timer: ManualTimer
@export var _portal_damage_sound_cooldown_timer: Timer
@export var _start_wave_action_cooldown_timer: ManualTimer


#########################
###       Public      ###
#########################

func get_players() -> Array[Player]:
	return _player_list


func get_wave_is_in_progress() -> bool:
	var wave_is_in_progress: bool = false

	for player in _player_list:
		if player.wave_is_in_progress():
			wave_is_in_progress = true

			break

	return wave_is_in_progress


func finished_the_game() -> bool:
	return _finished_the_game


func get_next_wave_timer() -> ManualTimer:
	return _next_wave_timer


func start_first_wave():
	_start_wave()
	started_first_wave.emit()


func start_next_wave():
	var reached_last_wave: bool = _level == Globals.get_wave_count()
	var game_is_neverending: bool = Globals.game_is_neverending()

	if reached_last_wave && !game_is_neverending:
		return

	_level += 1
	level_changed.emit()
	_start_wave()


func add_player(player: Player):
	player._team = self
	_player_list.append(player)
	player.wave_spawned.connect(_on_player_wave_spawned)
	player.wave_finished.connect(_on_player_wave_finished)


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


func play_portal_damage_sfx():
	var portal_damage_sfx_on_cooldown: bool = !_portal_damage_sound_cooldown_timer.is_stopped()
	
	if portal_damage_sfx_on_cooldown:
		return
	
	SFX.play_sfx_for_team(self, SfxPaths.HUMAN_DEATH_EXPLODE)

	_portal_damage_sound_cooldown_timer.start(PORTAL_DAMAGE_SFX_COOLDOWN)


func convert_local_player_score_to_exp():
	var old_exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var old_player_exp: int = ExperiencePassword.decode(old_exp_password)
	var old_player_level: int = PlayerExperience.get_level_at_exp(old_player_exp)

	var local_player: Player = PlayerManager.get_local_player()
	var score: int = floori(local_player.get_score())
	var exp_gain: int = floori(score * Constants.SCORE_TO_EXP)

	var new_player_exp: int = old_player_exp + exp_gain
	var new_exp_password: String = ExperiencePassword.encode(new_player_exp)
	var new_player_level: int = PlayerExperience.get_level_at_exp(new_player_exp)
	var player_level_changed: bool = new_player_level != old_player_level
	Settings.set_setting(Settings.EXP_PASSWORD, new_exp_password)
	Settings.flush()

	var old_upgrade_count: int = Utils.get_wisdom_upgrade_count_for_player_level(old_player_level)
	var new_upgrade_count: int = Utils.get_wisdom_upgrade_count_for_player_level(new_player_level)
	var gained_new_wisdom_upgrade_slot: bool = new_upgrade_count > old_upgrade_count

	var exp_gain_message: String = tr("MESSAGE_GAINED_EXPERIENCE").format({EXP_GAIN = exp_gain})
	var level_up_message: String = tr("MESSAGE_PLAYER_LEVEL_UP").format({LEVEL = new_player_level})
	var wisdom_message: String = tr("MESSAGE_NEW_WISDOM_UPGRADE")

	var title_screen_notification: String = ""

	if exp_gain > 0:
		Messages.add_normal(local_player, exp_gain_message)
		title_screen_notification += exp_gain_message
	elif exp_gain == 0:
		Messages.add_normal(local_player, tr("MESSAGE_NO_EXPERIENCE_GAINED"))
	elif exp_gain < 0:
		push_error("Exp gained is negative!")

	if player_level_changed:
		Messages.add_normal(local_player, level_up_message)
		title_screen_notification += " \n"
		title_screen_notification += level_up_message

	if gained_new_wisdom_upgrade_slot:
		Messages.add_normal(local_player, wisdom_message)
		title_screen_notification += " \n"
		title_screen_notification += wisdom_message

	if !title_screen_notification.is_empty():
		title_screen_notification = tr("NOTIFICATION_AFTER_GAME") + "\n" +title_screen_notification
		Globals.add_title_screen_notification(title_screen_notification)


func get_start_wave_action_is_on_cooldown() -> bool:
	var is_on_cooldown: bool = !_start_wave_action_cooldown_timer.is_stopped()
	
	return is_on_cooldown


func enable_allow_shared_build_space():
	_allow_shared_build_space = true


func get_allow_shared_build_space() -> bool:
	return _allow_shared_build_space


#########################
###      Private      ###
#########################

func _start_wave():
	_next_wave_timer.stop()
	
	for player in _player_list:
		player.start_wave(_level)
	
	SFX.play_sfx_for_team(self, SfxPaths.START_WAVE)

# 	NOTE: "start wave action cooldown" is a cooldown for
# 	player manually starting next wave by clicking on the
# 	button. Need this cooldown for cases where it's possible
# 	for player to accidentally spawn two waves in a row. For
# 	example, if there are two boss waves back to back and
# 	player double clicks. Or if natural timer times out at
# 	the same time as player clicks on the button.
	_start_wave_action_cooldown_timer.start(START_WAVE_ACTION_COOLDOWN)


func _do_game_win():
	var game_is_neverending: bool = Globals.game_is_neverending()
	
	if !game_is_neverending:
		_finished_the_game = true
	
	var game_win_message: String
	if game_is_neverending:
		game_win_message = tr("MESSAGE_GAME_WIN_NEVERENDING")
	else:
		game_win_message = tr("MESSAGE_GAME_WIN_NORMAL")

	for player in _player_list:
		Messages.add_normal(PlayerManager.get_local_player(), game_win_message)

	if is_local():
		convert_local_player_score_to_exp()

	game_win.emit()

	var COLOR_LIST: Array[Color] = [Color.WHITE, Color.FOREST_GREEN, Color.CYAN, Color.VIOLET, Color.GOLD, Color.PINK, Color.ORANGE]

	for i in range(10):
		var effect_count: int = 100 + i * 20
		effect_count = ceili(randf_range(0.5, 1.0) * effect_count)
		
		for j in range(effect_count):
			var x: float = Globals.synced_rng.randf_range(-4000, 4000)
			var y: float = Globals.synced_rng.randf_range(-4000, 4000)
			var scale: float = Globals.synced_rng.randf_range(1.0, 2.0)
			var speed: float = Globals.synced_rng.randf_range(0.7, 1.0)
			var color: Color = COLOR_LIST.pick_random()

			var effect: int = Effect.create_simple("res://src/effects/placeholder.tscn", Vector2(x, y))
			Effect.set_scale(effect, scale)
			Effect.set_color(effect, color)
			Effect.set_animation_speed(effect, speed)

		await Utils.create_manual_timer(0.5, self).timeout


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
		Messages.add_normal(player, tr("MESSAGE_GAME_LOSE"))

	if is_local():
		convert_local_player_score_to_exp()

	game_lose.emit()

	for player in _player_list:
		player.emit_game_lose_signal()


# This function starts the timer only if it's not already
# running or if new duration is shorter
# 
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
	var wave_is_in_progress: bool = get_wave_is_in_progress()
	if wave_is_in_progress:
		return

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
	if difficulty_is_extreme:
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
	var can_start_next_wave_timer: bool = all_players_finished
	if need_to_start_next_wave_timer && can_start_next_wave_timer:
		_start_timer_before_next_wave(Constants.TIME_BETWEEN_WAVES)


#########################
###       Static      ###
#########################

static func make(id: int) -> Team:
	var team: Team = Preloads.team_scene.instantiate()
	team._id = id

	return team
