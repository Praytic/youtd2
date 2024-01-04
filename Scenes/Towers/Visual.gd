@tool
extends Node2D


func _ready():
	$"../Model".queue_free()
