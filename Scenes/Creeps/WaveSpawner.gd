extends Node


const WAVE_COUNT_EASY = 80
const WAVE_COUNT_MEDIUM = 120
const WAVE_COUNT_HARD = 240


signal wave_started(wave: Wave)
signal wave_spawned(wave: Wave)
signal wave_ended(wave: Wave, cause: Wave.EndCause)
signal all_waves_cleared(cause: Wave.EndCause)


var _waves: Array = []


@onready var _timer_between_waves: Timer = $Timer
@onready var _creep_spawner = $CreepSpawner
@onready var _wave_paths = get_tree().get_nodes_in_group("wave_path")

func _ready():
	_timer_between_waves.set_autostart(false)
	
	for wave_number in range(0, WAVE_COUNT_EASY):
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
		
		print_debug("Wave number [%s] will have creeps [%s] of race [%s] and armor type [%s]" \
			% [wave_number, \
				", ".join(creep_combination), \
				Creep.Category.keys()[wave_race], \
				ArmorType.enm.keys()[wave_armor]])
		
		_waves.append(wave)
	
	print("Waves have been initialized. Total waves: %s" % _waves.size())
	
	_timer_between_waves.start()


func spawn_wave(wave: Wave):
	for creep_size in wave.get_creeps_combination():
		var creep = _creep_spawner \
			.get_creep_scene(creep_size, wave.get_race()) \
			.instantiate()
		creep.set_path_curve(wave.get_wave_path())
		creep.set_creep_size(creep_size)
		creep.set_armor_type(wave.get_armor_type())
		creep.set_category(wave.get_race())
		# TODO: set_health should be equal to base_hp * all_bonuses
		creep._health = wave.get_base_hp()
		creep._base_health = wave.get_base_hp()
		
		_creep_spawner.spawn_creep(creep)
	
	print_debug("Wave has been spawned [%s]." % wave)
	wave_spawned.emit(wave)


func end_wave(wave: Wave, cause: Wave.EndCause):
	if _waves.is_empty():
		all_waves_cleared.emit(cause)
	else:
		_timer_between_waves.start()
		wave_ended.emit(wave, cause)
	print_debug("Wave has ended [%s]." % wave)


func _on_Timer_timeout():
	var next_wave = _waves.pop_front()
	spawn_wave(next_wave)
	print_debug("Wave has started [%s]." % next_wave)
	wave_started.emit(next_wave)


func _get_wave_path(player: int, wave: Wave) -> Curve2D:
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
	return _wave_paths[idx].get_curve()
