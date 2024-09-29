extends MainLoop


# Checks that all scripts use valid .tscn paths.


var tscn_path_list: Array = []
var tscn_regex: RegEx


func _initialize():	
	print("Begin")
	run()
	print("End")


func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	tscn_regex = RegEx.new()
	tscn_regex.compile("\"[^\"]*.tscn\"")

	tscn_path_list = generate_tscn_path_list()

	check_scripts_in_dir(".")


func generate_tscn_path_list() -> Array[String]:
	var result: Array[String] = []
	
	generate_tscn_path_list_helper(".", result)
	
	return result


func generate_tscn_path_list_helper(dir_path: String, result: Array[String]):
# 	Process files in current dir
	var file_list: PackedStringArray = DirAccess.get_files_at(dir_path)
	var dir: DirAccess = DirAccess.open(dir_path)
	for filename in file_list:
		var file_path: String = "%s/%s" % [dir_path, filename]
		var file_extension: String = file_path.get_extension()
		var file_is_tscn: bool = file_extension == "tscn"

		if file_is_tscn:
			var file_path_via_res: String = file_path.replace("./src/", "res://src/")
			result.append(file_path_via_res)

#	Process child dirs
	var dir_list: Array = DirAccess.get_directories_at(dir_path)

	for child_dir in dir_list:
		var child_dir_path: String = "%s/%s" % [dir_path, child_dir]
		generate_tscn_path_list_helper(child_dir_path, result)


func check_scripts_in_dir(dir_path: String):
# 	Process files in current dir
	var file_list: PackedStringArray = DirAccess.get_files_at(dir_path)
	var dir: DirAccess = DirAccess.open(dir_path)
	for filename in file_list:
		var file_path: String = "%s/%s" % [dir_path, filename]
		var file_extension: String = file_path.get_extension()
		var file_is_gd: bool = file_extension == "gd"

		if file_is_gd:
			check_script_file(file_path)

#	Process child dirs
	var dir_list: Array = DirAccess.get_directories_at(dir_path)

	for child_dir in dir_list:
		var child_dir_path: String = "%s/%s" % [dir_path, child_dir]
		check_scripts_in_dir(child_dir_path)


func check_script_file(file_path: String):
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var content: String = file.get_as_text()

	var regex_match_list: Array[RegExMatch] = tscn_regex.search_all(content)

	for regex_match in regex_match_list:
		var tscn_path: String = regex_match.get_string().replace("\"", "")
		var path_is_valid: bool = tscn_path_list.has(tscn_path)

		if !path_is_valid:
			print("Found invalid tscn path in script! Path: %s, script: %s." % [tscn_path, file_path])
