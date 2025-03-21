extends Node

@export var piece_scene: PackedScene

var BOARD_WIDTH = 8
var BOARD_HEIGHT = 8
# 2d array for saving the board state
var board = []
# the piece the is selected by clicking on it
var selected_piece
# if its white's turn to move
var white_turn = true

# 2d array, represent which piecce is attacking that square. First dictionary is for white attack map, second dictionary for black attack map
# Since godot has no Set, use Map to imitate Set's behavior
# set.add(value) <-> dict[value] = null
# set.remove(value) <-> dict.erase(value)
# set.has(value) <-> dict.has(value) or value in dict
var attack_map = []

# for variable "kings", "attack_map", "blocking_squares", "en_passant_ranks", white's and black's value are store in a size 2 list.
# e.g. [white's value, black's value]
# this 2 Dictionary convert string representation  
var color_index = {"White": 0, "Black": 1}
var opposite_color_index = {"White": 1, "Black": 0}

var blocking_squares = [[], []]
var en_passant_ranks = [3, 4]
var en_passant_piece # for en passant

# keep track of kings to calculate checks faster
var kings = [null, null]

# keep track of all the pieces
var piece_list = [[], []]

# keep track of all the moves
var move_list = [] # format: [[piece, piece type, new type, original pos, new pos, piece taken, en_passant_piece]


# Called when the node enters the scene tree for the first time.
func _ready():
	clear_board()
	from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")
	

# return the list of pieces removed from attack map from the given coord
func remove_square_from_attack_map(coord):
	var removed = []
	for i in range(2):
		for p in attack_map[coord.x][coord.y][i].keys():
			remove_from_attack_map(p)
			removed.append(p)
	return removed

# 
func un_move():
	var last_move = move_list.pop_back() # [[piece, piece type, new type, original pos, new pos, piece taken]
	if (last_move == null):
		return 
		
	var piece = last_move[0]
	var pt = last_move[1]
	var coord = last_move[3]
	var old_pos = last_move[4]
	var piece_taken = last_move[5]
	en_passant_piece = last_move[6]
	
	var removed = []
	
	remove_from_attack_map(piece)
	
	for i in range(2):
		removed.append_array(remove_square_from_attack_map(coord))
		removed.append_array(remove_square_from_attack_map(old_pos))
			
		# en passant piece
		if piece_taken != null:
			removed.append_array(remove_square_from_attack_map(piece_taken.pos))
			
	board[coord.x][coord.y] = piece
	board[old_pos.x][old_pos.y] = null
	piece.on_unmove(coord, pt)
	
	for p in removed:
		add_to_attack_map(p)
	
	if piece_taken != null:
		piece_taken.active = true
		piece_taken.visible = true
		board[piece_taken.pos.x][piece_taken.pos.y] = piece_taken

	# TODO castle
	
	for p in removed:
		add_to_attack_map(p)
	add_to_attack_map(piece)
	add_to_attack_map(piece_taken)
		
	white_turn = !white_turn
		
		
	

# This function makes the attack map not accurate.
func add_piece(type, color, col, row):
	# if the original location has a piece, remove it first
	if (board[col][row] != null):
		$pieces.remove_child(board[row][col])
	
	# set up the board
	var piece = piece_scene.instantiate()
	piece.init(type, Vector2(col, row), color)
	board[col][row] = piece
	$pieces.add_child(piece)
	if type == "King":
		kings[color_index[color]] = piece
	piece_list[color_index[color]].append(piece)
	
