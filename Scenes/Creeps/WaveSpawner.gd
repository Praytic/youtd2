class_name WaveSpawner extends Node


var TIME_BETWEEN_WAVES: float = 15.0


signal wave_started(wave: Wave)
signal wave_spawned(wave: Wave)
signal wave_ended(wave: Wave)
signal all_waves_started
signal all_waves_cleared


var _wave_list: Array[Wave] = []
# NOTE: index starts at -1 because when the game starts no
# wave has been started yet
var _current_wave_index: int = -1


@onready var _timer_between_waves: Timer = $Timer
@onready var _creep_spawner = $CreepSpawner

func _ready():
	if Config.fast_waves_enabled():
		TIME_BETWEEN_WAVES = 0.1

	_timer_between_waves.set_autostart(false)
	_timer_between_waves.set_wait_time(TIME_BETWEEN_WAVES)


func generate_waves(wave_count: int, difficulty: Difficulty.enm):
	var previous_wave = null
	for wave_level in range(1, wave_count + 1):
		var wave: Wave = Wave.new(wave_level, difficulty)
		
		var creep_combination_string: String = wave.get_creep_combination_string()
		print_verbose("Wave [%s] will have creeps [%s] of race [%s] and armor type [%s]" \
			% [wave_level, \
				creep_combination_string, \
				CreepCategory.convert_to_string(wave.get_race()), \
				ArmorType.convert_to_string(wave.get_armor_type())])
		
		if previous_wave:
			previous_wave.next_wave = wave
		previous_wave = wave
		wave.add_to_group("wave")

		_wave_list.append(wave)
		
		wave.wave_ended.connect(_on_Wave_ended.bind(wave))
 
		add_child(wave, true)

	_creep_spawner.setup_background_load_queue(_wave_list)
	
	print_verbose("Waves have been initialized. Total waves: %s" % get_waves().size())
	
	_timer_between_waves.start()

	EventBus.waves_were_generated.emit()


func get_current_wave_level() -> int:
	if _current_wave_index != -1:
		return _current_wave_index + 1
	else:
		return 0


func spawn_wave(new_wave: Wave):
	new_wave.state = Wave.State.SPAWNING

	var creep_data_list: Array[CreepData] = WaveSpawner._generate_creep_data_list(new_wave)

	for creep_data in creep_data_list:
		_creep_spawner.queue_spawn_creep(creep_data)


func _on_Timer_timeout():
	_start_next_wave()


func _start_next_wave():
	_current_wave_index += 1

	var current_wave = get_current_wave()
	
	spawn_wave(current_wave)
	
	_add_message_about_wave(current_wave)
	
	print_verbose("Wave has started [%s]." % current_wave)
	wave_started.emit(current_wave)

	var all_waves_have_been_started: bool = _current_wave_index == _wave_list.size() - 1

	if all_waves_have_been_started:
		all_waves_started.emit()


func _on_CreepSpawner_all_creeps_spawned():
	var current_wave = get_current_wave()
	current_wave.state = Wave.State.SPAWNED
	print_verbose("Wave has been spawned [%s]." % current_wave)
	wave_spawned.emit(current_wave)


func get_current_wave() -> Wave:
	if _current_wave_index != -1:
		var current_wave: Wave = _wave_list[_current_wave_index]
		
		return current_wave
	else:
		return null


func get_waves() -> Array:
	return get_tree().get_nodes_in_group("wave")


# NOTE: use _wave_list instead of get_waves() because
# get_waves() uses get_nodes_in_group() which is not
# ordered.
func get_wave(level: int) -> Wave:
	var index: int = level - 1

	var in_bounds: bool = 0 <= index && index < _wave_list.size()

	if in_bounds:
		var wave: Wave = _wave_list[index]

		return wave
	else:
		return null


func get_time_left() -> float:
	var time: float = _timer_between_waves.get_time_left()

	return time


func wave_is_in_progress() -> float:
	var out: bool = _timer_between_waves.is_stopped()

	return out


func force_start_next_wave() -> bool:
	var current_wave: Wave = get_current_wave()
	var before_first_wave: bool = current_wave == null
	var current_wave_finished_spawning: bool = !before_first_wave && current_wave.state != Wave.State.SPAWNING
	var can_start_next_wave: bool = before_first_wave || current_wave_finished_spawning
	
	if can_start_next_wave:
		_timer_between_waves.stop()
		_start_next_wave()

		return true
	else:
		return false


func _on_Wave_ended(wave: Wave):
	if wave.state != Wave.State.CLEARED:
		push_error("Wave [%s] has ended but the state is invalid." % wave)
		
		return

	print_verbose("Wave [%s] is cleared." % wave)

	Messages.add_normal("=== Level [color=GOLD]%d[/color] completed! ===" % wave.get_level())

	wave_ended.emit(wave)

	var alive_creeps: Array = _get_alive_creeps()
	var all_creeps_are_killed: bool = alive_creeps.is_empty()
	var all_waves_were_started: bool = _current_wave_index == _wave_list.size() - 1

	if all_creeps_are_killed:
		if all_waves_were_started:
			all_waves_cleared.emit()
		else:
			_timer_between_waves.start()


func _get_alive_creeps() -> Array:
	var creep_list: Array = get_tree().get_nodes_in_group("creeps")
	var alive_list: Array = []

	for creep in creep_list:
		if !creep.is_dead():
			alive_list.append(creep)

	return alive_list


func _add_message_about_wave(wave: Wave):
	var combination_string: String = wave.get_creep_combination_string()

	var creep_race: CreepCategory.enm = wave.get_race()
	var race_string: String = CreepCategory.convert_to_colored_string(creep_race)

	var creep_armor: ArmorType.enm = wave.get_armor_type()
	var armor_string: String = ArmorType.convert_to_colored_string(creep_armor)

	Messages.add_normal("=== LEVEL [color=GOLD]%s[/color] ===" % wave.get_level())
	Messages.add_normal("%s (Race: %s, Armor: %s)" % [combination_string, race_string, armor_string])

	var special_list: Array[int] = wave.get_specials()

	for special in special_list:
		var special_name: String = WaveSpecial.get_special_name(special)
		var description: String = WaveSpecial.get_description(special)
		var special_string: String = "[color=BLUE]%s[/color] - %s" % [special_name, description]

		Messages.add_normal(special_string)


static func _generate_creep_data_list(wave: Wave) -> Array[CreepData]:
	var creep_data_list: Array[CreepData] = []
	var creep_combination: Array[CreepSize.enm] = wave.get_creep_combination()

	for creep_size in creep_combination:
		var creep_race: CreepCategory.enm = wave.get_creep_race()
		var scene_name: String = Wave.get_scene_name_for_creep_type(creep_size, creep_race)

		var creep_data: CreepData = CreepData.new()
		creep_data.scene_name = scene_name
		creep_data.size = creep_size
		creep_data.wave = wave

		creep_data_list.append(creep_data)
	
	return creep_data_list
