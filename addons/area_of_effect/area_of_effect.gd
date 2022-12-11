tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("AreaOfEffect", "Node2D", preload("core.gd"), preload("button_icon.png"))

func _exit_tree():
	remove_custom_type("AreaOfEffect")
