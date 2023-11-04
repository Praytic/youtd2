extends MainLoop


# This script takes individual tiles from current folder and
# combines them into a tilesheet.
#
# Takes one arg which should be the beginning of filenames to process
#
# Example: if you pass "Barrel", then script will process all files which start with "Barrel"
# And save result to "Barrel-combined.png"
#
# Input tiles must be 256x512
# Output will have margins of 4 around tiles.
# Output will have 8 rows.

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/CreateTilesheet.gd"

const ARG_COUNT: int = 1

const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 512
const MARGIN: int = 4
const CELL_WIDTH_WITH_MARGIN: int = CELL_WIDTH + MARGIN * 2
const CELL_HEIGHT_WITH_MARGIN: int = CELL_HEIGHT + MARGIN * 2
const RESULT_COLUMN_COUNT: int = 8


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

	print(arg_list)

	if arg_list.size() != ARG_COUNT:
		print("Incorrect args provided. Expected 1 arg, the beginning of filenames to process")

		return

	var filename_beginning: String = arg_list[0]

	process(filename_beginning)


func process(filename_beginning: String):
	var filename_list: Array = get_filename_list(filename_beginning)

	if filename_list.is_empty():
		push_error("No files found")

		return

	var file_count: int = filename_list.size()
	var result_column_count: int = RESULT_COLUMN_COUNT
	var result_row_count: int = ceil(float(file_count) / RESULT_COLUMN_COUNT)
	var result_width: int = result_column_count * CELL_WIDTH_WITH_MARGIN
	var result_height: int = result_row_count * CELL_HEIGHT_WITH_MARGIN

	var tilesheet_image: = Image.create(result_width, result_height, false, Image.FORMAT_RGBA8)

	for i in range(0, filename_list.size()):
		var filename: String = filename_list[i]
		var tile_image: Image = Image.load_from_file(filename)
		
		var current_column: int = i % result_column_count
		var current_row: int = i / result_column_count
		var src_rect_pos: Vector2i = Vector2i(0, 0)
		var src_rect_size: Vector2i = Vector2i(CELL_WIDTH, CELL_HEIGHT)
		var src_rect: Rect2i = Rect2i(src_rect_pos, src_rect_size)
		var blit_dst: Vector2i = Vector2i(current_column * CELL_WIDTH_WITH_MARGIN + MARGIN, current_row * CELL_HEIGHT_WITH_MARGIN + MARGIN)
		tilesheet_image.blit_rect(tile_image, src_rect, blit_dst)

	var result_path: String = "%s-combined.png" % filename_beginning
	tilesheet_image.save_png(result_path)


func get_filename_list(filename_beginning: String) -> Array[String]:
	var result: Array[String] = []

	var current_dir: DirAccess = DirAccess.open(".")
	var filename_list: Array = current_dir.get_files()

	for filename in filename_list:
		var filename_ok: bool = filename.begins_with(filename_beginning)

		if filename_ok:
			result.append(filename)

	return result
