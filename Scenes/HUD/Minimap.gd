extends Node2D

onready var mob_icon_template: Sprite = $MobIcon
onready var path_curve: Curve2D = $MobPath1.curve


func spawn(mob: Mob):
	var mob_icon = mob_icon_template.duplicate()
	mob_icon.show()
	mob_icon.position = path_curve.get_point_position(0)
	add_child(mob_icon)
	var path_scale = mob.path_curve.get_baked_length() / path_curve.get_baked_length()
	mob.connect("moved", self, "_on_Mob_moved", [mob, mob_icon, mob.mob_move_speed / path_scale])
	mob.connect("dead", self, "_on_Mob_dead", [mob_icon])
	
	
func _on_Mob_moved(delta: float, mob: Mob, mob_icon: Sprite, speed: float):
	var path_point: Vector2 = path_curve.get_point_position(mob.current_path_index)
	mob_icon.position = mob_icon.position.move_toward(path_point, speed * delta)

func _on_Mob_dead(mob_icon: Sprite):
	mob_icon.queue_free()
