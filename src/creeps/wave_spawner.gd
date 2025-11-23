class_name WaveSpawner extends Node


signal wave_spawned(level: int)
signal wave_finished(level: int)


var _wave_list: Array[Wave] = []
var _current_wave: Wave = null
var _player: Player = null

@export var _creep_spawner: CreepSpawner


#########################
###       Public      ###
#########################

func get_wave(level: int) -> Wave:
	var index: int = level - 1

	var in_bounds: bool = 0 <= index && index < _wave_list.size()

	if in_bounds:
		var wave: Wave = _wave_list[index]

		return wave
	else:
		return null


func set_player(player: Player):
	_player = player
	_creep_spawner.set_player(player)


func generate_waves():
	var wave_count: int = Globals.get_wave_count()
	_generate_waves_for_level_range(1, wave_count)


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


func current_wave_is_finished() -> bool:
	if _current_wave == null:
		return true

	var is_finished: bool = _current_wave.state == Wave.State.FINISHED

	return is_finished


func wave_is_finished(level: int) -> bool:
	var wave: Wave = get_wave(level)

	if wave == null:
		return false

	var is_finished: bool = wave.state == Wave.State.FINISHED

	return is_finished


#########################
###      Private      ###
#########################

func _generate_waves_for_level_range(level_start: int, wave_count: int):
	var difficulty: Difficulty.enm = Globals.get_difficulty()

	for wave_level in range(level_start, level_start + wave_count):
		var wave: Wave = Wave.new(wave_level, difficulty)
		_wave_list.append(wave)
		wave.finished.connect(_on_wave_finished.bind(wave))
		add_child(wave, true)

	var should_print_wave_info: bool = Config.print_wave_info()
	if should_print_wave_info:
		_print_wave_info()


func _print_wave_info():
	for wave in _wave_list:
		var wave_level: int = wave.get_level()
		var creep_combination_string: String = wave.get_creep_combination_string()

		var special_name_list: Array[String] = []
		for special in wave.get_specials():
			var special_name: String = WaveSpecialProperties.get_special_name(special)
			special_name_list.append(special_name)

		var specials_string: String
		if !special_name_list.is_empty():
			specials_string = ",".join(special_name_list)
		else:
			specials_string = "none"

		print("Wave [%s] will have creeps [%s] of race [%s] and armor type [%s]" % [wave_level, creep_combination_string, CreepCategory.get_display_string(wave.get_race()), ArmorType.get_display_string(wave.get_armor_type())])
		print("    Specials: %s" % specials_string)

		var creep_size_list: Array = wave.get_creep_sizes()

		for creep_size in creep_size_list:
			var creep_health: float = CreepSpawner.get_creep_health(wave, creep_size)
			var creep_size_string: String = CreepSize.get_display_string(creep_size)
			print("%s's HP: %s" % [creep_size_string, creep_health])

#		NOTE: need to add delay between prints to avoid
#		overflowing the console. Console overflow is not
#		critical but it does cut off the messages.
		if wave_level % 20 == 0:
			await get_tree().create_timer(0.1).timeout


func _add_message_about_wave(wave: Wave):
	if _player != PlayerManager.get_local_player():
		return
	
	var combination_string: String = wave.get_creep_combination_string()

	var creep_race: CreepCategory.enm = wave.get_race()
	var race_string: String = CreepCategory.convert_to_colored_string(creep_race)

	var creep_armor: ArmorType.enm = wave.get_armor_type()
	var armor_string: String = ArmorType.convert_to_colored_string(creep_armor)

	var wave_level: int = wave.get_level()
	var wave_is_bonus: int = Utils.wave_is_bonus(wave_level)
	var wave_header_text: String
	if !wave_is_bonus:
		wave_header_text = tr("MESSAGE_WAVE_LEVEL").format({LEVEL = wave_level})
	else:
		wave_header_text = tr("MESSAGE_WAVE_LEVEL_BONUS").format({LEVEL = wave_level})

	Messages.add_normal(_player, wave_header_text)
	Messages.add_normal(_player, tr("MESSAGE_WAVE_PROPS").format({CREEP_COMBINATION = combination_string, RACE = race_string, ARMOR = armor_string}))

	var special_list: Array[int] = wave.get_specials()

	for special in special_list:
		var special_name: String = WaveSpecialProperties.get_special_name(special)
		var description: String = WaveSpecialProperties.get_description(special)
		var special_string: String = "[color=BLUE]%s[/color] - %s" % [special_name, description]

		Messages.add_normal(_player, special_string)


#########################
###     Callbacks     ###
#########################

func _on_creep_spawner_all_creeps_spawned():
	if _current_wave == null:
		return

	_current_wave.state = Wave.State.SPAWNED
	var level: int = _current_wave.get_level()
	wave_spawned.emit(level)
	print_verbose("Wave has been spawned [%s]." % _current_wave)


func _on_wave_finished(wave: Wave):
	var team: Team = _player.get_team()
	var finished_the_game: bool = team.finished_the_game()
	if finished_the_game:
		return

	var level: int = wave.get_level()
	wave_finished.emit(level)

# 	Keep generating extra waves in neverending mode
	var game_is_neverending: bool = Globals.game_is_neverending()
	if game_is_neverending:
		var last_generated_level: int = _wave_list.back().get_level()
		var distance_to_last_generated_wave: int = last_generated_level - level

		if distance_to_last_generated_wave < 20:
			_generate_waves_for_level_range(last_generated_level + 1, 20)
