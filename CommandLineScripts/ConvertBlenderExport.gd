extends MainLoop


# Script to take results of blender export and turn it into
# spritesheets.
# Input: directory structure with separate sprites.
# Output: a set of spritesheets

# Run the script with godot's command line executable:
# "C:\Program Files\Godot\Godot_v4.1.1-stable_win64_console.exe" -s "C:/Users/kvely/youtd2/CommandLineScripts/ConvertBlenderExport.gd"

const CELL_WIDTH = 512
const COLUMNS = 4 
const ANIMATIONS = ["floating", "slow_run", "run", "death", "stunned"]

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
	for dir in ANIMATIONS:
		var direction_dirs: PackedStringArray = DirAccess.get_directories_at(dir)

		for direction_dirname in direction_dirs:
			combine_tiles(dir, direction_dirname)


func combine_tiles(animation: String, direction_dirname: String):
	var direction_dir_path: String = "%s/%s" % [animation, direction_dirname]
	var file_list: PackedStringArray = DirAccess.get_files_at(direction_dir_path)
	
	print("Processing [%s] frames for [%s] animation." % [file_list.size(), animation])
	
	var row_count: int = int(ceil(float(file_list.size()) / COLUMNS))

	var atlas_width: float = COLUMNS * CELL_WIDTH
	var atlas_height: float = row_count * CELL_WIDTH

	var atlas_image: = Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)

	for i in range(0, file_list.size()):
		var file_name: String = file_list[i]
		var file_path: String = "%s/%s" % [direction_dir_path, file_name]
		var image: Image = Image.load_from_file(file_path)
		var buffer: PackedByteArray = image.save_png_to_buffer()

		for x in range(0, CELL_WIDTH):
			for y in range(0, CELL_WIDTH):
				var atlas_x = CELL_WIDTH * (i % COLUMNS) + x
				var atlas_y = CELL_WIDTH * (i / COLUMNS) + y

				var pixel: Color = image.get_pixel(x, y)
				atlas_image.set_pixel(atlas_x, atlas_y, pixel)

	var atlas_filename: String = "%s_%s.png" % [animation, direction_dirname]
	var atlas_folder: String = "res://generated-atlases"
	DirAccess.make_dir_absolute(atlas_folder)
	var atlas_path: String = "%s/%s" % [atlas_folder, atlas_filename]
	atlas_image.save_png(atlas_path)
