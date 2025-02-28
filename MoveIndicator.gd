extends ColorRect

var BOARD_WIDTH = 6
var BOARD_HEIGHT = 6
var move_indicators = []
var active_indicator = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var screen_size = get_viewport_rect().size
	$MoveIndicator.position = Vector2(screen_size.y  / BOARD_HEIGHT / 2 - 10, screen_size.x  / BOARD_WIDTH / 2 - 10)
	
	for i in range(BOARD_HEIGHT):
		move_indicators.append([])
		for j in range(BOARD_WIDTH):
			var cur_position = Vector2(screen_size.y * i / BOARD_HEIGHT, screen_size.x * j / BOARD_WIDTH)
				
			move_indicators[i].append($MoveIndicator.duplicate())
			move_indicators[i][j].position += cur_position
			add_child(move_indicators[i][j])
			
func clear_indicators():
	for indicator in active_indicator:
		move_indicators[indicator.x][indicator.y].visible = false
	active_indicator = []


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
