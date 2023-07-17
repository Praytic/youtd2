extends ItemDrop


enum ItemDropState {
	SPAWNING,
	STILL,
	GATHERING,
	NONE
}

var _state: ItemDropState = ItemDropState.SPAWNING
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play("drop")


func _on_animation_finished():
	if _state == ItemDropState.SPAWNING:
		_state = ItemDropState.STILL
		_sprite.play("still")
