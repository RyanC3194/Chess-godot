extends ColorRect

var BOARD_WIDTH = 8
var BOARD_HEIGHT = 8


# Called when the node enters the scene tree for the first time.
func _ready():
	var screen_size = get_viewport_rect().size
	size = Vector2(screen_size.x  / BOARD_WIDTH, 4 * screen_size.y / BOARD_HEIGHT)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
