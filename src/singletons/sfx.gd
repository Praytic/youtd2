extends Node


# Functions for playing sound effects.


var _loaded_sfx_map: Dictionary = {}
var _2d_sfx_player_list: Array = []
var _sfx_player_list: Array = []

# --- SFX coalescing knobs (tune these two together) ---
# Within COALESCE_WINDOW_MS, at most MAX_SIMULTANEOUS_PER_SFX
# plays of the SAME sfx path are allowed; extra copies are
# dropped. This keeps multi-hit bursts audible (a splash hitting
# 30 creeps plays ~5 overlapping copies, not 30) without summing
# identical waveforms into clipping / exhausting audio voices.
# NOTE: this is client-local/cosmetic (uses real time, not sim
# time) and does not affect multiplayer determinism.
const COALESCE_WINDOW_MS: int = 200
const MAX_SIMULTANEOUS_PER_SFX: int = 3

# sfx_path -> { "window_start": int (ms), "count": int }
var _recent_play_map: Dictionary = {}


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

	if !_coalesce_allows(sfx_path):
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

	if !_coalesce_allows(sfx_path):
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


# NOTE: this f-n is *not* the same thing as SFXAtUnit() in
# JASS.
# This function plays a sound effect.
# SFXAtUnit() from JASS creates a "simple effect" (SFX),
# where "effect" is visual, not sound.
func sfx_at_unit(sfx_path: String, unit: Unit, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if unit == null:
		push_error("null unit passed to SFX.sfx_at_unit()")
		
		return

	var sfx_position: Vector2 = unit.get_visual_position()
	sfx_at_pos(sfx_path, sfx_position, volume_db, pitch_scale)


#########################
###      Private      ###
#########################

# Fixed-window per-path rate cap. Returns false when this sfx
# path has already played MAX_SIMULTANEOUS_PER_SFX times within
# the current COALESCE_WINDOW_MS window (so the caller drops it).
# See the coalescing knobs at the top of this file.
func _coalesce_allows(sfx_path: String) -> bool:
	var now: int = Time.get_ticks_msec()
	var entry: Dictionary = _recent_play_map.get(sfx_path, {})

	var window_expired: bool = entry.is_empty() || now - entry["window_start"] >= COALESCE_WINDOW_MS

	if window_expired:
		_recent_play_map[sfx_path] = {"window_start": now, "count": 1}

		return true

	if entry["count"] < MAX_SIMULTANEOUS_PER_SFX:
		entry["count"] += 1

		return true

	return false


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
