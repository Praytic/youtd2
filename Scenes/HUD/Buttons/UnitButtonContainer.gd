class_name UnitButtonContainer
extends AspectRatioContainer


static func make() -> UnitButtonContainer:
	return Globals.unit_button_container_scene.instantiate()


func _process(_delta):
	if self.get_child_count() == 0:
		queue_free()
