extends Node


@onready var audioStream: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.creep_reached_portal.connect(_on_Creep_reached_portal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_Creep_reached_portal(_damage, creep: Creep):
	AudioListener2D.make_current()
	creep.position
