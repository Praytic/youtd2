extends Control

onready var default_camera = get_node("%Camera")
onready var minimap_camera = $ViewportContainer/Viewport/MinimapCamera
onready var minimap_texture = $ViewportContainer/Viewport/MinimapTexture
onready var camera_projection = $ViewportContainer/Viewport/CameraProjection
onready var mobs_projection = $ViewportContainer/Viewport/MobsProjection
onready var map = get_node("%Map")
onready var mobs = map.get_node("MobYSort")
onready var minimap_scale: float

func _ready():
	minimap_camera.position = minimap_texture.get_rect().get_center()
	var map_size = map.get_play_area_size()
	var minimap_size = minimap_texture.get_rect().size
	minimap_scale = minimap_size.x / map_size.x / 2
	_update_view_rect()


func _on_Camera_camera_moved(shift_vector):
	minimap_camera.position = minimap_camera.get_camera_position() + \
		shift_vector * minimap_scale
	_update_view_rect()


func _on_Camera_camera_zoomed(zoom_value):
	_update_view_rect()

func _update_view_rect():
	var ctrans = default_camera.get_canvas_transform()
	var view_size = default_camera.get_viewport_rect().size / ctrans.get_scale()
	var view_pos = -ctrans.get_origin() / ctrans.get_scale()
#	print("Orig: %s %s" % [view_pos, view_size])
	
	var projection_size = view_size * minimap_scale
	var projection_pos = view_pos * minimap_scale
	
	var minimap_ctrans = minimap_camera.get_canvas_transform()
	var minimap_view_size = minimap_camera.get_viewport_rect().size / minimap_ctrans.get_scale()
	var minimap_view_pos = -minimap_ctrans.get_origin() / minimap_ctrans.get_scale()
	var minimap_view_center = minimap_view_pos + minimap_view_size / 2
	
	camera_projection.position = projection_pos
	camera_projection.set_size(projection_size)
	camera_projection.update()


func _on_MobYSort_child_entered_tree(mob):
	mob.connect("moved", self, "_on_Mob_moved", [mob])


func _on_MobYSort_child_exiting_tree(mob):
	mob.disconnect("moved", self, "_on_Mob_moved")
	mobs_projection.pos_dict.erase(mob)


func _on_Mob_moved(delta, mob):
	mobs_projection.pos_dict[mob] = mob.position * minimap_scale
	mobs_projection.update()
