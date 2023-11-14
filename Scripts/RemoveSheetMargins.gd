class_name RemoveSheetMargins extends MainLoop


# Takes a tilesheet and removes margins from it.
# Overwrites original file.

# How to use:
# "path/to/godot-console.exe" -s "path/to/RemoveSheetMargins.gd" -- "sheet.png"
# Example:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/RemoveSheetMargins.gd" -- "floor.png"


const ARG_COUNT: int = 1

const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 512
const MARGIN: int = 4
const CELL_WIDTH_WITH_MARGIN: int = CELL_WIDTH + MARGIN * 2
const CELL_HEIGHT_WITH_MARGIN: int = CELL_HEIGHT + MARGIN * 2


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

	if arg_list.size() != ARG_COUNT:
		print("Incorrect args provided. Expected args: sheet.")

		return

	var sheet_path: String = arg_list[0]

	process_sheet(sheet_path)


func process_sheet(sheet_path: String):
	print("Processing sheet:", sheet_path)

	var original_sheet: Image = Image.load_from_file(sheet_path)
	var original_size: Vector2 = Vector2(CELL_WIDTH_WITH_MARGIN, CELL_HEIGHT_WITH_MARGIN)
	var modified_size: Vector2 = Vector2(CELL_WIDTH, CELL_HEIGHT)
	var row_count: int = floori(float(original_sheet.get_height()) / original_size.y)
	var column_count: int = floori(float(original_sheet.get_width()) / original_size.x)
	var modified_sheet: Image = Image.create(modified_size.x * column_count, modified_size.y * row_count, false, Image.FORMAT_RGBA8)

	for row in range(0, row_count):
		for col in range(0, column_count):
			var original_frame_pos: Vector2i = Vector2i(col * original_size.x + MARGIN, row * original_size.y + MARGIN)
			var modified_frame_pos: Vector2i = Vector2i(col * modified_size.x, row * modified_size.y)
			var src_rect_pos: Vector2i = original_frame_pos
			var src_rect_size: Vector2i = Vector2i(CELL_WIDTH, CELL_HEIGHT)
			var src_rect: Rect2i = Rect2i(src_rect_pos, src_rect_size)
			var blit_dst: Vector2i = modified_frame_pos

			modified_sheet.blit_rect(original_sheet, src_rect, blit_dst)

	modified_sheet.save_png(sheet_path)
