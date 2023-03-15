extends Control

@onready var default_camera = get_node("%Camera3D")
@onready var minimap_camera = $SubViewportContainer/SubViewport/MinimapCamera
@onready var minimap_texture = $SubViewportContainer/SubViewport/MinimapTexture
@onready var camera_projection = $SubViewportContainer/SubViewport/CameraProjection
@onready var creeps_projection = $SubViewportContainer/SubViewport/CreepsProjection
@onready var map = get_node("%Map")
@onready var minimap_scale: float

func _ready():
	minimap_camera.position = minimap_texture.get_rect().get_center()
	var map_size = map.get_play_area_size()
	var minimap_size = minimap_texture.get_rect().size
	minimap_scale = minimap_size.x / map_size.x / 2
	_update_view_rect()


func _on_Camera_camera_moved(shift_vector):
	minimap_camera.position = minimap_camera.get_screen_center_position() + \
		shift_vector * minimap_scale
	_update_view_rect()


func _on_Camera_camera_zoomed(_zoom_value):
	_update_view_rect()

func _update_view_rect():
	var ctrans = default_camera.get_canvas_transform()
	var view_size = default_camera.get_viewport_rect().size / ctrans.get_scale()
	var view_pos = -ctrans.get_origin() / ctrans.get_scale()
#
	var projection_size = view_size * minimap_scale
	var projection_pos = view_pos * minimap_scale
	
	camera_projection.position = projection_pos
	camera_projection.set_size(projection_size)
	camera_projection.queue_redraw()


func _on_ObjectYSort_child_entered_tree(child: Node):
	if child is Creep:
		var creep: Creep = child as Creep
		creep.moved.connect(_on_Creep_moved.bind(creep))


func _on_ObjectYSort_child_exiting_tree(child: Node):
	if child is Creep:
		var creep: Creep = child as Creep
		creep.moved.disconnect(_on_Creep_moved)
		creeps_projection.pos_dict.erase(creep)


func _on_Creep_moved(_delta, creep: Creep):
	creeps_projection.pos_dict[creep] = creep.position * minimap_scale
	creeps_projection.queue_redraw()
