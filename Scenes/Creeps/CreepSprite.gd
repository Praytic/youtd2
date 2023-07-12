@tool
extends AnimatedSprite2D


@export var sprite_sheets_dir: String
@export var _animation_offset_map: Dictionary = {}

const ACTIONS = ["floating", "slow_run", "run", "death", "stunned", "fly"]
const DIRECTIONS = ["E", "SW", "W", "NE", "S", "SE", "N", "NW"]
const ANIMATION_FPS = 15.0


func _ready():
	# The code below is used to generate SpriteFrames in the editor.
	# It's not necessary to call this logic in runtime.
	if not Engine.is_editor_hint() or sprite_sheets_dir == null:
		return

	_animation_offset_map.clear()
	
	var start_time = Time.get_ticks_msec()
	sprite_frames.clear_all()
	for action in ACTIONS:
		for direction in DIRECTIONS:
			var animation_name = "%s_%s" % [action, direction]
			var sprite_sheet_path = "%s/%s.png" % [sprite_sheets_dir, animation_name]

#			NOTE: currently quietly skipping non-existing
#			animations because some creeps don't use
#			animations for NW, SW, etc.
			if !ResourceLoader.exists(sprite_sheet_path):
				if sprite_frames.has_animation(animation_name):
					sprite_frames.clear(animation_name)

				continue

			var sprite_sheet_atlas = load(sprite_sheet_path)
			print_verbose("sprite_sheet_path=", sprite_sheet_path)

			print_verbose("sprite_sheet_atlas.get_width() = ", sprite_sheet_atlas.get_width())
			
			var metadata: PackedMetadata = PackedMetadata.get_metadata_for_sheet(sprite_sheet_path)

			var packed_offset: Vector2 = metadata.get_offset() * sprite_sheet_atlas.get_size()
			_animation_offset_map[animation_name] = packed_offset

			var rows: int = metadata.get_row_count()
			var cols: int = metadata.get_col_count()
			var cell_size: Vector2 = Vector2(sprite_sheet_atlas.get_width() / cols, sprite_sheet_atlas.get_height() / rows)

			if sprite_frames.has_animation(animation_name):
				sprite_frames.clear(animation_name)

			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, ANIMATION_FPS)

			for row in range(0, rows):
				for col in range(0, cols):
					_create_animation_frame(animation_name, row, col, sprite_sheet_atlas, cell_size)

	var end_time = Time.get_ticks_msec()
	print_verbose("Generated animation frames in [%s] seconds." % [(end_time - start_time) / 1000.0])


func _create_animation_frame(anim, row, col, sprite_sheet, cell_size: Vector2):
	var texture = AtlasTexture.new()
	texture.atlas = sprite_sheet
	texture.region = Rect2(col * cell_size.x, row * cell_size.y, cell_size.x, cell_size.y)

	print_verbose("texture.region=", texture.region)
	if _is_valid_frame(texture):
		sprite_frames.add_frame(anim, texture)

func _is_valid_frame(texture_frame: AtlasTexture):
	return texture_frame.get_image().get_used_rect().size != Vector2i(0, 0)


# Use this instead of regular play(). This f-n corrects the
# position of the sprite for current animation.
func play_creep_animation(animation_name: String, custom_speed: float = 1.0):
	play(animation_name, custom_speed)

	var packed_offset: Vector2 = _animation_offset_map[animation] as Vector2
	set_offset(packed_offset)
