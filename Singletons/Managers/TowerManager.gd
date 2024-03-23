extends Node


#########################
###       Public      ###
#########################

# Return new unique instance of the Tower by its ID. Get
# script for tower and attach to scene. Script name matches
# with scene name so this can be done automatically instead
# of having to do it by hand in scene editor.
func get_tower(id: int, player: Player) -> Tower:
	var tower: Tower = Preloads.tower_scene.instantiate()
	var tower_script: Variant = _get_tower_script(id)
	tower.set_script(tower_script)
	var tower_sprite: Sprite2D = TowerSprites.get_sprite(id)
	tower.insert_sprite_scene(tower_sprite)
	tower.set_id(id)
	tower.set_player(player)

	return tower


#########################
###      Private      ###
#########################

# Get tower script based on tower scene name.
# Examples:
# TinyShrub1.tscn -> TinyShrub1.gd
# TinyShrub2.tscn -> TinyShrub1.gd
# TinyShrub3.tscn -> TinyShrub1.gd
# ...
func _get_tower_script(id: int) -> Variant:
	var family_name: String = TowerProperties.get_family_name(id)
	var script_path: String = "%s/%s1.gd" % [Constants.TOWERS_DIR, family_name]
	
	var script_exists: bool = ResourceLoader.exists(script_path)
	if !script_exists:
		push_error("No script found for id:", id, ". Tried at path:", script_path)
		
		return null

	var script: Variant = load(script_path)

	return script
