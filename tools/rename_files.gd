extends MainLoop


# Renames all files in current directory according to a
# pattern.


const PLACEHOLDER_COLOR = Color.BLUE
const RESULT_FOLDER: String = "placeholders"


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
	print(" ")
	print("Processing dir %s." % [dir_path])

	var file_list: PackedStringArray = DirAccess.get_files_at(dir_path)
	var dir: DirAccess = DirAccess.open(dir_path)
	var remove_via_tmp_list: Array[String] = []
	for old_filename in file_list:
		var new_filename: String = old_filename.to_snake_case()

		var filename_length_changed: bool = new_filename.length() != old_filename.length()

		if filename_length_changed:
			print("Renaming %s->%s" % [old_filename, new_filename])
			dir.rename(old_filename, new_filename)
		else:
			remove_via_tmp_list.append(old_filename)

	if !remove_via_tmp_list.is_empty():
		print("\n \n \nSome files need to be renamed via git mv + tmp trick:")
		
		for filename in remove_via_tmp_list:
			print(filename)

	# var dir_list: Array = DirAccess.get_directories_at(dir_path)

	# for child_dir in dir_list:
	# 	var child_dir_path: String = "%s/%s" % [dir_path, child_dir]
	# 	process_dir(child_dir_path)
