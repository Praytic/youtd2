extends MainLoop


# This script generates censored assets to be placed in
# public assets shared folder. This censoring is necessary
# because some assets have licenses which do not allow
# redistribution.
# 
# Processes all files in current directory and saves results
# into a new "censored assets" folder.
# 
# Placeholder assets are "censored" by replacing all
# original pixels with one color and applying extra
# distortion so that the asset is unrecognizable from the
# original.


const ARG_COUNT: int = 1

const PLACEHOLDER_COLOR = Color(Color.GRAY, 0.6)
const RESULT_FOLDER: String = "censored assets"
const DISTORTION_STRENGTH: int = 15


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
	var result_image: Image = generate_placeholder_image(original_image)
	var result_path: String = "%s/%s" % [result_folder, file_name]
	result_image.save_png(result_path)


func generate_placeholder_image(original_image: Image) -> Image:
	var width: float = original_image.get_width()
	var height: float = original_image.get_height()
	var result_image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(width, height) / 2

	var time_since_last_pixel: int = 100

	for x in range(0, width):
		for y in range(0, height):
			var original_pixel: Color = original_image.get_pixel(x, y)
			var pixel_is_set: bool = original_pixel.a != 0

			if pixel_is_set:
				time_since_last_pixel = 0
			else:
				time_since_last_pixel += 1

			if time_since_last_pixel < DISTORTION_STRENGTH:
				result_image.set_pixel(x, y, PLACEHOLDER_COLOR)

	return result_image
