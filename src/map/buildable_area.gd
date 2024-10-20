class_name BuildableArea extends TileMapLayer


# This tilemap is used to define tiles where a player can
# build towers. One BuildableArea for each Player. Note that
# this tilemap is used for two things:
# - Define buildable area in editor while developing
# - Display buildable area visually while game is running
# 
# The actual logic for checking buildable positions is
# implemented by the BuildSpace class. BuildSpace loads data
# about buildable positions from BuildableAreas when game
# starts.


const BUILDABLE_AREA_COLOR: Color = Color8(0, 255, 255)
const BUILDABLE_PULSE_ALPHA_MIN = 0.1
const BUILDABLE_PULSE_ALPHA_MAX = 0.2
const BUILDABLE_PULSE_PERIOD = 1.0

@export var player_id: int


func _ready() -> void:
	add_to_group("buildable_areas")
	
#	NOTE: reset color so it's same for all areas. In editor,
#	buildable areas have different colors for convenience
#	while developing.
	modulate = BUILDABLE_AREA_COLOR
	
	var tween = create_tween()
	tween.tween_property(self, "modulate",
		Color(BUILDABLE_AREA_COLOR, BUILDABLE_PULSE_ALPHA_MIN),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "modulate",
		Color(BUILDABLE_AREA_COLOR, BUILDABLE_PULSE_ALPHA_MAX),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR).set_delay(0.5 * BUILDABLE_PULSE_PERIOD)
	tween.set_loops()
