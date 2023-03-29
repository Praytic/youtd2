extends Node

# Collection of f-ns to deal with conversions between 2d and
# isometric projections.


# Perform a move_toward() operation in isometric space. This
# means that same delta will look visually slower when
# moving vertically than horizontally.
func vector_move_toward(start: Vector2, end: Vector2, delta: float) -> Vector2:
	var delta_vector_2d = (end - start).normalized() * delta
	var delta_vector_isometric: Vector2 = Vector2(delta_vector_2d.x, delta_vector_2d.y / 2)
	var isometric_delta: float = delta_vector_isometric.length()
	var move_result: Vector2 = start.move_toward(end, isometric_delta)

	return move_result


# Takes a vector in isometric space and calculates it's
# length in 2d space. Should be used for all distance
# calculations.
func vector_length(vector_isometric: Vector2) -> float:
	var vector_2d: Vector2 = Vector2(vector_isometric.x, vector_isometric.y * 2)
	var length: float = vector_2d.length()

	return length


# Takes two vectors in isometric space and calculates their
# distance in 2d space
func vector_distance_to(a: Vector2, b: Vector2) -> float:
	var difference: Vector2 = a - b
	var distance: float = vector_length(difference)

	return distance
