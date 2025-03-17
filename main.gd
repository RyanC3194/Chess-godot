extends Node

@export var piece_scene: PackedScene

var BOARD_WIDTH = 8
var BOARD_HEIGHT = 8
# 2d array for saving the board state
var board = []
# the piece the is selected by clicking on it
var selected_piece
# white's turn to move
var white_turn = true
var attack_map = [] # 2d array, represent which piecce is attacking that square. First dictionary is for white attack map, second dictionary for black attack map
# set.add(value) <-> dict[value] = null
# set.remove(value) <-> dict.erase(value)
# set.has(value) <-> dict.has(value) or value in dict
var color_index = {"White": 0, "Black": 1}
var opposite_color_index = {"White": 1, "Black": 0}
var blocking_squares = [[], []]
var en_passant_ranks = [3, 4]
var en_passant_piece # for en passant

# keep track of kings to calculate checks faster
var kings = [null, null]

# keep track of all the pieces
var piece_list = [[], []]


# Called when the node enters the scene tree for the first time.
func _ready():
	clear_board()
	from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")
	reveal_attack_map()
	for column in board:
		for p in column:
			if (p != null):
				add_to_attack_map(p)
	
	
# THis function makes the attack map not accurate.
func add_piece(type, color, col, row):
	# if the original location has a piece, remove it first
	if (board[col][row] != null):
		$pieces.remove_child(board[row][col])

	
	# set up the board
	var piece = piece_scene.instantiate()
	piece.piece_type = type
	piece.position.x = col * 100 #TODO dont use magic number
	piece.position.y = row * 100
	piece.pos = Vector2(col, row)
	piece.color = color
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
	remove_from_attack_map(piece)
	var removed = []
	for i in range(2):
		for p in attack_map[coord.x][coord.y][i].keys():
			remove_from_attack_map(p)
			removed.append(p)
			
	# keep track of en passant-able piece 
	if (piece.piece_type == "Pawn" && !piece.has_moved && (coord.y - piece.pos.y == 2 || coord.y - piece.pos.y == -2)):
		en_passant_piece = piece
	else:
		en_passant_piece = null
	
	var old_pos = piece.pos
	var col = coord.x
	var row = coord.y
	
	board[piece.pos.x][piece.pos.y] = null
	piece.on_move(coord)
	if (board[col][row]) != null:
		# remove the original piece
		remove_from_attack_map(board[col][row])
		board[col][row].visible = false
		piece_list[opposite_color_index[piece.color]].erase(board[col][row])
	# remove en passant piece
	elif (piece.piece_type == "Pawn" && coord.x != old_pos.x):
		board[col][old_pos.y].visible = false
		piece_list[opposite_color_index[piece.color]].erase(board[col][old_pos.y])
		
	board[col][row] = piece
	white_turn = !white_turn
	
	# check promotion
	if (piece.piece_type == "Pawn" && (row == 0 && piece.color == "White" || row == BOARD_HEIGHT - 1 && piece.color == "Black")):
		promotion(piece)

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
			

	# check if the opponent is checkmated
	print("aa", is_checkmate((o_king.color)))


func promotion(piece):
	#TODO
	$promotion_scene.visible = true
	$Background.enable_click = false
	piece.promote(await $promotion_scene.get_promotion_type(piece))
	$promotion_scene.visible = false
	$Background.enable_click = true

func add_to_attack_map(piece):
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

# for pieces other than kings
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
		if (piece.piece_type == "King" && !piece.has_moved && is_in_check()[color_index[piece.color]] == 0):
			#TODO maybe refractor to a funciion
			#king side
			if (board[piece.pos.x + 1][piece.pos.y] == null && attack_map[piece.pos.x + 1][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
				if (board[piece.pos.x + 2][piece.pos.y] == null && attack_map[piece.pos.x + 2][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
					if (board[piece.pos.x + 3][piece.pos.y] != null && !board[piece.pos.x + 3][piece.pos.y].has_moved && attack_map[piece.pos.x + 3][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
						legal_moves.append(Vector2(piece.pos.x + 2 , piece.pos.y))
			# queenside
			if (board[piece.pos.x - 1][piece.pos.y] == null && attack_map[piece.pos.x - 1][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
				if (board[piece.pos.x - 2][piece.pos.y] == null && attack_map[piece.pos.x - 2][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
					if (board[piece.pos.x - 3][piece.pos.y] == null && attack_map[piece.pos.x - 3][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
						if (board[piece.pos.x - 4][piece.pos.y] != null && !board[piece.pos.x - 4][piece.pos.y].has_moved && attack_map[piece.pos.x - 3][piece.pos.y][opposite_color_index[piece.color]].size() == 0):
							legal_moves.append(Vector2(piece.pos.x - 2 , piece.pos.y))
	return legal_moves

func _on_piece_selected(node):
	for possible_square in get_legal_moves(node):
		$MoveIndicators.move_indicators[possible_square.x][possible_square.y].visible = true
	$MoveIndicators.active_indicator = get_legal_moves(node)

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

func clear_board():
	for height in BOARD_HEIGHT:
		attack_map.append([])
		board.append([])
		for width in BOARD_WIDTH:
			board[height].append(null)
			attack_map[height].append([{}, {}]) # use dictionary as set

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

func reveal_attack_map():
	for x in attack_map.size():
		for y in attack_map[x].size():
			if attack_map[x][y][0].size() != 0:
				$MoveIndicators.move_indicators[x][y].visible = true
				$MoveIndicators.active_indicator.append(Vector2(x, y))

func is_checkmate(color):
	match is_in_check()[color_index[color]]:
		2:
			return get_legal_moves(kings[color_index[color]]).size() == 0
		1:
			for p in piece_list[color_index[color]]:
				if get_legal_moves(p).size() > 0:
					return false;
			return get_legal_moves(kings[color_index[color]]).size() == 0
		0:
			return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("reveal_attack_map"):
		reveal_attack_map()
