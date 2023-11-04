extends MainLoop


# Script to take a tileset and cut into 2 sections:
# 1. part below floor1
# 2. part above floor1
# These tiles are intended to be used as "connectors" to be
# placed between two layers of floor tiles.

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/Scripts/CutTilesIntoConnectors.gd" -- foo.png

const ARG_COUNT: int = 1

const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 512
const MARGIN: int = 4
const CELL_WIDTH_WITH_MARGIN: int = CELL_WIDTH + MARGIN * 2
const CELL_HEIGHT_WITH_MARGIN: int = CELL_HEIGHT + MARGIN * 2

# Cuts out bottom section in v shape
const polygon_bottom_v: PackedVector2Array = [Vector2(128, 511), Vector2(127, 511), Vector2(0, 447), Vector2(0, 319), Vector2(127, 383), Vector2(128, 383), Vector2(255, 319), Vector2(255, 447)]
# Cuts out top section in hexagon shape. It's basically the
# rest of the tile above the bottom v shape.
const polygon_top_hexagon: PackedVector2Array = [Vector2(128, 383), Vector2(127, 383), Vector2(0, 319), Vector2(0, 191), Vector2(127, 127), Vector2(128, 127), Vector2(255, 191), Vector2(255, 320)]

# NOTE: modify these to change which shape is used to cut
# bottom/top sections
const POLYGON_FOR_BOTTOM: PackedVector2Array = polygon_bottom_v
const POLYGON_FOR_TOP: PackedVector2Array = polygon_top_hexagon


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
		print("Incorrect args provided. Expected 1 args: path to tileset.")
		print(arg_list)

		return

	var path: String = arg_list[0]

	process_path(path)


func process_path(path: String):
	print("Processing path:", path)

	var original_image: Image = Image.load_from_file(path)

	var column_count: int = int(original_image.get_width() / CELL_WIDTH_WITH_MARGIN)
	var row_count: int = int(original_image.get_height() / CELL_HEIGHT_WITH_MARGIN)
	var new_row_count: int = row_count * 2
	var new_column_count: int = column_count
	var new_tilesheet_width: int = new_column_count * CELL_WIDTH_WITH_MARGIN
	var new_tilesheet_height: int = new_row_count * CELL_HEIGHT_WITH_MARGIN

	var atlas_image: = Image.create(new_tilesheet_width, new_tilesheet_height, false, Image.FORMAT_RGBA8)

	for column in range(0, column_count):
		for row in range(0, row_count):
			for cell_x in range(0, CELL_WIDTH):
				for cell_y in range(0, CELL_HEIGHT):
					var cell_pos: Vector2 = Vector2(cell_x, cell_y)
					var tilesheet_x: int = cell_x + MARGIN + CELL_WIDTH_WITH_MARGIN * column
					var tilesheet_y: int = cell_y + MARGIN + CELL_HEIGHT_WITH_MARGIN * row
					var pixel: Color = original_image.get_pixel(tilesheet_x, tilesheet_y)

					var is_part_of_bottom_v: bool = need_to_copy_pixel(cell_pos, POLYGON_FOR_BOTTOM)
					var is_part_of_top_v: bool = need_to_copy_pixel(cell_pos, POLYGON_FOR_TOP)

#					NOTE: shift down top section so that
#					it's bottom section touches bottom of
#					cell
					var new_tilesheet_y_for_top_section: int = cell_y + MARGIN + CELL_HEIGHT_WITH_MARGIN * row * 2 + 128
#					NOTE: draw bottom section on next row,
#					below top section
					var new_tilesheet_y_for_bottom_section: int = cell_y + MARGIN + CELL_HEIGHT_WITH_MARGIN * row * 2 + CELL_HEIGHT_WITH_MARGIN

					if is_part_of_top_v:
						atlas_image.set_pixel(tilesheet_x, new_tilesheet_y_for_top_section, pixel)

					if is_part_of_bottom_v:
						atlas_image.set_pixel(tilesheet_x, new_tilesheet_y_for_bottom_section, pixel)


	var original_filename: String = path.get_file()
	var new_path: String = path.replace(".png", "-cut.png")
	atlas_image.save_png(new_path)


func need_to_copy_pixel(pos: Vector2, polygon: PackedVector2Array):
	var pixel_is_in_poly: bool = Geometry2D.is_point_in_polygon(pos, polygon)
	
	return pixel_is_in_poly
