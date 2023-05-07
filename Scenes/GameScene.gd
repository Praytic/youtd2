extends Node2D


@onready var map_node: Node2D = $Map

var creeps_exit_count: int = 0


@export var creeps_game_over_count: int = 10
@export var ignore_game_over: bool = true


func _ready():
	print_verbose("GameScene has loaded.")

	Messages.add_normal("Welcome to youtd 2!")
	Messages.add_normal("Move the camera with arrow keys or WASD.")
	Messages.add_normal("To build towers, click on the tower button in the bottom right corner.")
	Messages.add_normal("Select one of the elements and pick a tower.")
	Messages.add_normal("Move the mouse cursor to a spot where you want to build the tower.")
	Messages.add_normal("When there's a valid build position, the tower under the cursor will turn green.")


func _on_HUD_start_wave(wave_index):
	$Map/CreepSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$Map/CreepSpawner.stop()


func _on_CreepExit_body_entered(body):
	if body is Creep:
		body.reach_portal()


func _on_WaveSpawner_wave_ended(_wave_index):
	GoldControl.add_income()
	KnowledgeTomesManager.add_knowledge_tomes()
