class_name WaveSpawner extends Node


var _wave_list: Array[Wave] = []
var _current_wave: Wave = null

@export var _creep_spawner: CreepSpawner


#########################
###       Public      ###
#########################

func generate_waves(wave_count: int, difficulty: Difficulty.enm):
	for wave_level in range(1, wave_count + 1):
		var wave: Wave = Wave.new(wave_level, difficulty)
		
		var creep_combination_string: String = wave.get_creep_combination_string()
		print_verbose("Wave [%s] will have creeps [%s] of race [%s] and armor type [%s]" \
			% [wave_level, \
				creep_combination_string, \
				CreepCategory.convert_to_string(wave.get_race()), \
				ArmorType.convert_to_string(wave.get_armor_type())])
		
		var special_name_list: Array[String] = []
		for special in wave.get_specials():
			var special_name: String = WaveSpecialProperties.get_special_name(special)
			special_name_list.append(special_name)

		var specials_string: String
		if !special_name_list.is_empty():
			specials_string = ",".join(special_name_list)
		else:
			specials_string = "none"

		print_verbose("    Specials: %s" % specials_string)
		_print_creep_hp_overall(wave)
		
		_wave_list.append(wave)
		
		add_child(wave, true)

	_creep_spawner.setup_background_load_queue(_wave_list)
	
	print_verbose("Waves have been initialized. Total waves: %s" % _wave_list.size())


func start_wave(level: int):
	var wave: Wave = get_wave(level)
	
	if wave == null:
		push_error("Failed to start wave #%d because it's null" % level)
		
		return
	
	wave.state = Wave.State.SPAWNING

	_current_wave = wave

	var creep_data_list: Array[CreepData] = WaveSpawner._generate_creep_data_list(wave)

	for creep_data in creep_data_list:
		_creep_spawner.queue_spawn_creep(creep_data)
	
	_add_message_about_wave(wave)
	
	print_verbose("Wave has started [%s]." % wave)


# NOTE: wave is considered in progress if it's spawning
# creeps. If it has finished spawning creeps but creeps are
# still alive, the wave is considered to not be in progress.
func wave_is_in_progress() -> bool:
	if _current_wave == null:
		return false

	var in_progress: bool = _current_wave.state == Wave.State.SPAWNING

	return in_progress


#########################
###      Private      ###
#########################

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
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var description: String = WaveSpecialProperties.get_description(special)
		var special_string: String = "[color=BLUE]%s[/color] - %s" % [special_name, description]

		Messages.add_normal(special_string)


func _print_creep_hp_overall(wave: Wave):
	var creep_size_list: Array = wave.get_creep_sizes()

	for creep_size in creep_size_list:
		var creep_health: float = CreepSpawner.get_creep_health(wave, creep_size)
		var creep_size_string: String = CreepSize.convert_to_string(creep_size)
		print_verbose("%s's HP: %s" % [creep_size_string, creep_health])


#########################
###     Callbacks     ###
#########################

func _on_CreepSpawner_all_creeps_spawned():
	if _current_wave == null:
		return

	_current_wave.state = Wave.State.SPAWNED
	print_verbose("Wave has been spawned [%s]." % _current_wave)


#########################
### Setters / Getters ###
#########################

func get_wave(level: int) -> Wave:
	var index: int = level - 1

	var in_bounds: bool = 0 <= index && index < _wave_list.size()

	if in_bounds:
		var wave: Wave = _wave_list[index]

		return wave
	else:
		return null


#########################
###       Static      ###
#########################

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
