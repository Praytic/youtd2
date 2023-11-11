extends MainLoop


# Script to take real assets in current directory and turn
# them into placeholder assets. Replaces all non-transparent
# original pixels with a solid color.
# Writes results into a folder called "placeholders".

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/GeneratePlaceholderAssets.gd"

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
	if dir_path.ends_with(RESULT_FOLDER):
		return
	
	generate_placeholder_assets(dir_path)

	var dir_list: Array = DirAccess.get_directories_at(dir_path)

	for child_dir in dir_list:
		var child_dir_path: String = "%s/%s" % [dir_path, child_dir]
		process_dir(child_dir_path)


func generate_placeholder_assets(dir_path: String):
	print(" \n")
	print("Processing dir %s." % [dir_path])
	
	var result_folder: String = "%s/%s" % [dir_path, RESULT_FOLDER]
	DirAccess.make_dir_absolute(result_folder)

	var file_list: PackedStringArray = DirAccess.get_files_at(dir_path)

	for file_name in file_list:
		var is_png: bool = file_name.ends_with(".png")

		if !is_png:
			continue

		var file_path: String = "%s/%s" % [dir_path, file_name]

		process_file(file_path, file_name, result_folder)


func process_file(file_path: String, file_name: String, result_folder: String):
	print("Processing file %s." % [file_path])

	var original_image: Image = Image.load_from_file(file_path)
	var width: float = original_image.get_width()
	var height: float = original_image.get_height()
	var result_image: = Image.create(width, height, false, Image.FORMAT_RGBA8)

	for x in range(0, width):
		for y in range(0, height):
			var original_pixel: Color = original_image.get_pixel(x, y)
			var pixel_is_set: bool = original_pixel.a != 0

			if pixel_is_set:
				result_image.set_pixel(x, y, PLACEHOLDER_COLOR)
	
	var result_path: String = "%s/%s" % [result_folder, file_name]
	result_image.save_png(result_path)
