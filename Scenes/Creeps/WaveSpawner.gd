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


func _ready():
	var wave_combinations_count = Properties.get_wave_csv_properties().size() - 1
	for wave_number in range(0, WAVE_COUNT_EASY):
		var wave_id = randi_range(0, wave_combinations_count)
		var wave_race = randi_range(0, Creep.Category.size())
		var wave_armor = randi_range(0, ArmorType.enm.size())
		
		var wave = Wave.new()
		wave.set_id(wave_id)
		wave.set_wave_number(wave_number)
		wave.set_race(wave_race)
		wave.set_armor_type(wave_armor)
		
		_waves.append(wave)


func spawn_wave(wave: Wave):
	for creep_size in wave.get_creeps_combination():
		var creep = Creep.new()
		creep.set_path_curve(wave.get_path())
		creep.set_creep_size(creep_size)
		creep.set_armor_type(wave.get_armor_type())
		creep.set_category(wave.get_race)
		
		_creep_spawner.spawn_creep(creep)
	wave_spawned.emit(wave)

func end_wave(wave: Wave, cause: Wave.EndCause):
	if _waves.is_empty():
		all_waves_cleared.emit(cause)
	else:
		_timer_between_waves.start()
		wave_ended.emit(wave, cause)


func _on_Timer_timeout():
	var next_wave = _waves.pop_front()
	spawn_wave(next_wave)
	wave_started.emit(next_wave)
