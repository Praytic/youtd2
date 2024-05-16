extends MainLoop


# Checks which buff icons do not point to existing assets.


const SET_BUFF_ICON_FUNC: String = ".set_buff_icon("


func _initialize():
	print("Begin")
	run()
	print("End")


func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	print(" \n")
	print("List of files which use invalid buff icons:")
	print(" \n")

	process_dir("res://Scenes")


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

	var find_index: int = 0

	while true:
		var find_result: int = content.find(SET_BUFF_ICON_FUNC, find_index)

		if find_result == -1:
			break

		var opening_bracket_index: int = content.find("(", find_result)
		var closing_bracket_index: int = content.find(")", find_result)

		var buff_icon_path: String = content.substr(opening_bracket_index + 1, closing_bracket_index - opening_bracket_index - 1)
		buff_icon_path = buff_icon_path.replace("\"", "")

		var script_uses_valid_buff_icon: bool = ResourceLoader.exists(buff_icon_path)

		if !script_uses_valid_buff_icon:
			print("%s => %s" % [file_path, buff_icon_path])

		find_index = closing_bracket_index
