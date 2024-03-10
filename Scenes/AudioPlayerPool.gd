class_name AudioPlayerPool extends Node


# Provides access to reusable audio players. Creates new
# players when needed. Used by SFX singleton.


var _2d_sfx_player_list: Array = []
var _sfx_player_list: Array = []


#########################
###       Public      ###
#########################

func get_sfx_player() -> AudioStreamPlayer:
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


func get_2d_sfx_player() -> AudioStreamPlayer2D:
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
