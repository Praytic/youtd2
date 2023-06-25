@tool
extends AnimatedSprite2D


@export var sprite_sheets_dir: String

const ACTIONS = ["floating", "slow_run", "run", "death", "stunned"]
const DIRECTIONS = ["E", "W", "S", "N"]
const CELL_WIDTH = 512
const COLUMNS = 4 


func _ready():
	for action in ACTIONS:
		for direction in DIRECTIONS:
			var animation_name = "%s_%s" % [action, direction]
			var sprite_sheet_path = "%s/%s.png" % [sprite_sheets_dir, animation_name]
			var sprite_sheet_atlas = load(sprite_sheet_path)
			var rows = sprite_sheet_atlas.get_height() / CELL_WIDTH

			if sprite_frames.has_animation(animation_name):
				sprite_frames.clear(animation_name)

			sprite_frames.add_animation(animation_name)
			
			print_verbose("Create [%s] animation frames for [%s] action." % [rows * COLUMNS, animation_name])
			
			for row in range(0, rows):
				for col in range(0, COLUMNS):
					print_verbose("Create [%s:%s] frame." % [row, col])
					_create_animation_frame(animation_name, row, col, sprite_sheet_atlas)


func _create_animation_frame(anim, row, col, sprite_sheet):
	var frame = Image.create(CELL_WIDTH, CELL_WIDTH, false, Image.FORMAT_RGBA8)
	frame.blit_rect(sprite_sheet.get_image(), Rect2(col * CELL_WIDTH, row * CELL_WIDTH, CELL_WIDTH, CELL_WIDTH), Vector2(0, 0))

	var texture = ImageTexture.create_from_image(frame)
	
	print_verbose("[%s:%s] - %s" % [row, col, texture.get_size()])
	
	var frame_index = row * COLUMNS + col
	sprite_frames.add_frame(anim, texture)
