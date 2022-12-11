extends Node2D

class_name Tower

signal build_complete
signal build_init

var aoe: AreaOfEffect

export(float) var radius
export(int) var size = 32

func _ready():
	aoe = AreaOfEffect.new(radius)
	aoe.position = Vector2(size, size) / 2
	connect("build_complete", self, "_on_build_complete")
	connect("build_init", self, "_on_build_init")
	add_child(aoe)
	aoe.hide()
	
func _on_build_complete():
	print("Build complete")
	aoe.hide()

func _on_build_init():
	print("Build init")
	aoe.show()
