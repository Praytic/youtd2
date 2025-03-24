class_name MissionManager extends Node


# Manages mission state during a match.

var _mission_list: Array[Mission] = []

@export var _hud: HUD


#########################
###     Built-in      ###
#########################

func _ready() -> void:
	EventBus.player_selected_builder.connect(_on_player_selected_builder)
	PlayerManager.players_created.connect(_on_players_created)

#	NOTE: missions are only for singleplayer so exit early
# 	if not in singleplayer
	var player_mode: PlayerMode.enm = Globals.get_player_mode()
	if player_mode != PlayerMode.enm.SINGLEPLAYER:
		return

	var id_list: Array = MissionProperties.get_id_list()
	
	for id in id_list:
		var already_completed: bool = MissionStatus.get_mission_is_complete(id)
		if already_completed:
			continue
		
		var mission_script_path: String = MissionProperties.get_script_path(id)
		var mission_script: Script = load(mission_script_path)
		
		var mission: Mission = mission_script.new(id)
		mission.was_failed.connect(_on_mission_was_failed.bind(mission))
		_mission_list.append(mission)
		add_child(mission)


#########################
###      Private      ###
#########################

func _remove_mission(mission: Mission):
	var mission_id: int = mission.get_id()
	_hud.set_mission_track_state(mission_id, MissionTrackIndicator.State.FAILED)

	_mission_list.erase(mission)
	remove_child(mission)
	mission.queue_free()


func _mission_requirements_are_satisfied(mission_id) -> bool:
	var required_wave_count: int = MissionProperties.get_wave_count(mission_id)
	var required_game_mode: GameMode.enm = MissionProperties.get_game_mode(mission_id)
	var required_difficulty: Difficulty.enm = MissionProperties.get_difficulty(mission_id)
	var required_builder_id: int = MissionProperties.get_builder(mission_id)
	
	var wave_count: int = Globals.get_wave_count()
	var game_mode: GameMode.enm = Globals.get_game_mode()
	var difficulty: Difficulty.enm = Globals.get_difficulty()
	var local_player: Player = PlayerManager.get_local_player()
	var builder: Builder = local_player.get_builder()
	var builder_id: int = builder.get_id()

	var wave_count_match: bool = wave_count == required_wave_count
	var game_mode_match: bool = game_mode == required_game_mode
	var difficulty_match: bool = difficulty == required_difficulty

	var required_builder_is_any: bool = required_builder_id == MissionProperties.BUILDER_ANY_ID
	var builder_match: bool = required_builder_is_any || builder_id == required_builder_id

	var all_match: bool = wave_count_match && game_mode_match && difficulty_match && builder_match

	return all_match


#########################
###     Callbacks     ###
#########################

func _on_players_created():
	var local_player: Player = PlayerManager.get_local_player()
	var local_team: Team = local_player.get_team()
	
	local_team.game_lose.connect(_on_game_lose)
	local_team.game_win.connect(_on_game_win)


# Some missions should be removed at the start of the game
# if incompatible game settings or builder are selected.
func _on_player_selected_builder():
	var removed_mission_list: Array = []

	for mission in _mission_list:
		var mission_id: int = mission.get_id()
		var requirements_ok: bool = _mission_requirements_are_satisfied(mission_id)

		if !requirements_ok:
			removed_mission_list.append(mission)

	for mission in removed_mission_list:
		_remove_mission(mission)


func _on_game_win():
#	NOTE: need to check missions for fail one last time
#	before processing game win because the fail check runs
#	periodically and may have missed a fail condition which
#	happened since last check
	_check_missions_for_fail()

	for mission in _mission_list:
		var mission_was_completed: bool = mission.process_game_win()

		if mission_was_completed:
			var mission_id: int = mission.get_id()
			var mission_description: String = MissionProperties.get_description(mission_id)
			
			_hud.set_mission_track_state(mission_id, MissionTrackIndicator.State.COMPLETED)

			MissionStatus.set_mission_is_complete(mission_id, true)
			Messages.add_normal(null, tr("MESSAGE_MISSION_COMPLETED").format({MISSION_DESCRIPTION = mission_description}))
			print_verbose("Mission was completed: %s" % mission_description)


# All in progress missions are failed on game over
func _on_game_lose():
	var mission_list: Array = _mission_list.duplicate()
	
	for mission in mission_list:
		_remove_mission(mission)


func _on_mission_was_failed(mission: Mission):
	var mission_id: int = mission.get_id()
	var mission_description: String = MissionProperties.get_description(mission_id)
	print_verbose("Mission was failed: %s" % mission_description)

#	NOTE: since mission was failed, remove it to stop
#	processing it
	_remove_mission(mission)


# NOTE: need to duplicate because _mission_list may get modified when mission is failed and gets removed from list
func _on_fail_check_timer_timeout() -> void:
	_check_missions_for_fail()


func _check_missions_for_fail():
	var mission_list: Array = _mission_list.duplicate()
	
	for mission in mission_list:
		mission.check_for_fail()


# NOTE: need to check fails for tracked missions more often so that there's
# not a large visual delay between doing a fail condition and tracking turning to FAILED
func _on_fast_fail_check_timer_timeout():
	var mission_list: Array = _mission_list.duplicate()
	
	var tracked_mission_list: Array = []
	
	for mission in mission_list:
		var mission_id: int = mission.get_id()
		var mission_is_tracked: bool = MissionTracking.get_mission_is_tracked(mission_id)
		
		if mission_is_tracked:
			tracked_mission_list.append(mission)
	
	for mission in tracked_mission_list:
		mission.check_for_fail()
	
