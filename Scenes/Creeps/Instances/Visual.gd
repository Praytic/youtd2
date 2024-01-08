@tool
extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var sprite: AnimatedSprite2D = $Sprite
	var temp_sprite: AnimatedSprite2D = $Sprite2D
	var selection_sprite: AnimatedSprite2D = $SelectionOutline
	print("Temp_sprite.offset = %s" % temp_sprite.offset)
	sprite.sprite_frames = temp_sprite.sprite_frames
	sprite.set_offset(temp_sprite.offset)
	sprite.scale = temp_sprite.scale
	sprite.position = temp_sprite.position
	selection_sprite.sprite_frames = temp_sprite.sprite_frames
	selection_sprite.set_offset(temp_sprite.offset)
	selection_sprite.scale = temp_sprite.scale
	selection_sprite.position = temp_sprite.position
#	$Sprite2D.queue_free()