func is_pinned(piece, color):
	# TODO optimize it
	#TODO dont use global variable blockign squares
	var attacked_times = is_in_check()[color_index[color]]
	var pinned = false
	board[piece.pos.x][piece.pos.y] = null
	var ps = []
	var king = kings[color_index[color]]
	for p in attack_map[piece.pos.x][piece.pos.y][opposite_color_index[color]]:
		ps.append(p)
		add_to_attack_map(p)
	if is_in_check()[color_index[color]] - attacked_times != 0:
		pinned = true
	
	if pinned:
		blocking_squares[opposite_color_index[color]] = []
		for p in attack_map[king.pos.x][king.pos.y][opposite_color_index[color]]:
			if p in attack_map[piece.pos.x][piece.pos.y][opposite_color_index[color]]:
				var mag = max(king.pos.x - p.pos.x, king.pos.y - p.pos.y, p.pos.x - king.pos.x, p.pos.y - king.pos.y)
				var offset = (king.pos - p.pos) / mag
				var current = p.pos
				while (current != king.pos):
					blocking_squares[opposite_color_index[color]].append(current)
					current += offset
		
	for p in ps:
		remove_from_attack_map(p)
	board[piece.pos.x][piece.pos.y] = piece
	for p in ps:
		add_to_attack_map(p)
	return pinned

func is_in_check():
	return [attack_map[kings[0].pos.x][kings[0].pos.y][1].size(), attack_map[kings[1].pos.x][kings[1].pos.y][0].size()]

func move_piece(piece, coord):
	var old_pos = piece.pos
	var col = coord.x
	var row = coord.y
	var removed = []
	var new_move = [piece, piece.piece_type, piece.piece_type, piece.pos, coord, board[col][row], en_passant_piece]
	
	remove_from_attack_map(piece)
	
	for i in range(2):
		for p in attack_map[coord.x][coord.y][i].keys():
			remove_from_attack_map(p)
			removed.append(p)
	
			
	# keep track of en passant-able piece 
	if (piece.piece_type == "Pawn" && piece.move_count == 0 && (coord.y - piece.pos.y == 2 || coord.y - piece.pos.y == -2)):
		en_passant_piece = piece
	else:
		en_passant_piece = null
	
	
	board[piece.pos.x][piece.pos.y] = null
	piece.on_move(coord)
	if (board[col][row]) != null:
		# remove the original piece
		remove_from_attack_map(board[col][row])
		board[col][row].visible = false
		board[col][row].active = false
	# remove en passant piece
	elif (piece.piece_type == "Pawn" && coord.x != old_pos.x):
		new_move[-1] = board[col][old_pos.y]
		board[col][old_pos.y].visible = false
		board[col][old_pos.y].active = false
		new_move[5] = board[col][old_pos.y]
		
	board[col][row] = piece
	white_turn = !white_turn
	
	# check promotion
	if (piece.piece_type == "Pawn" && (row == 0 && piece.color == "White" || row == BOARD_HEIGHT - 1 && piece.color == "Black")):
		promotion(piece)
		# update the new piece type to the move list
		new_move[2] = piece.piece_type
	
	move_list.append(new_move)

	for i in range(2):
		for p in attack_map[old_pos.x][old_pos.y][i].keys():
			add_to_attack_map(p)
	add_to_attack_map(piece)
	for p in removed:
		add_to_attack_map(p)
	
	var o_king = kings[opposite_color_index[piece.color]]
	# if the move results in a check, update a list of squares that would stop the check either by capturing the piece checking the king or block it.
	if (is_in_check()[opposite_color_index[piece.color]]) == 1:
		match piece.piece_type:
			"Bishop", "Rook", "Queen":
				var mag = max(o_king.pos.x - piece.pos.x, o_king.pos.y - piece.pos.y, piece.pos.x - o_king.pos.x, piece.pos.y - o_king.pos.y)
				var offset = (o_king.pos - piece.pos) / mag
				var current = piece.pos
				blocking_squares[color_index[piece.color]] = []
				while (current != o_king.pos):
					blocking_squares[color_index[piece.color]].append(current)
					current += offset
			_:
				# capturingt the attack piece
				blocking_squares[color_index[piece.color]].append(piece.pos)
			
	else:
		blocking_squares[color_index[piece.color]] = []
		
	# if the move is castle, also move the rook
	if (piece.piece_type == "King"):
		if (old_pos.x + 2 == coord.x):
			white_turn = !white_turn
			move_piece(board[old_pos.x + 3][old_pos.y], Vector2(old_pos.x + 1, old_pos.y))
		if (old_pos.x - 2 == coord.x):
			white_turn = !white_turn
			move_piece(board[old_pos.x - 4][old_pos.y], Vector2(old_pos.x - 1, old_pos.y))
			

	if (is_checkmate(o_king.color)):
		$HUD.on_win(piece.color)
	print(move_list)


