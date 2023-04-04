extends MainLoop


# Script to take tile images produced by blender export
# script and combine them into an atlas image.

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.0-stable_win64_console.exe" -s ./Scenes/GenerateAtlas.gd --path="C:/Users/kvely/blender/bird/script-export/rigAction" --name="bird"

const PATH_ARG: String = "path"
const NAME_ARG: String = "name"


func _initialize():
	print("GenerateAtlas.gd begin")

	var args_map: Dictionary = parse_args()

	var args_ok: bool = check_args(args_map)
	if !args_ok:
		print("GenerateAtlas.gd error - args not okay")

		return

	var path: String = args_map[PATH_ARG]
	var name: String = args_map[NAME_ARG]

	run(path, name)

	print("GenerateAtlas.gd end")


# NOTE: returning true from _process() is the only way to
# quit from MainLoop.
func _process(_delta: float):
	var end_main_loop: bool = true

	return end_main_loop


func parse_args() -> Dictionary:
	var out: Dictionary = {}

	var cmdline_args: Array = OS.get_cmdline_args()

	for argument in cmdline_args:
		if argument.find("=") > -1:
			var key_value: PackedStringArray = argument.split("=")
			var key: String = key_value[0].lstrip("--")
			var value: String = key_value[1]
			out[key] = value


	return out


func check_args(args_map: Dictionary) -> bool:
	var ok: bool = true

	for arg_key in [PATH_ARG, NAME_ARG]:
		if !args_map.has(arg_key):
			print("Argument is not defined: ", arg_key)

			ok = false

	return ok


func run(root_path: String, name: String):
	var direction_dirs: PackedStringArray = DirAccess.get_directories_at(root_path)

	for direction_dirname in direction_dirs:
		combine_tiles(root_path, direction_dirname, name)


func combine_tiles(root_path: String, direction_dirname: String, name: String):
	var direction_dir_path: String = "%s/%s" % [root_path, direction_dirname]
	var file_list: PackedStringArray = DirAccess.get_files_at(direction_dir_path)
	
	var column_count: int = 4
	var row_count: int = int(ceil(float(file_list.size()) / column_count))
	var cell_width: int = 256

	var atlas_width: float = column_count * cell_width
	var atlas_height: float = row_count * cell_width

	var atlas_image: = Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)

	for i in range(0, file_list.size()):
		var file_name: String = file_list[i]
		var file_path: String = "%s/%s" % [direction_dir_path, file_name]
		var image: Image = Image.load_from_file(file_path)
		var buffer: PackedByteArray = image.save_png_to_buffer()

		for x in range(0, 256):
			for y in range(0, 256):
				var atlas_x = cell_width * (i % column_count) + x
				var atlas_y = cell_width * (i / column_count) + y

				var pixel: Color = image.get_pixel(x, y)
				atlas_image.set_pixel(atlas_x, atlas_y, pixel)

	var atlas_filename: String = "%s_%s.png" % [name, direction_dirname]
	var atlas_folder: String = "res://generated-atlases"
	DirAccess.make_dir_absolute(atlas_folder)
	var atlas_path: String = "%s/%s" % [atlas_folder, atlas_filename]
	atlas_image.save_png(atlas_path)
