extends Node


const WAVE_COUNT_EASY = 80
const WAVE_COUNT_MEDIUM = 120
const WAVE_COUNT_HARD = 240
var TIME_BETWEEN_WAVES: float = 5.0


signal wave_started(wave: Wave)
signal wave_spawned(wave: Wave)
signal wave_ended(wave: Wave)
signal all_waves_cleared


@onready var _timer_between_waves: Timer = $Timer
@onready var _creep_spawner = $CreepSpawner
@onready var _wave_paths = get_tree().get_nodes_in_group("wave_path")

func _ready():
	if FF.fast_waves_enabled():
		TIME_BETWEEN_WAVES = 0.1

	_timer_between_waves.set_autostart(false)
	_timer_between_waves.set_wait_time(TIME_BETWEEN_WAVES)
	
	var previous_wave = null
	for wave_number in range(1, WAVE_COUNT_EASY):
		var wave_id = randi_range(0, Properties.get_wave_csv_properties().size() - 1)
		var wave_race = randi_range(0, Creep.Category.size() - 1)
		var wave_armor = randi_range(0, ArmorType.enm.size() - 1)
		
		var wave = Wave.new()
		wave.set_id(wave_id)
		wave.set_wave_number(wave_number)
		wave.set_race(wave_race)
		wave.set_armor_type(wave_armor)
		wave.set_wave_path(_get_wave_path(0, wave))
		
		var creep_combination = []
		for creep_size in wave.get_creeps_combination():
			var creep_size_name = Creep.Size.keys()[creep_size]
			creep_combination.append(creep_size_name)
		
		_init_wave_creeps(wave)
		
		Log.debug("Wave number [%s] will have creeps [%s] of race [%s] and armor type [%s]" \
			% [wave_number, \
				", ".join(creep_combination), \
				Creep.Category.keys()[wave_race], \
				ArmorType.enm.keys()[wave_armor]])
		
		if previous_wave:
			previous_wave.next_wave = wave
		previous_wave = wave
		if wave_number == 1:
			wave.add_to_group("current_wave")
		wave.add_to_group("wave")
		
		wave.wave_ended.connect(Callable(self, "_on_Wave_ended"))
		
		add_child(wave, true)
	
	Log.debug("Waves have been initialized. Total waves: %s" % get_waves().size())
	
	_timer_between_waves.start()


func spawn_wave(new_wave: Wave):
	new_wave.state = Wave.State.SPAWNING
	
	for creep in new_wave.get_creeps():
		_creep_spawner.queue_spawn_creep(creep)


func _init_wave_creeps(wave: Wave):
	var creeps = []
	var creep_sizes = wave.get_creeps_combination()
	for creep_size in creep_sizes:
		var creep = _creep_spawner.generate_creep_for_wave(wave, creep_size)
		creeps.append(creep)
		
	wave.set_creeps(creeps)

func end_current_wave():
	var current_wave = get_current_wave()
	
	Log.debug("Wave has ended [%s]." % current_wave)
	
	# Send events, restart the timer
	if get_waves().is_empty():
		all_waves_cleared.emit()
	else:
		_timer_between_waves.start()
		wave_ended.emit(current_wave)
	
	# Prepare variables for the next wave
	var next_wave = current_wave.next_wave
	current_wave.remove_from_group("current_wave")
	next_wave.add_to_group("current_wave")


func _on_Timer_timeout():
	var current_wave = get_current_wave()
	
	spawn_wave(current_wave)
	
	Log.debug("Wave has started [%s]." % current_wave)
	wave_started.emit(current_wave)


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
	Log.debug("Wave has been spawned [%s]." % current_wave)
	wave_spawned.emit(current_wave)


func get_current_wave() -> Wave:
	return get_tree().get_first_node_in_group("current_wave")


func get_waves() -> Array:
	return get_tree().get_nodes_in_group("wave")


func _on_Wave_ended():
	var current_wave = get_current_wave()
	if current_wave.state == Wave.State.CLEARED:
		Log.debug("Wave [%s] is cleared." % current_wave)
		end_current_wave()
	else:
		push_error("Wave [%s] has ended but the state is invalid." % [current_wave])
	
