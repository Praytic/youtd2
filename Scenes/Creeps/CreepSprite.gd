@tool
extends AnimatedSprite2D


@export var sprite_sheets_dir: String

const ACTIONS = ["floating", "slow_run", "run", "death", "stunned", "fly"]
const DIRECTIONS = ["E", "SW", "W", "NE", "S", "SE", "N", "NW"]
const COLUMNS = 4 
const ANIMATION_FPS = 15.0


func _ready():
	# The code below is used to generate SpriteFrames in the editor.
	# It's not necessary to call this logic in runtime.
	if not Engine.is_editor_hint():
		return
	
	var start_time = Time.get_ticks_msec()
	sprite_frames.clear_all()
	for action in ACTIONS:
		for direction in DIRECTIONS:
			var animation_name = "%s_%s" % [action, direction]
			var sprite_sheet_path = "%s/%s.png" % [sprite_sheets_dir, animation_name]
			var sprite_sheet_atlas = load(sprite_sheet_path)
			
			if not sprite_sheet_atlas:
				continue
			
			var cell_width = sprite_sheet_atlas.get_width() / COLUMNS
			var rows = sprite_sheet_atlas.get_height() / cell_width

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
	var cell_width = sprite_sheet.get_width() / COLUMNS
	var texture = AtlasTexture.new()
	texture.atlas = sprite_sheet
	texture.region = Rect2(col * cell_width, row * cell_width, cell_width, cell_width)
	if _is_valid_frame(texture):
		sprite_frames.add_frame(anim, texture)

func _is_valid_frame(texture_frame: AtlasTexture):
	return texture_frame.get_image().get_used_rect().size != Vector2i(0, 0)
