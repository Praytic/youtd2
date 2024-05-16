class_name TutorialController extends Node


# Controls the flow of tutorials. Collects triggers and converts them into tutorials. Note that multiple tutorials can be queued at a time.


signal tutorial_triggered(tutorial_id: TutorialProperties.TutorialId)


enum Trigger {
	PLAYER_STARTED_BUILD_MODE_GAME,
	PLAYER_STARTED_RANDOM_MODE_GAME,
	RESEARCH_ELEMENT,
	ROLLED_TOWERS,
	BUILT_A_TOWER,
	FIRST_ITEM_DROP,
	PORTAL_DAMAGE,
	WAVE_1_FINISHED,
	WAVE_7_FINISHED,
	WAVE_10_FINISHED,
	WAVE_15_FINISHED,
	UNIT_LEVELED_UP,
	
	COUNT,
}

var _trigger_to_tutorial_list_map: Dictionary = {
	Trigger.PLAYER_STARTED_BUILD_MODE_GAME: [TutorialProperties.TutorialId.INTRO_FOR_BUILD_MODE],
	Trigger.PLAYER_STARTED_RANDOM_MODE_GAME: [TutorialProperties.TutorialId.INTRO_FOR_RANDOM_MODE, TutorialProperties.TutorialId.RESEARCH_ELEMENTS],
	Trigger.RESEARCH_ELEMENT: [TutorialProperties.TutorialId.ROLL_TOWERS],
	Trigger.ROLLED_TOWERS: [TutorialProperties.TutorialId.TOWER_STASH, TutorialProperties.TutorialId.BUILD_TOWER],
	Trigger.BUILT_A_TOWER: [TutorialProperties.TutorialId.RESOURCES, TutorialProperties.TutorialId.TOWER_INFO],
	Trigger.FIRST_ITEM_DROP: [TutorialProperties.TutorialId.ITEMS],
	Trigger.PORTAL_DAMAGE: [TutorialProperties.TutorialId.PORTAL_DAMAGE],
	Trigger.WAVE_1_FINISHED: [TutorialProperties.TutorialId.WAVE_1_FINISHED],
	Trigger.WAVE_7_FINISHED: [TutorialProperties.TutorialId.CHALLENGE_WAVE],
	Trigger.WAVE_10_FINISHED: [TutorialProperties.TutorialId.UPGRADING],
	Trigger.WAVE_15_FINISHED: [TutorialProperties.TutorialId.TRANSFORMING],
	Trigger.UNIT_LEVELED_UP: [TutorialProperties.TutorialId.TOWER_LEVELS],
}

var _trigger_processed_map: Dictionary = {}
var _tutorial_queue: Array = []
var _tutorial_is_in_progress: bool = false


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.finished_tutorial_section.connect(_on_finished_tutorial_section)
	EventBus.local_player_rolled_towers.connect(_on_local_player_rolled_towers)
	EventBus.item_dropped.connect(_on_item_dropped)
	EventBus.portal_received_damage.connect(_on_portal_received_damage)
	EventBus.built_a_tower.connect(_on_built_a_tower)
	EventBus.unit_leveled_up.connect(_on_unit_leveled_up)
	
	for trigger in range(0, Trigger.COUNT):
		var trigger_is_mapped: bool = _trigger_to_tutorial_list_map.has(trigger)
		
		if !trigger_is_mapped:
			push_error("Tutorial trigger is unmapped: %d" % trigger)


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	local_player.selected_builder.connect(_on_local_player_selected_builder)
	local_player.element_level_changed.connect(_on_local_player_element_level_changed)
	local_player.wave_finished.connect(_on_local_player_wave_finished)


#########################
###      Private      ###
#########################

# NOTE: triggers are processed only once and ignored after
# that
func _process_trigger(trigger: Trigger):
	var trigger_already_processed: bool = _trigger_processed_map.has(trigger)

	if !trigger_already_processed:
		_trigger_processed_map[trigger] = true
		
		var triggered_tutorial_list: Array = _trigger_to_tutorial_list_map[trigger]
		_tutorial_queue.append_array(triggered_tutorial_list)
		_process_tutorial_queue()


func _process_tutorial_queue():
	if _tutorial_queue.is_empty() || _tutorial_is_in_progress:
		return
	
	var tutorial: int = _tutorial_queue.pop_front()
	_tutorial_is_in_progress = true
	tutorial_triggered.emit(tutorial)


#########################
###     Callbacks     ###
#########################

# NOTE: some tutorials are followed up by other tutorials so process queue after tutorial is closed
func _on_finished_tutorial_section():
	_tutorial_is_in_progress = false
	_process_tutorial_queue()


# NOTE: this is the first trigger, where the tutorial starts
func _on_local_player_selected_builder():
	var game_mode: GameMode.enm = Globals.get_game_mode()
	
	if game_mode == GameMode.enm.BUILD:
		_process_trigger(Trigger.PLAYER_STARTED_BUILD_MODE_GAME)
	else:
		_process_trigger(Trigger.PLAYER_STARTED_RANDOM_MODE_GAME)



func _on_local_player_element_level_changed():
	_process_trigger(Trigger.RESEARCH_ELEMENT)


func _on_local_player_rolled_towers():
	_process_trigger(Trigger.ROLLED_TOWERS)


func _on_item_dropped():
	_process_trigger(Trigger.FIRST_ITEM_DROP)


func _on_portal_received_damage():
	_process_trigger(Trigger.PORTAL_DAMAGE)


func _on_local_player_wave_finished(level: int):
	match level:
		1: _process_trigger(Trigger.WAVE_1_FINISHED)
		7: _process_trigger(Trigger.WAVE_7_FINISHED)
		10: _process_trigger(Trigger.WAVE_10_FINISHED)
		15: _process_trigger(Trigger.WAVE_15_FINISHED)


func _on_built_a_tower():
	_process_trigger(Trigger.BUILT_A_TOWER)


func _on_unit_leveled_up():
	_process_trigger(Trigger.UNIT_LEVELED_UP)