func promotion(piece):
	$promotion_scene.visible = true
	$Background.enable_click = false
	piece.promote(await $promotion_scene.get_promotion_type(piece))
	$promotion_scene.visible = false
	$Background.enable_click = true

func add_to_attack_map(piece):
	if piece == null:
		return
	if piece.piece_type == "Bishop" || piece.piece_type == "Rook" || piece.piece_type == "Queen":
		for diag in piece.possible_squares:
			for move in diag:
				attack_map[move.x][move.y][color_index[piece.color]][piece] = null
				if board[move.x][move.y] != null:
					break
	elif piece.piece_type == "Pawn":
		for move in piece.possible_squares[1]:
			attack_map[move.x][move.y][color_index[piece.color]][piece] = null
		
	else:
		for move in piece.possible_squares:
			attack_map[move.x][move.y][color_index[piece.color]][piece] = null

func remove_from_attack_map(piece):
	if piece.piece_type == "Bishop" || piece.piece_type == "Rook" || piece.piece_type == "Queen":
		for diag in piece.possible_squares:
			for move in diag:
				attack_map[move.x][move.y][color_index[piece.color]].erase(piece)
				if board[move.x][move.y] != null:
					break
	elif piece.piece_type == "Pawn":
		for move in piece.possible_squares[1]:
			attack_map[move.x][move.y][color_index[piece.color]].erase(piece)
		
	else:
		for move in piece.possible_squares:
			if board[move.x][move.y] == null:
				attack_map[move.x][move.y][color_index[piece.color]].erase(piece)

#determine if the resulting move would keep/make the player in check, making it an illegal move
# TODO special case en passant
func is_check_resolved(piece, move):
	if piece.piece_type != "King":
		if is_in_check()[color_index[piece.color]] == 2:
			return false;
		var piece_is_pinned = is_pinned(piece, piece.color)
		if is_in_check()[color_index[piece.color]] == 1:
			if piece_is_pinned:
				return false
			if move in blocking_squares[opposite_color_index[piece.color]]:
				return true
			return false
		else:
			# if the piece is not pinned, or the move would still block the opponent's piece that is pinning this piece
			if !piece_is_pinned || move in blocking_squares[opposite_color_index[piece.color]]:
				return true
			return false
	else:
		return attack_map[move.x][move.y][(color_index[piece.color] + 1) % 2].size() == 0
		
	
