extends MainLoop


# Script to take a tilesheet and separate it into individual
# tiles.

#
# Examples:
# "foo.png" -> "foo-1.png", "foo-2.png"...

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/SeparateTilesheet.gd" -- foo.png

const ARG_COUNT: int = 1

const CELL_WIDTH: int = 128
const CELL_HEIGHT: int = 128


func _initialize():
	print("Begin")
	run()
	print("End")


func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	var arg_list: Array = OS.get_cmdline_user_args()

	print("Argument list: ", arg_list)

	print(arg_list)

	if arg_list.size() != ARG_COUNT:
		print("Incorrect args provided. Expected 1 args: path.")
		print(arg_list)

		return

	var path: String = arg_list[0]

	process_path(path)


func process_path(path: String):
	print("Processing path:", path)

	var original_image: Image = Image.load_from_file(path)
	var original_width: int = original_image.get_width()
	var original_height: int = original_image.get_height()
	var row_count: int = original_height / CELL_HEIGHT
	var column_count: int = original_width / CELL_WIDTH

	var tile_index: int = 0

	for column in range(0, column_count):
		for row in range(0, row_count):
			var result_image: = Image.create(CELL_WIDTH, CELL_HEIGHT, false, Image.FORMAT_RGBA8)

			var src_rect_pos: Vector2i = Vector2i(column * CELL_WIDTH, row * CELL_HEIGHT)
			var src_rect_size: Vector2i = Vector2i(CELL_WIDTH, CELL_HEIGHT)
			var src_rect: Rect2i = Rect2i(src_rect_pos, src_rect_size)
			var blit_dst: Vector2i = Vector2i(0, 0)
			result_image.blit_rect(original_image, src_rect, blit_dst)

			var result_path: String = path.replace(".png", "-%d.png" % tile_index)
			result_image.save_png(result_path)
			
			tile_index += 1
