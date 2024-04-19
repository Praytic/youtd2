extends Node


func isometric_vector_to_top_down(v: Vector2) -> Vector2:
	var top_down: Vector2 = v * Vector2(1.0, 2.0)

	return top_down


func top_down_vector_to_isometric(v: Vector2) -> Vector2:
	var top_down: Vector2 = v * Vector2(1.0, 0.5)

	return top_down


func vector3_to_vector2(vec3: Vector3) -> Vector2:
	return Vector2(vec3.x, vec3.y)


func canvas_pos_to_wc3_pos(canvas_pos: Vector2) -> Vector2:
	var pos_pixels: Vector2 = VectorUtils.isometric_vector_to_top_down(canvas_pos)
	var pos_wc3: Vector2 = pos_pixels / Constants.WC3_DISTANCE_TO_PIXELS

	return pos_wc3


func wc3_pos_to_canvas_pos(pos_wc3: Vector3) -> Vector2:
	var pos_pixels: Vector3 = pos_wc3 * Constants.WC3_DISTANCE_TO_PIXELS
	var canvas_x: float = pos_pixels.x
	var canvas_y: float = pos_pixels.y * 0.5 - pos_pixels.z * 0.5
	var pos_canvas: Vector2 = Vector2(canvas_x, canvas_y)

	return pos_canvas


func vector_distance_squared(a: Vector2, b: Vector2) -> float:
	var diff: Vector2 = a - b
	var distance_squared: float = diff.x * diff.x + diff.y * diff.y

	return distance_squared


func vector_in_range(start: Vector2, end: Vector2, radius: float) -> bool:
	var diff: Vector2 = start - end
	var distance_squared: float = diff.x * diff.x + diff.y * diff.y
	var radius_squared: float = radius * radius
	var in_range: bool = distance_squared <= radius_squared

	return in_range