func get_legal_moves(piece):
	# if the king is doubled check, other pieces will not be able to resolve the check
	if piece.piece_type != "King" && is_in_check()[color_index[piece.color]] > 1:
			return []
			
	var legal_moves = []
	if piece.piece_type == "Bishop" || piece.piece_type == "Rook" || piece.piece_type == "Queen":
		for diag in piece.possible_squares:
			for move in diag:
				if board[move.x][move.y] == null:
					if is_check_resolved(piece, move):
						legal_moves.append(move)
					continue
				elif (board[move.x][move.y].color != piece.color) && is_check_resolved(piece, move):
					legal_moves.append(move)
				break
	elif piece.piece_type == "Pawn":
		for move in piece.possible_squares[0]:
			if board[move.x][move.y] == null:
				if is_check_resolved(piece, move):
					legal_moves.append(move)
			else:
				break
		# check attacks
		for move in piece.possible_squares[1]:
			if board[move.x][move.y] != null && board[move.x][move.y].color != piece.color && is_check_resolved(piece, move):
				legal_moves.append(move)
			# check en passant
			
			if (piece.pos.y == en_passant_ranks[color_index[piece.color]]):
				if (en_passant_piece != null && board[move.x][piece.pos.y] == en_passant_piece):
					legal_moves.append(move)
				
		
	else:
		for move in piece.possible_squares:
			if board[move.x][move.y] == null or board[move.x][move.y].color != piece.color:
					if is_check_resolved(piece, move):
						legal_moves.append(move)
		# castle
		if (piece.piece_type == "King" && piece.move_count == 0 && is_in_check()[color_index[piece.color]] == 0):
			#TODO maybe refractor to a funciion
			#king side
			if (board[piece.pos.x + 1][piece.pos.y] == null && attack_map[piece.pos.x + 1][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
				if (board[piece.pos.x + 2][piece.pos.y] == null && attack_map[piece.pos.x + 2][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
					if (board[piece.pos.x + 3][piece.pos.y] != null && board[piece.pos.x + 3][piece.pos.y].move_count == 0 && attack_map[piece.pos.x + 3][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
						legal_moves.append(Vector2(piece.pos.x + 2 , piece.pos.y))
			# queenside
			if (board[piece.pos.x - 1][piece.pos.y] == null && attack_map[piece.pos.x - 1][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
				if (board[piece.pos.x - 2][piece.pos.y] == null && attack_map[piece.pos.x - 2][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
					if (board[piece.pos.x - 3][piece.pos.y] == null && attack_map[piece.pos.x - 3][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
						if (board[piece.pos.x - 4][piece.pos.y] != null && board[piece.pos.x - 4][piece.pos.y].move_count == 0 && attack_map[piece.pos.x - 3][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
							legal_moves.append(Vector2(piece.pos.x - 2 , piece.pos.y))
	return legal_moves

func _on_piece_selected(node):
	for possible_square in get_legal_moves(node):
		$MoveIndicators.move_indicators[possible_square.x][possible_square.y].visible = true
	$MoveIndicators.active_indicator = get_legal_moves(node)
	print(node.possible_squares)

# determine which piece is selected when clicked
func _on_background_click(coord):
	$MoveIndicators.clear_indicators()
	if selected_piece != null:
		if coord in get_legal_moves(selected_piece):
			move_piece(selected_piece, coord)
			selected_piece = null
			return
		
	selected_piece = null	
	if board[coord.x][coord.y] != null:
		selected_piece = board[coord.x][coord.y]
		if ((white_turn && selected_piece.color == "White") || (!white_turn) && selected_piece.color == "Black"):
			_on_piece_selected(selected_piece)
		else:
			selected_piece = null

# clear the entire board and attack map
func clear_board():
	for height in BOARD_HEIGHT:
		attack_map.append([])
		board.append([])
		for width in BOARD_WIDTH:
			board[height].append(null)
			attack_map[height].append([{}, {}]) # use dictionary as set

# laod the game to a certain position from fen code
func from_fen(fen):
	var row = 0
	var col = 0
	var notation_dict = {"p": ["Pawn", "Black"], "r": ["Rook", "Black"], "n": ["Knight", "Black"], "b": ["Bishop", "Black"], "q": ["Queen", "Black"], "k": ["King", "Black"], "R": ["Rook", "White"], "N": ["Knight", "White"], "B": ["Bishop", "White"], "Q": ["Queen", "White"], "K": ["King", "White"], "P": ["Pawn", "White"]}
	piece_list = [[], []]
	for c in fen:
		if c == "/":
			row += 1
			col = 0
		elif c in notation_dict.keys():
			add_piece(notation_dict[c][0], notation_dict[c][1], col, row)
			col += 1
		else:
			col += int(c)
			
	for column in board:
		for p in column:
			if (p != null):
				add_to_attack_map(p)

# for debug
func reveal_attack_map():
	for x in attack_map.size():
		for y in attack_map[x].size():
			if attack_map[x][y][0].size() != 0:
				$MoveIndicators.move_indicators[x][y].visible = true
				$MoveIndicators.active_indicator.append(Vector2(x, y))

# determine if a player has no avaliable moves
func is_checkmate(color):
	match is_in_check()[color_index[color]]:
		2:
			return get_legal_moves(kings[color_index[color]]).size() == 0
		1:
			# if the king is checked only one way, other pieces may be able to block or capture the checknig piece
			for p in piece_list[color_index[color]]:
				if p.active && get_legal_moves(p).size() > 0:
					return false;
			return get_legal_moves(kings[color_index[color]]).size() == 0
		0:
			return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("reveal_attack_map"):
		reveal_attack_map()
	elif Input.is_action_just_released("unmove"):
		un_move()
