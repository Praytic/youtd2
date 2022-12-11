tool
extends Node2D

class_name AreaOfEffect

var radius: float
var resolution: float

func _init(radius: float, position: Vector2):
	var aoe_sprite = Sprite.new()
	aoe_sprite.texture = load("res://Resources/PulsingDot.tres")
	self.radius = radius
	self.resolution = resolution

func _get_property_list():
	var properties = []
	properties.append({
		name = "Debug",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})

	# Example of adding a property to the script category
	properties.append({
		name = "Logging_Enabled",
		type = TYPE_BOOL
	})
	return properties

func _ready():
	pass
