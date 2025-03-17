extends ColorRect

var BOARD_WIDTH = 8
var BOARD_HEIGHT = 8

signal clicked

# Called when the node enters the scene tree for the first time.
func _ready():
	var screen_size = get_viewport_rect().size
	size = Vector2(screen_size.x  / BOARD_WIDTH, 4 * screen_size.y / BOARD_HEIGHT)
	$Queen.position = Vector2(0, 0)
	$Bishop.position = Vector2(0, screen_size.y / BOARD_HEIGHT)
	$Rook.position = Vector2(0, 2 * screen_size.y /  BOARD_HEIGHT)
	$Knight.position = Vector2(0, 3 * screen_size.y / BOARD_HEIGHT)
	$QueenDark.position = Vector2(0, 0)
	$BishopDark.position = Vector2(0, screen_size.y / BOARD_HEIGHT)
	$RookDark.position = Vector2(0, 2 * screen_size.y /  BOARD_HEIGHT)
	$KnightDark.position = Vector2(0, 3 * screen_size.y / BOARD_HEIGHT)

func get_promotion_type(piece):
	if (piece.color == "White"):
		$Queen.visible = true
		$Bishop.visible = true
		$Rook.visible = true
		$Knight.visible = true
		$QueenDark.visible = false
		$BishopDark.visible = false
		$RookDark.visible = false
		$KnightDark.visible = false
		
	else:
		$QueenDark.visible = true
		$BishopDark.visible = true
		$RookDark.visible = true
		$KnightDark.visible = true
		$Queen.visible = false
		$Bishop.visible = false
		$Rook.visible = false
		$Knight.visible = false
	position.x = piece.position.x
	position.y = piece.pos.y / 7 * size.y
	var pos = await clicked
	return pos_to_type(pos)

func pos_to_type(pos):
	if (pos.y < size.y / 4):
		return "Queen"
	if (pos.y < size.y / 2):
		return "Bishop"
	if (pos.y < 3 * size.y / 4):
		return "Rook"
	return "Knight"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_gui_input(event):
	if event is InputEventMouseButton:
		clicked.emit(event.position)
