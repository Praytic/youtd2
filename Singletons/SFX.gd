extends Node


var _loaded_sfx_map: Dictionary = {}
var _2d_sfx_player_list: Array = []
var _sfx_player_list: Array = []


@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")


# NOTE: this f-n is non-positional. Current viewport
# position doesn't affect the sfx.
func play_sfx(sfx_name: String):
	if !FF.sfx_enabled():
		return

	var sfx_player: AudioStreamPlayer = _get_sfx_player()
	var sfx_stream: AudioStream = _get_sfx(sfx_name)

	var invalid_sfx: bool = sfx_stream.get_length() == 0

	if invalid_sfx:
		return

	sfx_player.set_stream(sfx_stream)
	sfx_player.play()


func sfx_at_pos(sfx_name: String, sfx_position: Vector2):
	if !FF.sfx_enabled():
		return

	var sfx_player: AudioStreamPlayer2D = _get_2d_sfx_player()
	var sfx_stream: AudioStream = _get_sfx(sfx_name)

	var invalid_sfx: bool = sfx_stream.get_length() == 0

	if invalid_sfx:
		return

	sfx_player.set_stream(sfx_stream)
	sfx_player.global_position = sfx_position
	sfx_player.play()


func sfx_at_unit(sfx_name: String, unit: Unit):
	var sfx_position: Vector2 = unit.get_visual_position()
	sfx_at_pos(sfx_name, sfx_position)


func sfx_on_unit(sfx_name: String, unit: Unit, body_part: String):
	var sfx_position: Vector2 = unit.get_body_part_position(body_part)
	sfx_at_pos(sfx_name, sfx_position)


func _get_sfx(sfx_name: String) -> AudioStream:
	if _loaded_sfx_map.has(sfx_name):
		return _loaded_sfx_map[sfx_name]

	if !sfx_name.ends_with(".mp3") && !sfx_name.ends_with(".wav") && !sfx_name.ends_with(".ogg"):
		print_debug("Sfx must be mp3, wav or ogg:", sfx_name)

		return AudioStreamMP3.new()

	var file_exists: bool = ResourceLoader.exists(sfx_name)

	if !file_exists:
		print_debug("Failed to find sfx at:", sfx_name)

		return AudioStreamMP3.new()

	var stream: AudioStream = load(sfx_name)

#	NOTE: turn off looping in case it was turned on in sfx's
#	.import file.
	if stream is AudioStreamMP3:
		var stream_mp3: AudioStreamMP3 = stream as AudioStreamMP3
		stream_mp3.loop = false
	elif stream is AudioStreamOggVorbis:
		var stream_ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
		stream_ogg.loop = false

	_loaded_sfx_map[sfx_name] = stream

	return stream


func _get_sfx_player() -> AudioStreamPlayer:
	for sfx_player in _sfx_player_list:
		if !sfx_player.playing:
			return sfx_player

	var new_sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
	_sfx_player_list.append(new_sfx_player)
	_game_scene.add_child(new_sfx_player)

	return new_sfx_player


# This is a way to recycle existing players
func _get_2d_sfx_player() -> AudioStreamPlayer2D:
	for sfx_player in _2d_sfx_player_list:
		if !sfx_player.playing:
			return sfx_player

	var new_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	_2d_sfx_player_list.append(new_sfx_player)
	_game_scene.add_child(new_sfx_player)

	return new_sfx_player
