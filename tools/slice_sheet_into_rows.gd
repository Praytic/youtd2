extends MainLoop


# Script to take an image and slice it into slices. Each
# slice is named with "original_name-N.png". Use this to
# break down very large tilesheets into multiple smaller
# tilesheets.

#
# Examples:
# "foo.png" -> "foo-1.png", "foo-2.png"...

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/SliceSheetIntoRows.gd" -- foo.png 6

const ARG_COUNT: int = 2

const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 512
const MARGIN: int = 0
const CELL_WIDTH_WITH_MARGIN: int = CELL_WIDTH + MARGIN * 2
const CELL_HEIGHT_WITH_MARGIN: int = CELL_HEIGHT + MARGIN * 2


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
		print("Incorrect args provided. Expected 2 args: path and row count per slice.")
		print(arg_list)

		return

	var path: String = arg_list[0]
	var row_count: int = arg_list[1].to_int()

	process_path(path, row_count)


func process_path(path: String, row_count: int):
	print("Processing path:", path)

	var original_image: Image = Image.load_from_file(path)
	var original_width: int = original_image.get_width()
	var original_height: int = original_image.get_height()
	var slice_height: int = row_count * CELL_HEIGHT_WITH_MARGIN
	var slice_count: int = ceil(float(original_height) / slice_height)
	
	if slice_height > original_height:
		push_error("Row count arg is larger than row count in original image.")

		return

	print("Slice count will be:", slice_count)

	for i in range(0, slice_count):
		var result_image: = Image.create(original_width, slice_height, false, Image.FORMAT_RGBA8)

		var src_rect_pos: Vector2i = Vector2i(0, i * slice_height)
		var src_rect_size: Vector2i = Vector2i(original_width, slice_height)
		var src_rect: Rect2i = Rect2i(src_rect_pos, src_rect_size)
		var blit_dst: Vector2i = Vector2i(0, 0)
		result_image.blit_rect(original_image, src_rect, blit_dst)

		var result_path: String = path.replace(".png", "-%d.png" % i)
		result_image.save_png(result_path)
