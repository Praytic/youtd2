class_name GenerateAtlas


# Script to take tile images produced by blender export
# script and combine them into an atlas image.
# How to use: add a call to GenerateAtlas.run() in GameScene._init()

# TODO: make this runnable from in-game console. Workflow should be like this:
# Press "~" to open console
# Type "generate-atlas"
# File pick dialog opens
# Choose folder that contains images
# Enter name to use for atlas names
# Generation process runs

# NOTE: copy this to GameScene.gd
# func _init():
# 	GenerateAtlas.run("C:/Users/kvely/blender/bird/script-export/rigAction", "bird")


static func run(root_path: String, name: String):
	var direction_dirs: PackedStringArray = DirAccess.get_directories_at(root_path)

	for direction_dirname in direction_dirs:
		GenerateAtlas.combine_tiles(root_path, direction_dirname, name)


static func combine_tiles(root_path: String, direction_dirname: String, name: String):
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
