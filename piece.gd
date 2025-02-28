extends Area2D

var BOARD_WIDTH = 6
var BOARD_HEIGHT = 6

@export_enum("King", "Rook", "Knight", "Bishop", "Pawn") var piece_type: String
@export_enum("Black", "White") var color: String
var clickable = false
var selected = true
var possible_squares = []
signal sig_selected
var pos: Vector2
static var king_offsets = [Vector2(1, 1), Vector2(1, 0), Vector2(1, -1), Vector2(0, 1), Vector2(0, -1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1)]
func _ready():
	update_type()
	calculate_possible_squares()
	
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
	print("asd askd ")
	
# does not take checks into account
func calculate_possible_squares():
	possible_squares = []
	for offset in king_offsets:
		var new_pos: Vector2= pos + offset
		if new_pos.x >= 0 &&  new_pos.x < BOARD_WIDTH && new_pos.y >= 0 &&  new_pos.y < BOARD_HEIGHT:
			possible_squares.append(new_pos)

	
func _process(delta):
	if clickable && Input.is_action_just_pressed("select"):
		sig_selected.emit(self)
	
		
func _on_texture_rect_mouse_entered():
	clickable = true


func _on_texture_rect_mouse_exited():
	clickable = false




