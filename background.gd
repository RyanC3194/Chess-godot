extends ColorRect

var BOARD_WIDTH = 6
var BOARD_HEIGHT = 6



# Called when the node enters the scene tree for the first time.
func _ready():
	var screen_size = get_viewport_rect().size
	var dark
	$Dark.size = Vector2(screen_size.y / BOARD_HEIGHT, screen_size.x  / BOARD_WIDTH)
	
	for i in range(BOARD_HEIGHT):
		for j in range(BOARD_WIDTH):
			if (i + j) % 2 == 0:
				var cur_position = Vector2(screen_size.y * i / BOARD_HEIGHT, screen_size.x * j / BOARD_WIDTH)
				dark = $Dark.duplicate()
				dark.position = cur_position
				add_child(dark)


	
	

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
