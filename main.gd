extends Node

@export var piece_scene: PackedScene

var BOARD_WIDTH = 6
var BOARD_HEIGHT = 6
var board = []
var move_indicators_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for height in BOARD_HEIGHT:
		board.append([])
		for width in BOARD_WIDTH:
			board[height].append(null)
		
	add_piece("King", "White", 5, 0)
	add_piece("Pawn", "White", 4, 0)
	add_piece("Rook", "White", 5, 1)
	add_piece("Knight", "White", 5, 2)
	add_piece("Bishop", "White", 5, 3)
	
	add_piece("King", "Black", 0, 5)
	add_piece("Pawn", "Black", 1, 5)
	add_piece("Rook", "Black", 0, 4)
	add_piece("Knight", "Black", 0, 3)
	add_piece("Bishop", "Black", 0, 2)
	pass # Replace with function body.
	

func add_piece(type, color, row, col):
	# if the original location has a piece, remove it first
	if (board[row][col] != null):
		remove_child(board[row][col])
	
	# set up the board
	var piece = piece_scene.instantiate()
	piece.piece_type = type
	piece.position.x = col * 100
	piece.position.y = row * 100
	piece.pos = Vector2(col, row)
	piece.color = color
	piece.sig_selected.connect(_on_piece_sig_selected)
	board[row][col] = piece
	add_child(piece)	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_piece_sig_selected(node):
	$MoveIndicators.clear_indicators()
	print(node.possible_squares)
	for possible_square in node.possible_squares:
		$MoveIndicators.move_indicators[possible_square.x][possible_square.y].visible = true
	$MoveIndicators.active_indicator = node.possible_squares
		
	pass # Replace with function body.
