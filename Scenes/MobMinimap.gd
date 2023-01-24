extends TextureRect

onready var game_scene: Node = get_tree().get_root().get_node("GameScene")


func _ready():
	pass


func _process(_delta):
	update()


func _draw():
	var objects_node: Node = game_scene.get_node("ObjectYSort")
	
	for node in objects_node.get_children():
		if node is Mob:
			var pos = node.global_position
#			NOTE: Magic numbers from here:
#			https://stackoverflow.com/questions/10506502/what-is-the-connection-between-an-isometric-angle-and-scale
			pos.x /= 1.414213562373095
			pos.y /= (1.414213562373095 * 1/sqrt(3))
#			NOTE: to be more correct, have to rotate *around* the center of the world, which means
#			adding and subtracting the center pos before and after rotating.
#			Since currently center of the world is (0, 0), we can just rotate.
#			Make it more robust by rotating around center. Not sure how to get center pos without
#			hardcoding. 
			pos = pos.rotated(deg2rad(-45))
			pos /= 60
			draw_circle(pos, 2, Color.red)

