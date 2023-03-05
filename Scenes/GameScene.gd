extends Node2D


@onready var map_node: Node2D = $Map
var mobs_exit_count: int = 0

@export var mobs_game_over_count: int = 10
@export var ignore_game_over: bool = true

func _ready():
	randomize()


func _on_HUD_start_wave(wave_index):
	$Map/MobSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$Map/MobSpawner.stop()


func _on_MobSpawner_progress_changed(progress_string):
	$UI/HUD/VBoxContainer/WaveProgressLabel.text = progress_string


func _on_MobExit_body_entered(body):
	if body is Mob:
		update_mob_exit_count(mobs_exit_count + 1)

		body.queue_free()
		
		var game_over = mobs_exit_count >= mobs_game_over_count
		
		if game_over && !ignore_game_over:
			do_game_over()


# Updates variable and changes value in label
func update_mob_exit_count(new_value):
	mobs_exit_count = new_value
	
	var mob_count_right_text = "%d/%d" % \
	[mobs_exit_count, mobs_game_over_count]
		
	$UI/HUD/VBoxContainer/HBoxContainer2/MobCountRight.text = \
	mob_count_right_text


func do_game_over():
	$UI/HUD/GameOverLabel.visible = true


func _on_MobSpawner_wave_ended(_wave_index: int):
	GoldManager.add_gold()
	KnowledgeTomesManager.add_knowledge_tomes()
