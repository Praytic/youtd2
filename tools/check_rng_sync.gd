extends MainLoop


# Checks that all scripts use random functions via
# RandomNumberGenerator instance. This is to prevent desyncs
# because using random functions from global namespace
# causes desyncs.


const RESULT_FOLDER: String = "placeholders"

const GOOD_PREFIX: String = "rng."

const RANDOM_FUNC_LIST: Array = [
	[GOOD_PREFIX, "randf"],
	[GOOD_PREFIX, "randfn"],
	[GOOD_PREFIX, "randf_range"],
	[GOOD_PREFIX, "randf_range"],
	[GOOD_PREFIX, "randi"],
	[GOOD_PREFIX, "randi_range"],
#	NOTE: pick_random() and shuffle() are attached to Utils
#	because RandomNumberGenerator doesn't have these
#	functions
	["Utils.", "pick_random"],
	["Utils.", "shuffle"],
]


func _initialize():
	print("Begin")
	run()
	print("End")


func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	process_dir(".")


func process_dir(dir_path: String):
# 	Process files in current dir
	var file_list: PackedStringArray = DirAccess.get_files_at(dir_path)
	var dir: DirAccess = DirAccess.open(dir_path)
	for filename in file_list:
		var file_path: String = "%s/%s" % [dir_path, filename]
		process_file(file_path)

#	Process child dirs
	var dir_list: Array = DirAccess.get_directories_at(dir_path)

	for child_dir in dir_list:
		var child_dir_path: String = "%s/%s" % [dir_path, child_dir]
		process_dir(child_dir_path)


func process_file(file_path: String):
	var file_is_script: bool = file_path.ends_with(".gd")

	if !file_is_script:
		return

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var content: String = file.get_as_text()

	var misused_func_list: Array[String] = []

	for element in RANDOM_FUNC_LIST:
		var good_prefix: String = element[0]
		var function: String = element[1]
		
		var func_without_prefix: String = "%s(" % [function]
		var func_with_prefix: String = "%s%s(" % [good_prefix, function]
		var all_func_count: int = content.count(func_without_prefix)
		var good_prefix_count: int = content.count(func_with_prefix)

		var func_was_used_with_good_prefixes: bool = all_func_count == good_prefix_count

		if !func_was_used_with_good_prefixes:
			misused_func_list.append(function)

	if !misused_func_list.is_empty():
		print("!!! Issue found in file %s" % file_path)
		print("Misused functions: ", misused_func_list)

	return content
