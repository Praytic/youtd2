extends MainLoop


# Renames all files in current directory according to a
# pattern.

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/RenameFiles.gd"

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
	for old_filename in file_list:
		var new_filename: String = old_filename.replace("-combined", "-cut")
		dir.rename(old_filename, new_filename)

	var dir_list: Array = DirAccess.get_directories_at(dir_path)

	for child_dir in dir_list:
		var child_dir_path: String = "%s/%s" % [dir_path, child_dir]
		process_dir(child_dir_path)
