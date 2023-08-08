class_name WaveSpawner extends Node


var TIME_BEFORE_FIRST_WAVE: float = 120.0
var TIME_BETWEEN_WAVES: float = 15.0


signal all_waves_started
signal all_waves_cleared
signal generated_all_waves


var _wave_list: Array[Wave] = []


@onready var _timer_between_waves: Timer = $Timer
@onready var _creep_spawner = $CreepSpawner

func _ready():
	if Config.fast_waves_enabled():
		TIME_BETWEEN_WAVES = 0.1

	_timer_between_waves.set_autostart(false)


func generate_waves(wave_count: int, difficulty: Difficulty.enm):
	for wave_level in range(1, wave_count + 1):
		var wave: Wave = Wave.new(wave_level, difficulty)
		
		var creep_combination_string: String = wave.get_creep_combination_string()
		print_verbose("Wave [%s] will have creeps [%s] of race [%s] and armor type [%s]" \
			% [wave_level, \
				creep_combination_string, \
				CreepCategory.convert_to_string(wave.get_race()), \
				ArmorType.convert_to_string(wave.get_armor_type())])
		
		wave.add_to_group("wave")

		_wave_list.append(wave)
		
		wave.finished.connect(_on_wave_finished.bind(wave))
 
		add_child(wave, true)

	_creep_spawner.setup_background_load_queue(_wave_list)
	
	print_verbose("Waves have been initialized. Total waves: %s" % get_waves().size())

	generated_all_waves.emit()


func start_initial_timer():
	_timer_between_waves.start(TIME_BEFORE_FIRST_WAVE)


func _on_Timer_timeout():
	_start_next_wave()


func _start_next_wave():
	WaveLevel.increase()

	var current_wave: Wave = get_current_wave()
	current_wave.state = Wave.State.SPAWNING

	var creep_data_list: Array[CreepData] = WaveSpawner._generate_creep_data_list(current_wave)

	for creep_data in creep_data_list:
		_creep_spawner.queue_spawn_creep(creep_data)
	
	_add_message_about_wave(current_wave)
	
	print_verbose("Wave has started [%s]." % current_wave)

	if _last_wave_was_started():
		all_waves_started.emit()


func _on_CreepSpawner_all_creeps_spawned():
	var current_wave = get_current_wave()
	current_wave.state = Wave.State.SPAWNED
	print_verbose("Wave has been spawned [%s]." % current_wave)


func get_current_wave() -> Wave:
	var current_level: int = WaveLevel.get_current()
	var current_wave: Wave = get_wave(current_level)

	return current_wave


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
	var before_first_wave: bool = WaveLevel.get_current() == 0
	var current_wave_finished_spawning: bool = current_wave != null && current_wave.state != Wave.State.SPAWNING
	var can_start_next_wave: bool = !_last_wave_was_started() && (before_first_wave || current_wave_finished_spawning)

	if can_start_next_wave:
		_timer_between_waves.stop()
		_start_next_wave()

		return true
	else:
		return false


func _on_wave_finished(wave: Wave):
	print_verbose("Wave [%s] is finished." % wave)

	Messages.add_normal("=== Level [color=GOLD]%d[/color] completed! ===" % wave.get_level())

	var wave_level: int = wave.get_level()
	GoldControl.add_income(wave_level)
	KnowledgeTomesManager.add_knowledge_tomes()

	var any_wave_is_active: bool = false

	for this_wave in _wave_list:
		if this_wave.state == Wave.State.SPAWNING || this_wave.state == Wave.State.SPAWNED:
			any_wave_is_active = true

			break

	if !any_wave_is_active:
		if _last_wave_was_started():
			all_waves_cleared.emit()
		else:
			_timer_between_waves.start(TIME_BETWEEN_WAVES)


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


func _last_wave_was_started() -> bool:
	var wave_index: int = WaveLevel.get_current() - 1
	var after_last_wave: bool = wave_index >= _wave_list.size()

	return after_last_wave
