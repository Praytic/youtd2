extends MainLoop


# Cuts all single tiles in current directory to look like
# they are behind a floor2 tile. Creates two "left" and
# "right" versions. Note that this script assumes that the
# cut tiles will be placed above brick tiles. There will be
# a gap if you place these tiles above dirt tiles.
# 
# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/CutSingleTile.gd"

const ARG_COUNT: int = 0
const PNG_SUFFIX: String = ".png"
const LEFT_SUFFIX: String = "-cut-left.png"
const RIGHT_SUFFIX: String = "-cut-right.png"

const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 512

const left_section: PackedVector2Array = [Vector2(0, 449), Vector2(256, 319), Vector2(256, 0), Vector2(0, 0)]
const right_section: PackedVector2Array = [Vector2(0, 319), Vector2(256, 449), Vector2(256, 0), Vector2(0, 0)]


func _initialize():
	print("Begin")
	run()
	print("End")


# NOTE: returning true from _process() is the only way to
# quit from MainLoop.
func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	var arg_list: Array = OS.get_cmdline_user_args()

	print("Argument list: ", arg_list)

	if arg_list.size() != ARG_COUNT:
		print("Incorrect args provided. Expected 0 args.")
		print(arg_list)

		return

	process_current_dir()


func process_current_dir():
	var current_dir: DirAccess = DirAccess.open(".")
	var current_dir_path: String = current_dir.get_current_dir()
	var filename_list: Array = current_dir.get_files()

	var results_dir_path: String = "%s/results" % current_dir_path
	DirAccess.make_dir_absolute(results_dir_path)

	for filename in filename_list:
		var file_is_png: bool = filename.ends_with(PNG_SUFFIX)

		if file_is_png:
			process_file(results_dir_path, filename)


func process_file(results_dir_path: String, filename: String):
	print("Processing file:", filename)

	var original_image: Image = Image.load_from_file(filename)
	var left_result_image: = Image.create(original_image.get_width(), original_image.get_height(), false, Image.FORMAT_RGBA8)
	var right_result_image: = Image.create(original_image.get_width(), original_image.get_height(), false, Image.FORMAT_RGBA8)

	for cell_x in range(0, CELL_WIDTH):
		for cell_y in range(0, CELL_HEIGHT):
			var cell_pos: Vector2 = Vector2(cell_x, cell_y)
			var pixel: Color = original_image.get_pixel(cell_x, cell_y)

			var is_part_of_left: bool = need_to_copy_pixel(cell_pos, left_section)
			var is_part_of_right: bool = need_to_copy_pixel(cell_pos, right_section)

			if is_part_of_left:
				left_result_image.set_pixel(cell_x, cell_y, pixel)
			if is_part_of_right:
				right_result_image.set_pixel(cell_x, cell_y, pixel)

	var left_result_path: String = "%s/%s" % [results_dir_path, filename]
	left_result_path = left_result_path.replace(PNG_SUFFIX, LEFT_SUFFIX)
	left_result_image.save_png(left_result_path)

	var right_result_path: String = "%s/%s" % [results_dir_path, filename]
	right_result_path = right_result_path.replace(PNG_SUFFIX, RIGHT_SUFFIX)
	right_result_image.save_png(right_result_path)


func need_to_copy_pixel(pos: Vector2, polygon: PackedVector2Array):
	var pixel_is_in_poly: bool = Geometry2D.is_point_in_polygon(pos, polygon)
	
	return pixel_is_in_poly
