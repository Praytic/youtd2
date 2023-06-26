@tool
extends AnimatedSprite2D


@export var sprite_sheets_dir: String

const ACTIONS = ["floating", "slow_run", "run", "death", "stunned"]
const DIRECTIONS = ["E", "W", "S", "N"]
const CELL_WIDTH = 512
const COLUMNS = 4 
const ANIMATION_FPS = 15.0


func _ready():
	var start_time = Time.get_ticks_msec()
	sprite_frames.clear_all()
	for action in ACTIONS:
		for direction in DIRECTIONS:
			var animation_name = "%s_%s" % [action, direction]
			var sprite_sheet_path = "%s/%s.png" % [sprite_sheets_dir, animation_name]
			var sprite_sheet_atlas = load(sprite_sheet_path)
			var rows = sprite_sheet_atlas.get_height() / CELL_WIDTH
			
			if sprite_frames.has_animation(animation_name):
				sprite_frames.clear(animation_name)
			
			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, ANIMATION_FPS)
			
			for row in range(0, rows):
				for col in range(0, COLUMNS):
					_create_animation_frame(animation_name, row, col, sprite_sheet_atlas)
	
	var end_time = Time.get_ticks_msec()
	print_verbose("Generated animation frames in [%s] seconds." % [(end_time - start_time) / 1000.0])


func _create_animation_frame(anim, row, col, sprite_sheet):
	var frame = Image.create(CELL_WIDTH, CELL_WIDTH, false, Image.FORMAT_RGBA8)
	frame.blit_rect(sprite_sheet.get_image(), Rect2(col * CELL_WIDTH, row * CELL_WIDTH, CELL_WIDTH, CELL_WIDTH), Vector2(0, 0))

	var texture = ImageTexture.create_from_image(frame)
	
	var frame_index = row * COLUMNS + col
	sprite_frames.add_frame(anim, texture)
