extends Area2D

var BOARD_WIDTH = 8
var BOARD_HEIGHT = 8

@export_enum("King", "Rook", "Knight", "Bishop", "Pawn", "Queen") var piece_type: String
@export_enum("Black", "White") var color: String
var has_moved = false
var clickable = false
var selected = true
var possible_squares = []
var pos: Vector2
static var king_offsets = [Vector2(1, 1), Vector2(1, 0), Vector2(1, -1), Vector2(0, 1), Vector2(0, -1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1)]
static var knight_offsets = [Vector2(2, 1), Vector2(2, -1), Vector2(-2, 1), Vector2(-2, -1), Vector2(1, 2), Vector2(1, -2), Vector2(-1, 2), Vector2(-1, -2),]
func _ready():
	update_type()
	update_possible_squares()

func promote(pt):
	piece_type = pt
	$Pawn.visible = false
	$PawnDark.visible = false
	_ready()
	
func update_type():
	if (color == "White"):
		if (piece_type == "King"):
			$King.visible = true
		elif (piece_type == "Knight"):
			$Knight.visible = true
		elif (piece_type == "Bishop"):
			$Bishop.visible = true
		elif (piece_type == "Pawn"):
			$Pawn.visible = true
		elif (piece_type == "Rook"):
			$Rook.visible = true
		elif (piece_type == "Queen"):
			$Queen.visible = true
	else:
		if (piece_type == "King"):
			$KingDark.visible = true
		elif (piece_type == "Knight"):
			$KnightDark.visible = true
		elif (piece_type == "Bishop"):
			$BishopDark.visible = true
		elif (piece_type == "Pawn"):
			$PawnDark.visible = true
		elif (piece_type == "Rook"):
			$RookDark.visible = true
		elif (piece_type == "Queen"):
			$QueenDark.visible = true

func calculate_bishop_possible_squares():
	var result = []
	# the order of the directions should not be changed because main.move depends on it
	var offset = Vector2(-1, 1)
	var cur = pos + offset
	var diag = []
	while cur.x >= 0 and cur.y < BOARD_HEIGHT:
		diag.append(cur)
		cur += offset
	result.append(diag)
	
	offset = Vector2(1, 1)
	cur = pos + offset
	diag = []
	while cur.x < BOARD_WIDTH and cur.y < BOARD_HEIGHT:
		diag.append(cur)
		cur += offset
	result.append(diag)
		
	offset = Vector2(1, -1)
	cur = pos + offset
	diag = []
	while cur.x < BOARD_WIDTH and cur.y >= 0:
		diag.append(cur)
		cur += offset
	result.append(diag)
	
	offset = Vector2(-1, -1)
	cur = pos + offset
	diag = []
	while cur.x >= 0 and cur.y >= 0:
		diag.append(cur)
		cur += offset
	result.append(diag)
	
	return result
	
func calculate_rook_possible_squares():
	var result = []
	# dont change order
	var offset = Vector2(0, 1)
	var cur = pos + offset
	var diag = []
	while cur.y < BOARD_HEIGHT:
		diag.append(cur)
		cur += offset
	result.append(diag)

	offset = Vector2(1, 0)
	cur = pos + offset
	diag = []
	while cur.x < BOARD_WIDTH:
		diag.append(cur)
		cur += offset
	result.append(diag)

	offset = Vector2(0, -1)
	cur = pos + offset
	diag = []
	while cur.y >= 0:
		diag.append(cur)
		cur += offset
	result.append(diag)

	offset = Vector2(-1, 0)
	cur = pos + offset
	diag = []
	while cur.x >= 0:
		diag.append(cur)
		cur += offset
	result.append(diag)
	return result
	
# does not take checks into account
func update_possible_squares():
	possible_squares = []
	match piece_type:
		"King":
			for offset in king_offsets:
				var new_pos: Vector2= pos + offset
				if new_pos.x >= 0 &&  new_pos.x < BOARD_WIDTH && new_pos.y >= 0 &&  new_pos.y < BOARD_HEIGHT:
					possible_squares.append(new_pos)
		"Knight":
			for offset in knight_offsets:
				var new_pos: Vector2= pos + offset
				if new_pos.x >= 0 &&  new_pos.x < BOARD_WIDTH && new_pos.y >= 0 &&  new_pos.y < BOARD_HEIGHT:
					possible_squares.append(new_pos)
		"Bishop":
			possible_squares = calculate_bishop_possible_squares()
			
		"Rook":
			possible_squares = calculate_rook_possible_squares()

		"Queen":
			possible_squares = calculate_bishop_possible_squares()
			possible_squares.append_array(calculate_rook_possible_squares())
			
			
		"Pawn":
			var offsets =[Vector2(0, 1)]
			if ((color == "Black" && pos.y == 1) || (color == "White" && pos.y == 6) && !has_moved):
					offsets.append(Vector2(0, 2))
			possible_squares = [[], []]
			for offset in offsets:
				var new_pos: Vector2
				if color == "Black":
					new_pos= pos + offset
				else:
					new_pos = pos + (-1) * offset
				if new_pos.x >= 0 &&  new_pos.x < BOARD_WIDTH && new_pos.y >= 0 &&  new_pos.y < BOARD_HEIGHT:
					possible_squares[0].append(new_pos)
			offsets = [Vector2(1, 1), Vector2(-1, 1)]
			for offset in offsets:
				var new_pos: Vector2
				if color == "Black":
					new_pos= pos + offset
				else:
					new_pos = pos + (-1) * offset
				if new_pos.x >= 0 &&  new_pos.x < BOARD_WIDTH && new_pos.y >= 0 &&  new_pos.y < BOARD_HEIGHT:
					possible_squares[1].append(new_pos)
			
				
	
func on_move(coord):
	has_moved = true
	var col = coord.x
	var row = coord.y
	position.x = col * 100
	position.y = row * 100
	pos =  Vector2(col, row)
	update_possible_squares()
	
func _process(delta):
	pass
	
		





