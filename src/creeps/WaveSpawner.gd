class_name WaveSpawner extends Node


signal wave_finished(level: int)


var _wave_list: Array[Wave] = []
var _current_wave: Wave = null
var _player: Player = null

@export var _creep_spawner: CreepSpawner


#########################
###       Public      ###
#########################


func set_player(player: Player):
	_player = player
	_creep_spawner.set_player(player)


func generate_waves():
	var wave_count: int = Globals.get_wave_count()
	var difficulty: Difficulty.enm = Globals.get_difficulty()
	
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
		
		wave.finished.connect(_on_wave_finished.bind(wave))
		
		add_child(wave, true)

	print_verbose("Waves have been initialized. Total waves: %s" % _wave_list.size())


func start_wave(level: int):
	var wave: Wave = get_wave(level)
	
	if wave == null:
		push_error("Failed to start wave #%d because it's null" % level)
		
		return
	
	wave.state = Wave.State.SPAWNING

	_current_wave = wave

	_creep_spawner.start_spawning_wave(wave)
	
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


func current_wave_is_finished() -> bool:
	if _current_wave == null:
		return true

	var is_finished: bool = _current_wave.state == Wave.State.FINISHED

	return is_finished


#########################
###      Private      ###
#########################

func _add_message_about_wave(wave: Wave):
	if _player != PlayerManager.get_local_player():
		return
	
	var combination_string: String = wave.get_creep_combination_string()

	var creep_race: CreepCategory.enm = wave.get_race()
	var race_string: String = CreepCategory.convert_to_colored_string(creep_race)

	var creep_armor: ArmorType.enm = wave.get_armor_type()
	var armor_string: String = ArmorType.convert_to_colored_string(creep_armor)

	Messages.add_normal(_player, "[color=GOLD]=== LEVEL %s ===[/color]" % wave.get_level())
	Messages.add_normal(_player, "%s (Race: %s, Armor: %s)" % [combination_string, race_string, armor_string])

	var special_list: Array[int] = wave.get_specials()

	for special in special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var description: String = WaveSpecialProperties.get_description(special)
		var special_string: String = "[color=BLUE]%s[/color] - %s" % [special_name, description]

		Messages.add_normal(_player, special_string)


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


func _on_wave_finished(wave: Wave):
	var game_over: bool = _player.get_team().is_game_over()
	if game_over:
		return

	var level: int = wave.get_level()
	wave_finished.emit(level)


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
