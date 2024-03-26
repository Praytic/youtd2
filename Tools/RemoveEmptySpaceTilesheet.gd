class_name RemoveEmptySpaceTilesheet extends MainLoop


# Takes a sprite sheet and removes empty space from it. Only
# removes empty space above tiles and removes equal amounts
# from all tiles.

# This script will also print the modified tile sizes and
# texture origins, which you should input into the tileset
# editor.

# NOTE: the minimum result tile height is 128, so that tile
# is usable in tilesets.

# How to use:
# "path/to/godot-console.exe" -s "path/to/RemoveEmptySpaceTilesheet.gd" -- "path/to/sheets-folder"
# Example:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/RemoveEmptySpaceTilesheet.gd" -- "."


const ARG_COUNT: int = 1

const MIN_HEIGHT: int = 128
const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 512
const MARGIN: int = 0
const CELL_WIDTH_WITH_MARGIN: int = CELL_WIDTH + MARGIN * 2
const CELL_HEIGHT_WITH_MARGIN: int = CELL_HEIGHT + MARGIN * 2
const RESULT_FOLDER: String = "results"


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
		print("Incorrect args provided. Expected args: sheet dir.")

		return

	var sheets_dir: String = arg_list[0]

	process_dir(sheets_dir)


func process_dir(dir_path: String):
	if dir_path.ends_with(RESULT_FOLDER):
		return

	process_files_in_dir(dir_path)

	var dir_list: Array = DirAccess.get_directories_at(dir_path)

	for child_dir in dir_list:
		var child_dir_path: String = "%s/%s" % [dir_path, child_dir]
		process_dir(child_dir_path)


func process_files_in_dir(dir_path: String):
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
	print(" ")
	print("Processing sheet:", file_path)

	var empty_height: int = calculate_empty_height(file_path)

	var original_sheet: Image = Image.load_from_file(file_path)
	var original_size: Vector2 = Vector2(CELL_WIDTH_WITH_MARGIN, CELL_HEIGHT_WITH_MARGIN)
	var modified_size: Vector2 = Vector2(CELL_WIDTH_WITH_MARGIN, CELL_HEIGHT_WITH_MARGIN - empty_height)
	var row_count: int = int(float(original_sheet.get_height()) / original_size.y)
	var column_count: int = int(float(original_sheet.get_width()) / original_size.x)
	var modified_sheet: Image = Image.create(modified_size.x * column_count, modified_size.y * row_count, false, Image.FORMAT_RGBA8)

	var original_size_without_margins: Vector2 = Vector2(CELL_WIDTH, CELL_HEIGHT)
	var modified_size_without_margins: Vector2 = Vector2(CELL_WIDTH, CELL_HEIGHT - empty_height)
	print("Original size: ", original_size_without_margins)
	print("Modified size: ", modified_size_without_margins)
	print("Modified texture origin Y: ", (modified_size_without_margins.y - 64) - modified_size_without_margins.y / 2)

#	Cut part of the original tile, without the empty space
#	above. Past it into modified tilesheet.
	for row in range(0, row_count):
		for col in range(0, column_count):
			var original_frame_pos: Vector2i = Vector2i(col * original_size.x + MARGIN, row * original_size.y + MARGIN)
			var modified_frame_pos: Vector2i = Vector2i(col * modified_size.x + MARGIN, row * modified_size.y + MARGIN)
			var src_rect_pos: Vector2i = original_frame_pos + Vector2i(0, empty_height)
			var src_rect_size: Vector2i = Vector2i(CELL_WIDTH, CELL_HEIGHT - empty_height)
			var src_rect: Rect2i = Rect2i(src_rect_pos, src_rect_size)
			var blit_dst: Vector2i = modified_frame_pos

			modified_sheet.blit_rect(original_sheet, src_rect, blit_dst)

	var result_path: String = "%s/%s" % [result_folder, file_name]
	modified_sheet.save_png(result_path)


func calculate_empty_height(file_path: String) -> int:
	var sheet: Image = Image.load_from_file(file_path)
	var max_used_rect: Rect2i = get_max_used_rect(sheet)
	var empty_height: int = max_used_rect.position.y

#	NOTE: only return even heights so that texture origin Y
#	is a whole number
	if empty_height % 2 != 0:
		empty_height -= 1

	if CELL_HEIGHT - empty_height < MIN_HEIGHT:
		empty_height = CELL_HEIGHT - MIN_HEIGHT

	return empty_height


# Calculate a rect that fits all sprites in the sprite sheet
func get_max_used_rect(sheet_image: Image) -> Rect2i:
	var sheet_texture: ImageTexture = ImageTexture.create_from_image(sheet_image)
	
	var original_size: Vector2 = Vector2(CELL_WIDTH_WITH_MARGIN, CELL_HEIGHT_WITH_MARGIN)
	var row_count: int = int(float(sheet_image.get_height()) / original_size.y)
	var column_count: int = int(float(sheet_image.get_width()) / original_size.x)
	
	var max_used_rect: Rect2i = Rect2i()
	var first_rect: bool = true

	for row in range(0, row_count):
		for col in range(0, column_count):
			var used_rect: Rect2i = get_used_rect_at_cell(sheet_texture, row, col, original_size)

			var sprite_is_empty: bool = used_rect.size == Vector2i(0, 0)

			if sprite_is_empty:
				continue
			
			if first_rect:
				max_used_rect = used_rect
				first_rect = false
			
			max_used_rect = max_used_rect.merge(used_rect)
	
	return max_used_rect


# Get used rect for sprite in sprite sheet at position
func get_used_rect_at_cell(sheet_texture: ImageTexture, row: int, col: int, original_size: Vector2) -> Rect2i:
	var sprite = AtlasTexture.new()
	sprite.atlas = sheet_texture

	var region_position: Vector2 = Vector2(col * original_size.x, row * original_size.y)
	var region_size: Vector2 = original_size
	sprite.region = Rect2(region_position, region_size)

	var image: Image = sprite.get_image()
	var used_rect = image.get_used_rect()

	return used_rect
