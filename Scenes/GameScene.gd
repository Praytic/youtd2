extends Node2D

const mob_scene_map: Dictionary = {
	"Mob": preload("res://Scenes/Mob.tscn")
}


var map_node: Node
var mobs_exit_count: int = 0

export var mobs_game_over_count: int = 10
export var ignore_game_over: bool = true

func _ready():
	map_node = $DefaultMap
	
	$Canvas/HUD/VBoxContainer/HBoxContainer/WaveEdit.value = 1
	$MobSpawner.start(0)
	var _connect_error = $MobSpawner.connect("wave_ended", self, "_on_wave_end")
	
	update_mob_exit_count(0)

func _on_MobSpawner_spawned(mob_name):
	var mob_scene = mob_scene_map[mob_name]
	var mob: Mob = mob_scene.instance()
	mob.set_path($MobPath1)
	
	$MobYSort.add_child(mob)


func _on_HUD_start_wave(wave_index):
	$MobSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$MobSpawner.stop()


func _on_MobSpawner_progress_changed(progress_string):
	$Canvas/HUD/VBoxContainer/WaveProgressLabel.text = progress_string


func _on_MobExit_body_entered(body):
	var body_owner: Node = body.get_owner()
	
	if body_owner is Mob:
		update_mob_exit_count(mobs_exit_count + 1)
		
		var game_over = mobs_exit_count >= mobs_game_over_count
		
		if game_over && !ignore_game_over:
			do_game_over()


# Updates variable and changes value in label
func update_mob_exit_count(new_value):
	mobs_exit_count = new_value
	
	var mob_count_right_text = "%d/%d" % \
	[mobs_exit_count, mobs_game_over_count]
		
	$Canvas/HUD/VBoxContainer/HBoxContainer2/MobCountRight.text = \
	mob_count_right_text


func do_game_over():
	$Canvas/HUD/GameOverLabel.visible = true

func _on_wave_end(_wave_index: int):
	GoldManager.add_gold()
	KnowledgeTomesManager.add_knowledge_tomes()
	


func _on_MobSpawner_wave_ended(_wave_index):
	pass # Replace with function body.
