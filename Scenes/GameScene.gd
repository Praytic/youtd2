extends Node2D


@onready var map_node: Node2D = $Map
var creeps_exit_count: int = 0

@export var creeps_game_over_count: int = 10
@export var ignore_game_over: bool = true


func _on_HUD_start_wave(wave_index):
	$Map/CreepSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$Map/CreepSpawner.stop()


func _on_CreepExit_body_entered(body):
	if body is Creep:
		body.queue_free()


func _on_CreepSpawner_wave_ended(_wave_index: int):
	GoldManager.add_gold()
	KnowledgeTomesManager.add_knowledge_tomes()
