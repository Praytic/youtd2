extends Node2D


@onready var map_node: Node2D = $Map
var creeps_exit_count: int = 0

@export var creeps_game_over_count: int = 10
@export var ignore_game_over: bool = true


func _on_HUD_start_wave(wave_index):
	$Map/CreepSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$Map/CreepSpawner.stop()


func _on_CreepSpawner_progress_changed(progress_string):
	$UI/HUD/VBoxContainer/WaveProgressLabel.text = progress_string


func _on_CreepExit_body_entered(body):
	if body is Creep:
		update_creep_exit_count(creeps_exit_count + 1)

		body.queue_free()
		
		var game_over = creeps_exit_count >= creeps_game_over_count
		
		if game_over && !ignore_game_over:
			do_game_over()


# Updates variable and changes value in label
func update_creep_exit_count(new_value):
	creeps_exit_count = new_value
	
	var creep_count_right_text = "%d/%d" % \
	[creeps_exit_count, creeps_game_over_count]
		
	$UI/HUD/VBoxContainer/HBoxContainer2/CreepCountRight.text = \
	creep_count_right_text


func do_game_over():
	$UI/HUD/GameOverLabel.visible = true


func _on_CreepSpawner_wave_ended(_wave_index: int):
	GoldManager.add_gold()
	KnowledgeTomesManager.add_knowledge_tomes()
