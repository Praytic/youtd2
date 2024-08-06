extends Node


# Functions for playing sound effects.


var _loaded_sfx_map: Dictionary = {}
var _2d_sfx_player_list: Array = []
var _sfx_player_list: Array = []


#########################
###       Public      ###
#########################

func play_sfx_for_team(team: Team, sfx_path: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	var player_list: Array[Player] = team.get_players()

	for player in player_list:
		SFX.play_sfx_for_player(player, sfx_path, volume_db, pitch_scale)


func play_sfx_for_player(player: Player, sfx_path: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	var player_is_local_player: bool = player == PlayerManager.get_local_player()

	if player_is_local_player:
		SFX.play_sfx(sfx_path, volume_db, pitch_scale)


func play_sfx_random_pitch(sfx_path: String, volume_db: float = 0.0, pitch_scale_min: float = 0.95, pitch_scale_max: float = 1.05):
	var random_pitch: float = Globals.local_rng.randf_range(pitch_scale_min, pitch_scale_max)
	
	SFX.play_sfx(sfx_path, volume_db, random_pitch)


# NOTE: this f-n is non-positional. Current viewport
# position doesn't affect the sfx.
func play_sfx(sfx_path: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if !Settings.get_bool_setting(Settings.ENABLE_SFX):
		return

	var sfx_player: AudioStreamPlayer = _get_sfx_player()
	sfx_player.pitch_scale = pitch_scale
	sfx_player.volume_db = volume_db
	var sfx_stream: AudioStream = _get_sfx(sfx_path)

	var invalid_sfx: bool = sfx_stream == null || sfx_stream.get_length() == 0

	if invalid_sfx:
		push_error("SFX [%s] doesn't exist." % sfx_path)
		
		return

	sfx_player.set_stream(sfx_stream)
	sfx_player.play()


func sfx_at_pos(sfx_path: String, sfx_position: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if !Settings.get_bool_setting(Settings.ENABLE_SFX):
		return

	var sfx_player: AudioStreamPlayer2D = _get_2d_sfx_player()
	sfx_player.pitch_scale = pitch_scale
	sfx_player.volume_db = volume_db
	var sfx_stream: AudioStream = _get_sfx(sfx_path)

	var invalid_sfx: bool = sfx_stream.get_length() == 0

	if invalid_sfx:
		return

	sfx_player.set_stream(sfx_stream)
	sfx_player.global_position = sfx_position
	sfx_player.play()


# NOTE: SFXAtUnit() in JASS
func sfx_at_unit(sfx_path: String, unit: Unit, volume_db: float = 0.0, pitch_scale: float = 1.0):
	var sfx_position: Vector2 = unit.get_visual_position()
	sfx_at_pos(sfx_path, sfx_position, volume_db, pitch_scale)


# NOTE: SFXOnUnit() in JASS
func sfx_on_unit(sfx_path: String, unit: Unit, body_part: Unit.BodyPart, volume_db: float = 0.0, pitch_scale: float = 1.0):
	var sfx_position: Vector2 = unit.get_body_part_position(body_part)
	sfx_at_pos(sfx_path, sfx_position, volume_db, pitch_scale)


#########################
###      Private      ###
#########################

func _get_sfx(sfx_path: String) -> AudioStream:
	if _loaded_sfx_map.has(sfx_path):
		return _loaded_sfx_map[sfx_path]

	if !sfx_path.ends_with(".mp3") && !sfx_path.ends_with(".wav") && !sfx_path.ends_with(".ogg"):
		push_error("Sfx must be mp3, wav or ogg:", sfx_path)

		return AudioStreamMP3.new()

	var file_exists: bool = ResourceLoader.exists(sfx_path)

	if !file_exists:
		push_error("Failed to find sfx at:", sfx_path)

		return AudioStreamMP3.new()

	var stream: AudioStream = load(sfx_path)

#	NOTE: turn off looping in case it was turned on in sfx's
#	.import file.
	if stream is AudioStreamMP3:
		var stream_mp3: AudioStreamMP3 = stream as AudioStreamMP3
		stream_mp3.loop = false
	elif stream is AudioStreamOggVorbis:
		var stream_ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
		stream_ogg.loop = false

	_loaded_sfx_map[sfx_path] = stream

	return stream


# This function either returns a newly created
# AudioStreamPlayer or reuses a previously created one.
func _get_sfx_player() -> AudioStreamPlayer:
	var idle_player: AudioStreamPlayer = null

	for sfx_player in _sfx_player_list:
		if !sfx_player.playing:
			idle_player = sfx_player

			break

	if idle_player != null:
		return idle_player

	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	_sfx_player_list.append(new_player)
	add_child(new_player)

	return new_player


# Same as _get_sfx_player() but for AudioStreamPlayer2D
func _get_2d_sfx_player() -> AudioStreamPlayer2D:
	var idle_player: AudioStreamPlayer2D = null

	for sfx_player in _2d_sfx_player_list:
		if !sfx_player.playing:
			idle_player = sfx_player

			break

	if idle_player != null:
		return idle_player

	var new_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	_2d_sfx_player_list.append(new_player)
	add_child(new_player)

	return new_player
