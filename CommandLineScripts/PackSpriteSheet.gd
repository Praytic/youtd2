class_name PackSpriteSheet extends MainLoop


# Takes sprite sheets in a given folder/subfolders and
# generates versions that are more tightly packed, with less
# empty space. Also performs an optional resize.

# How to use:
# 1. Open terminal.
# 
# 2. Run the script with godot's command line executable:
# "path/to/godot-console.exe" -s "path/to/PackSpriteSheet.gd" -- "path/to/target/folder" "raw size of frames in sprites sheets" "target size of frames in sprites sheets"
# Example:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/CommandLineScripts/PackSpriteSheet.gd" -- "C:/Users/kvely/packing-dir/orc" 512 256
# Target size can be same as raw or lower. Raw size must be
# dividable by target size.
#
# 
# 3. Resulting packed sprite sheets will overwrite
#    originals, so make sure to backup.
# 
# 4. In addition to packed sprite sheets, this script also
#    generates metadata. This metadata needs to be used to
#    display the packed sprite sheet correctly.


const ARG_COUNT: int = 3

var _raw_frame_size: int = 0
var _original_frame_size: int = 0


func _initialize():	
	print("PackSpriteSheet.gd begin")
	run()
	print("PackSpriteSheet.gd end")


# NOTE: returning true from _process() is the only way to
# quit from MainLoop.
func _process(_delta: float):
	var end_main_loop: bool = true
	return end_main_loop


func run():
	var arg_list: Array = OS.get_cmdline_user_args()

	print("Argument list: ", arg_list)

	if arg_list.size() != ARG_COUNT:
		print("Incorrect args provided. Expected 2 args: path and original frame size.")

		return

	var root_dir_path: String = arg_list[0]
	_raw_frame_size = arg_list[1].to_float()
	_original_frame_size = arg_list[2].to_float()

	process_dir(root_dir_path)


func process_dir(dir_path: String):
	print("Processing dir:", dir_path)

# 	Process sheets in current dir
	var sheet_list: Array = DirAccess.get_files_at(dir_path)
	sheet_list = sheet_list.filter(
		func(sheet: String):
			var is_png: bool = sheet.ends_with(".png")
			return is_png
			)

	for sheet in sheet_list:
		var sheet_path: String = "%s/%s" % [dir_path, sheet]
		process_sheet(sheet_path)

# 	Recurse into subdirs
	var subdir_list: Array = DirAccess.get_directories_at(dir_path)

	for subdir_name in subdir_list:
		var subdir_path: String = "%s/%s" % [dir_path, subdir_name]
		process_dir(subdir_path)


func process_sheet(sheet_path: String):
	print("Processing sheet: ", sheet_path)
	
	var sprite_sheet: Image = Image.load_from_file(sheet_path)

	var need_to_resize: bool = _raw_frame_size != _original_frame_size

	if need_to_resize:
		var new_size: Vector2 = sprite_sheet.get_size() * _original_frame_size / _raw_frame_size
		sprite_sheet.resize(new_size.x, new_size.y)

	var max_used_rect: Rect2i = get_max_used_rect(sprite_sheet)
	var packed_sheet: Image = create_packed_sheet(sprite_sheet, max_used_rect)

	packed_sheet.save_png(sheet_path)
	save_metadata(sheet_path, packed_sheet, max_used_rect)


# Calculate a rect that fits all sprites in the sprite sheet
func get_max_used_rect(sheet_image: Image) -> Rect2i:
	var sheet_texture: ImageTexture = ImageTexture.create_from_image(sheet_image)
	
	var original_size: Vector2 = Vector2(_original_frame_size, _original_frame_size)
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


# Create packed sheet copying sprites within given rect from source sprite sheet.
func create_packed_sheet(sheet_image: Image, max_used_rect: Rect2i) -> Image:
	var original_size: Vector2 = Vector2(_original_frame_size, _original_frame_size)
	var packed_size: Vector2 = max_used_rect.size
	var row_count: int = int(float(sheet_image.get_height()) / original_size.y)
	var column_count: int = int(float(sheet_image.get_width()) / original_size.x)
	
	var packed_sheet: Image = Image.create(packed_size.x * column_count, packed_size.y * row_count, false, Image.FORMAT_RGBA8)

	for row in range(0, row_count):
		for col in range(0, column_count):
			var src_rect: Rect2i = Rect2i()
			src_rect.position = Vector2i(original_size.x * col, original_size.y * row) + max_used_rect.position
			src_rect.size = max_used_rect.size

			var dst: Vector2i = Vector2i(packed_size.x * col, packed_size.y * row)

			packed_sheet.blit_rect(sheet_image, src_rect, dst)
	
	return packed_sheet


func save_metadata(sheet_path: String, packed_sheet: Image, max_used_rect: Rect2i):
	var metadata_path: String = PackedMetadata.get_metadata_path(sheet_path)

# 	Create and write first line if opening metadata file for
# 	the first time
# 	NOTE: WRITE_READ creates file if doesn't exist and
# 	truncates it. READ_WRITE is the opposite.
	if !FileAccess.file_exists(metadata_path):
		var file_created: FileAccess = FileAccess.open(metadata_path, FileAccess.WRITE_READ)
		
		var legend_line: Array = PackedMetadata.get_legend_line()
		file_created.store_csv_line(legend_line)

		file_created.close()

	var original_center: Vector2 = Vector2(_original_frame_size / 2, _original_frame_size / 2)
	var used_rect_center: Vector2 = max_used_rect.position + max_used_rect.size / 2
	var offset_pixels: Vector2 = used_rect_center - original_center

	var metadata: PackedMetadata = PackedMetadata.make(sheet_path, packed_sheet, max_used_rect, offset_pixels)
	var metadata_csv_line: Array = metadata.convert_to_csv_line()

	var metadata_file: FileAccess = FileAccess.open(metadata_path, FileAccess.READ_WRITE)

	metadata_file.seek_end()
	metadata_file.store_csv_line(metadata_csv_line)


func get_row_count() -> int:
	return 0
