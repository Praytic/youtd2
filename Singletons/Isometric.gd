extends Node

# Collection of f-ns to deal with conversions between 2d and
# isometric projections.


# Perform a move_toward() operation in isometric space. This
# means that same delta will look visually slower when
# moving vertically than horizontally.
func vector_move_toward(start: Vector2, end: Vector2, delta: float) -> Vector2:
	var delta_pixels: float = Utils.to_pixels(delta)
	var move_result: Vector2 = vector_move_toward_PIXELS(start, end, delta_pixels)

	return move_result


func vector_move_toward_PIXELS(start: Vector2, end: Vector2, delta: float) -> Vector2:
	var start_top_down: Vector2 = isometric_vector_to_top_down(start)
	var end_top_down: Vector2 = isometric_vector_to_top_down(end)
	var move_result_top_down: Vector2 = start_top_down.move_toward(end_top_down, delta)
	var move_result_isometric: Vector2 = top_down_vector_to_isometric(move_result_top_down)

	return move_result_isometric


# Takes a vector in isometric space and calculates it's
# length in 2d space. Should be used for all distance
# calculations.
func vector_length(vector_isometric: Vector2) -> float:
	var length_pixels: float = vector_length_PIXELS(vector_isometric)
	var length: float = Utils.from_pixels(length_pixels)
	
	return length


func vector_length_PIXELS(vector_isometric: Vector2) -> float:
	var vector_top_down: Vector2 = isometric_vector_to_top_down(vector_isometric)
	var length: float = vector_top_down.length()

	return length


func vector_distance_to(a: Vector2, b: Vector2) -> float:
	var distance_pixels: float = vector_distance_to_PIXELS(a, b)
	var distance: float = Utils.from_pixels(distance_pixels)

	return distance


# Takes two vectors in isometric space and calculates their
# distance in 2d space
func vector_distance_to_PIXELS(a: Vector2, b: Vector2) -> float:
	var difference_isometric: Vector2 = a - b
	var distance: float = vector_length_PIXELS(difference_isometric)

	return distance


func isometric_vector_to_top_down(v: Vector2) -> Vector2:
	var top_down: Vector2 = v * Vector2(1.0, 2.0)

	return top_down


func top_down_vector_to_isometric(v: Vector2) -> Vector2:
	var top_down: Vector2 = v * Vector2(1.0, 0.5)

	return top_down


# Applies z coordinate by modifying y coordinate of result
func vector3_to_isometric_vector2(vector3: Vector3) -> Vector2:
	var x: float = vector3.x
	var y: float = vector3.y - vector3.z * 0.5
	var vector2: Vector2 = Vector2(x, y)

	return vector2
