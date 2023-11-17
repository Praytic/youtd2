class_name PrerenderTool extends Node


# Script which creates images used for a prerendered
# background. It hides all visual entities except for the
# background tilemap and then moves the camera around the
# tilemap while taking photos. Saves results to root of
# project.

# Note that you should discard photo0 - it's the same as
# photo1. Have to take first picture at first position twice
# because first two photos are always the same for some
# reason.


# This is the width and height of photos.
const _PRERENDER_CHUNK_SIZE: float = 2048


static func run(gamescene: Node, ui_canvas_layer: CanvasLayer, map_node):
	var scene_tree: SceneTree = gamescene.get_tree()
	var viewport: Viewport = gamescene.get_viewport()
	var viewport_rect: Rect2 = viewport.get_visible_rect()
	
	var camera: Camera2D = viewport.get_camera_2d()
#	Turn off camera limits so that it can go to map edges
	camera.limit_left = -100000
	camera.limit_right = 100000
	camera.limit_top = -100000
	camera.limit_bottom = 100000
#	Set camera zoom to this value so that map pixels exactly match
#	screen pixels
	camera.zoom = Vector2.ONE * 2560 / _PRERENDER_CHUNK_SIZE
	
	var window: Viewport = gamescene.get_window()
	window.size = Vector2i(_PRERENDER_CHUNK_SIZE, _PRERENDER_CHUNK_SIZE)

#	Hide everything except the map
	ui_canvas_layer.hide()
	map_node.setup_for_prerendering()

	await scene_tree.create_timer(1.0).timeout

	var viewport_texture: ViewportTexture = viewport.get_texture()
	var viewport_scale: Vector2 = viewport.get_screen_transform().get_scale()
	var camera_zoom: float = viewport_rect.size.x / _PRERENDER_CHUNK_SIZE
	var viewport_size: Vector2 = viewport_texture.get_size() / viewport_scale / camera_zoom

	var row_count: int = 4
	var column_count: int = 4

	var first_position: Vector2 = -(row_count / 2) * viewport_size + viewport_size / 2

	var cam_position_list: Array[Vector2] = []

	for row in range(0, row_count):
		for column in range(0, column_count):
			var cam_position: Vector2 = first_position + Vector2(column * viewport_size.x, row * viewport_size.y)
			cam_position_list.append(cam_position)

#	NOTE: first photo is same as second for some reason - no
#	idea so doing first one twice as a workaround
	cam_position_list.insert(0, first_position)

	for i in range(0, cam_position_list.size()):
		camera.position = cam_position_list[i]

#		NOTE: wait for screen to render at new position
		await scene_tree.create_timer(0.2).timeout

		print("Photo #%d @ %s" % [i, camera.position])
		var viewport_image: Image = viewport_texture.get_image()
		var result_path: String = "photo%d.png" % i
		viewport_image.save_png(result_path)

#	Turn UI back on to signal completion
	ui_canvas_layer.show()
