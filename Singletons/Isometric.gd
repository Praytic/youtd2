extends Node

# Collection of f-ns to deal with conversions between 2d and
# isometric projections.


func isometric_vector_to_top_down(v: Vector2) -> Vector2:
	var top_down: Vector2 = v * Vector2(1.0, 2.0)

	return top_down


func top_down_vector_to_isometric(v: Vector2) -> Vector2:
	var top_down: Vector2 = v * Vector2(1.0, 0.5)

	return top_down
