extends ColorRect

var BOARD_WIDTH = 8
var BOARD_HEIGHT = 8

signal background_click


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


func convert_coord(coord):
	var screen_size = get_viewport_rect().size
	return Vector2(int(coord.x / (screen_size.x  / BOARD_WIDTH)), int(coord.y / (screen_size.y / BOARD_HEIGHT)))


func _on_gui_input(event):
	if event is InputEventMouseButton:
		background_click.emit(convert_coord((event.position)))
	pass # Replace with function body.
