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
@onready var _wave_paths = get_tree().get_nodes_in_group("wave_path")

func _ready():
	if Config.fast_waves_enabled():
		TIME_BETWEEN_WAVES = 0.1

	_timer_between_waves.set_autostart(false)
	_timer_between_waves.set_wait_time(TIME_BETWEEN_WAVES)


func generate_waves(wave_count: int, difficulty: Difficulty.enm):
	var previous_wave = null
	for wave_number in range(1, wave_count + 1):
		var wave_id = randi_range(0, Properties.get_wave_csv_properties().size() - 1)
		var wave_race = randi_range(0, CreepCategory.enm.size() - 1)
		var wave_armor = randi_range(0, ArmorType.enm.size() - 1)
		
		var wave = Wave.new()
		wave.set_id(wave_id)
		wave.set_wave_number(wave_number)
		wave.set_race(wave_race)
		wave.set_armor_type(wave_armor)
		wave.set_wave_path(_get_wave_path(0, wave))
		wave.set_difficulty(difficulty)
		
		var wave_specials: Array[int] = WaveSpecial.get_random(wave)
		wave.set_specials(wave_specials)

		var creep_combination = []
		for creep_size in wave.get_creeps_combination():
			var creep_size_name: String = CreepSize.convert_to_string(creep_size)
			creep_combination.append(creep_size_name)
		
		_init_wave_creeps(wave)
		
		print_verbose("Wave number [%s] will have creeps [%s] of race [%s] and armor type [%s]" \
			% [wave_number, \
				", ".join(creep_combination), \
				CreepCategory.convert_to_string(wave_race), \
				ArmorType.convert_to_string(wave_armor)])
		
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
	
	for creep_data in new_wave.get_creep_data_list():
		_creep_spawner.queue_spawn_creep(creep_data)


func _init_wave_creeps(wave: Wave):
	var creep_data_list: Array[CreepData] = []
	var creep_sizes = wave.get_creeps_combination()
	for creep_size in creep_sizes:
		var creep_data: CreepData = _creep_spawner.generate_creep_for_wave(wave, creep_size)
		creep_data_list.append(creep_data)
		
	wave.set_creep_data_list(creep_data_list)


func _on_Timer_timeout():
	_start_next_wave()


func _start_next_wave():
	_current_wave_index += 1

	var current_wave = get_current_wave()
	
	spawn_wave(current_wave)
	
	Messages.add_normal("Wave %d" % current_wave.get_wave_number())
	
	print_verbose("Wave has started [%s]." % current_wave)
	wave_started.emit(current_wave)

	var all_waves_have_been_started: bool = _current_wave_index == _wave_list.size() - 1

	if all_waves_have_been_started:
		all_waves_started.emit()


func _get_wave_path(player: int, wave: Wave) -> Path2D:
	var idx = -1
	for i in _wave_paths.size():
		var wave_path = _wave_paths[i]
		if wave_path.is_air == wave.is_air() \
				and wave_path.player == player:
			idx = i
			break
	
	if idx == -1:
		push_error("Could not find wave path for player [%s] and wave [%s] in "  % [player, wave] \
			+ "a group of paths [wave_path].")
	return _wave_paths[idx]


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

#	NOTE: some hero needs to modify parameters of income
#	formula, but that's for much later.
	var wave_level: int = wave.get_wave_number()
	var upkeep: int = 20 + wave_level * 2
	var current_gold: int = floori(GoldControl.get_gold())
	var interest: int = floori(min(current_gold * GoldControl.interest_rate, 1000))
	var income: int = upkeep + interest
	GoldControl.add_gold(income)

	Messages.add_normal("Income: %d upkeep, %d interest." % [upkeep, interest])

	print_verbose("Wave [%s] is cleared." % wave)

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
