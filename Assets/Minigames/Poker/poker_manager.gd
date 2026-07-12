extends Node3D
class_name PokerManager

@export var p_interaction: Node # Change to your interaction node type
@export var deck: Array[PokerCard] = []

@export var p_card1: Node3D
@export var p_card2: Node3D

@export var npc1_cards: Node3D
@export var npc2_cards: Node3D

@export var t_cards: Array[Node3D] = []
@export var back_card_texture: Texture

#UI
@onready var poker_ui: Control = $PokerUI
@onready var raise_button: TextureButton = $PokerUI/ActionButtons/RaiseButton
@onready var check_button: TextureButton = $PokerUI/ActionButtons/CheckButton
@onready var fold_button: TextureButton = $PokerUI/ActionButtons/FoldButton
@onready var action_buttons: Control = $PokerUI/ActionButtons

@onready var raise_menu: Control = $PokerUI/RaiseMenu
@onready var back_button: TextureButton = $PokerUI/RaiseMenu/BackButton
@onready var bet_button: TextureButton = $PokerUI/RaiseMenu/BetButton
@onready var piggy_button: TextureButton = $PokerUI/RaiseMenu/PiggyButton
@onready var current_bet_text: Label = $PokerUI/RaiseMenu/CurrentBetText



#------------------------------------------------
var npc1_hand: Array[PokerCard] = [null, null]
var npc2_hand: Array[PokerCard] = [null, null]
var player_hand: Array[PokerCard] = [null, null]
var table_cards: Array[PokerCard] = [null, null, null, null, null]

var waiting_player: bool = false
var is_game_active: bool = true
var turn_index: int = 0
var current_bet: int = 0
var raise_bet: int = 5

var npc1_folded: bool = false
var npc2_folded: bool = false

var global_bet: int = 0
var npc1_bet: int = 0
var npc2_bet: int = 0

var current_min_bet: int = 5
var player_bet: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MinigameManager.register_minigame("poker", self)
	
	raise_button.pressed.connect(action_player_raise)
	fold_button.pressed.connect(action_player_fold)
	check_button.pressed.connect(action_player_check)
	
	back_button.pressed.connect(action_leave_bet)
	bet_button.pressed.connect(action_bet)
	piggy_button.pressed.connect(action_raise_bet)
	

func start_minigame():
	#set things up
	current_min_bet = 5
	current_bet = current_min_bet
	player_bet = 5
	npc1_bet = 5
	npc2_bet = 5
	global_bet = 15
	
	for i in range(t_cards.size()):
		t_cards[i].texture = back_card_texture
	
	action_buttons.visible = false
	
	GameManager.current_money -= 5 
	p_card1.visible = true
	p_card2.visible = true
	is_game_active = true

	
	shuffle_deck()
	create_round()
	poker_flow_manager()

func shuffle_deck():
	deck.shuffle()

func create_round():
	npc1_hand[0] = deck[0]
	npc1_hand[1] = deck[1]
	npc2_hand[0] = deck[2]
	npc2_hand[1] = deck[3]
	player_hand[0] = deck[4]
	player_hand[1] = deck[5]

	for i in range(5):
		table_cards[i] = deck[6 + i]
	
	print(table_cards)
	p_card1.texture = player_hand[0].card_sprite
	p_card2.texture = player_hand[1].card_sprite

func poker_flow_manager() -> void:
	# -- PRE-FLOP --
	await npc_turn1(0)
	if npc1_folded: 
		npc1_cards.visible = false

	await player_turn()
	if not is_game_active: return
	
	await npc_turn1(2)
	if npc2_folded: 
		npc2_cards.visible = false
		
	if check_early_win(): return

	# -- THE FLOP --
	print("Flop")
	show_table_cards(0, 2)
	await get_tree().create_timer(1.0).timeout

	if not npc1_folded:
		await npc_turn2(0, 3)
		if npc1_folded: npc1_cards.visible = false

	await player_turn()
	if not is_game_active: return

	if not npc2_folded:
		await npc_turn2(2, 3)
		if npc2_folded: npc2_cards.visible = false

	if check_early_win(): return

	# -- THE TURN --
	print("Turn")
	show_table_cards(2, 4)
	await get_tree().create_timer(1.0).timeout

	if not npc1_folded:
		await npc_turn2(0, 5)
		if npc1_folded: npc1_cards.visible = false

	await player_turn()
	if not is_game_active: return

	if not npc2_folded:
		await npc_turn2(2, 5)
		if npc2_folded: npc2_cards.visible = false

	if check_early_win(): return

	# -- THE RIVER --
	print("River")
	show_table_cards(4, 5)
	await get_tree().create_timer(1.0).timeout

	if not npc1_folded:
		await npc_turn2(0, 5)
		if npc2_folded: npc2_cards.visible = false

	await player_turn()
	if not is_game_active: return

	if not npc2_folded: 
		await npc_turn2(2, 5)
		if npc2_folded: npc2_cards.visible = false

	if check_early_win(): return

	# -- SHOWDOWN --
	var points_npc1: int = calculate_points(npc1_hand)
	var points_npc2: int = calculate_points(npc2_hand)
	var points_player: int = calculate_points(player_hand)

	if (npc1_folded or points_player >= points_npc1) and (npc2_folded or points_player >= points_npc2):
		print("Player wins!")
		# $WinGameAudio.play() 
		GameManager.current_money += global_bet
	else:
		print("Player loses.")
		# $LoseGameAudio.play()

	await get_tree().create_timer(1.0).timeout
	action_player_fold()

# Helper function to clean up repetitive win checks
func check_early_win() -> bool:
	if npc1_folded and npc2_folded:
		print("Player wins because everyone folded!")
		GameManager.current_money += global_bet
		action_player_fold()
		return true
	return false
	
func npc_turn1(npc_index: int):
	var current_npc = npc1_hand if npc_index == 0 else npc2_hand

	if current_npc[0].number + current_npc[1].number < 10 and \
	   (current_npc[0].number != current_npc[1].number or current_npc[0].suit != current_npc[1].suit):
		
		print("I fold!")
		await get_tree().create_timer(1.5).timeout

		if npc_index == 0: npc1_folded = true
		else: npc2_folded = true
	else:
		print("I keep playing!")
		await get_tree().create_timer(1.5).timeout

		if npc_index == 0:
			npc1_bet += 5
			global_bet += 5
		else:
			npc2_bet += 5
			global_bet += 5

	await get_tree().create_timer(1.0).timeout

func npc_turn2(npc_index: int, cards_in_table: int):
	var current_npc = npc1_hand if npc_index == 0 else npc2_hand
	var npc_current_bet = npc1_bet if npc_index == 0 else npc2_bet

	var pressure_fold_chance = (current_min_bet / 100.0) * 5.0
	if randf_range(0.0, 100.0) <= pressure_fold_chance:
		print("NPC ", npc_index, " folds under pressure!")
		await get_tree().create_timer(1.5).timeout

		if npc_index == 0: npc1_folded = true
		else: npc2_folded = true
		await get_tree().create_timer(1.0).timeout
		return
	print("I keep playing!")
	var hand = evaluate_hand(current_npc, table_cards, cards_in_table)
	var bluff = randf_range(0.0, 100.0)
	
	if hand.has_four_of_a_kind or hand.has_full_house or bluff <= 10.0:
		print("I raise my bet!")
		await get_tree().create_timer(1.5).timeout

		var npc_raise_amount = (current_min_bet - npc_current_bet) + 10
		current_min_bet += 10

		if npc_index == 0:
			npc1_bet += npc_raise_amount
			global_bet += npc_raise_amount
		else:
			npc2_bet += npc_raise_amount
			global_bet += npc_raise_amount

func player_turn():
	waiting_player = true
	action_buttons.visible = true
	
	while waiting_player:
		await get_tree().process_frame
		
	action_buttons.visible = false

func show_table_cards(start_pos: int, end_pos: int):
	print(start_pos) 
	print(end_pos)
	
	for i in range(start_pos, end_pos):
		t_cards[i].texture = table_cards[i].card_sprite;
		

func action_player_fold():
	MinigameManager.unregister_minigame("poker")

	is_game_active = false
	p_card1.visible = false
	p_card2.visible = false
	action_buttons.visible = false;
	
	if GameManager.player_interaction:
		GameManager.player_interaction.end_interaction()
		
	waiting_player = false
	
func action_player_raise():
	raise_menu.visible = true
	action_buttons.visible = false

func action_raise_bet():
	if (GameManager.current_money >= 5):
		raise_bet += 5
		GameManager.current_money -= 5
		current_bet_text.text = "$ " + str(raise_bet)

func action_leave_bet():
	raise_menu.visible = false
	action_buttons.visible = true

func action_bet():
	current_bet += raise_bet
	current_bet_text.text = "5"
	raise_bet = current_min_bet
	
	raise_menu.visible = false
	action_buttons.visible = false
	waiting_player = false
	
func action_player_check():
	var callAmount = current_min_bet - player_bet
	
	if (callAmount > 0):
		if (GameManager.current_money >= callAmount):
			player_bet += callAmount;
			global_bet += callAmount;
			GameManager.current_money -= callAmount;
	
		else:
			action_player_fold()
			return
	
	waiting_player = false;

func calculate_points(hand: Array[PokerCard]) -> int:
	var current_hand = evaluate_hand(hand, table_cards, 5)
	
	var all_cards: Array[PokerCard] = []
	all_cards.append_array(hand)
	for i in range(5):
		if table_cards[i] != null:
			all_cards.append(table_cards[i])

	var number_groups = {}
	var suit_groups = {}
	for c in all_cards:
		number_groups[c.number] = number_groups.get(c.number, 0) + 1
		suit_groups[c.suit] = suit_groups.get(c.suit, [])
		suit_groups[c.suit].append(c)

	var score: int = 0

	if current_hand.has_straight_flush:
		var sf_cards: Array = []
		for suit in suit_groups:
			if suit_groups[suit].size() >= 5:
				sf_cards = suit_groups[suit]
				break
		score = _set_hand_score(100, 8, sf_cards)

	elif current_hand.has_four_of_a_kind:
		var four_cards: Array = []
		for num in number_groups:
			if number_groups[num] == 4:
				for c in all_cards:
					if c.number == num: four_cards.append(c)
				break
		score = _set_hand_score(60, 7, four_cards)

	elif current_hand.has_full_house:
		var fh_cards: Array = []
		# Grab all triplets and pairs contributing to the Full House
		for num in number_groups:
			if number_groups[num] == 3 or number_groups[num] == 2:
				for c in all_cards:
					if c.number == num: fh_cards.append(c)
		score = _set_hand_score(40, 4, fh_cards)

	elif current_hand.has_flush:
		var flush_cards: Array = []
		for suit in suit_groups:
			if suit_groups[suit].size() >= 5:
				# Take up to 5 cards matching the suit
				var full_suit_list = suit_groups[suit]
				for i in range(min(5, full_suit_list.size())):
					flush_cards.append(full_suit_list[i])
				break
		score = _set_hand_score(35, 4, flush_cards)

	elif current_hand.has_three_of_a_kind:
		var trips_cards: Array = []
		for num in number_groups:
			if number_groups[num] == 3:
				for c in all_cards:
					if c.number == num: trips_cards.append(c)
				break
		score = _set_hand_score(30, 3, trips_cards)

	elif current_hand.has_two_pair:
		var two_pair_cards: Array = []
		for num in number_groups:
			if number_groups[num] == 2:
				for c in all_cards:
					if c.number == num: two_pair_cards.append(c)
		score = _set_hand_score(20, 2, two_pair_cards)

	elif current_hand.has_pair:
		var pair_cards: Array = []
		for num in number_groups:
			if number_groups[num] == 2:
				for c in all_cards:
					if c.number == num: pair_cards.append(c)
				break
		score = _set_hand_score(10, 2, pair_cards)

	else:
		var highest_card = all_cards[0]
		for c in all_cards:
			if c.number > highest_card.number:
				highest_card = c
		score = _set_hand_score(5, 1, [highest_card])

	return score


func _set_hand_score(base_score: int, multiplier: int, scoring_cards: Array) -> int:
	var card_sum: int = 0
	for c in scoring_cards:
		card_sum += c.number
	
	return base_score + (card_sum * multiplier)

func evaluate_hand(hand: Array[PokerCard], table_cards_arr: Array[PokerCard], cards_in_table: int) -> HandEvaluation:
	var result = HandEvaluation.new()
	var all_cards: Array[PokerCard] = []
	all_cards.append_array(hand)
	
	for i in range(cards_in_table):
		all_cards.append(table_cards_arr[i])

	# Group systems conversions
	var number_groups = {}
	var suit_groups = {}
	
	for c in all_cards:
		number_groups[c.number] = number_groups.get(c.number, 0) + 1
		suit_groups[c.suit] = suit_groups.get(c.suit, [])
		suit_groups[c.suit].append(c)

	var pairs_count = 0
	var trips_count = 0
	var values = number_groups.values()
	
	for count in values:
		if count == 2: pairs_count += 1
		if count == 3: trips_count += 1

	var has_flush = false
	var flush_cards: Array = []
	for suit in suit_groups:
		if suit_groups[suit].size() >= 5:
			has_flush = true
			flush_cards = suit_groups[suit]
			break

	var has_straight = check_for_straight(all_cards)
	var has_straight_flush = false
	if has_flush:
		has_straight_flush = check_for_straight(flush_cards)

	result.has_straight_flush = has_straight_flush
	result.has_four_of_a_kind = 4 in values
	result.has_full_house = (trips_count >= 1 and pairs_count >= 1) or (trips_count >= 2)
	result.has_flush = has_flush
	result.has_straight = has_straight
	result.has_three_of_a_kind = 3 in values
	result.has_two_pair = pairs_count >= 2
	result.has_pair = pairs_count >= 1

	return result

func check_for_straight(cards: Array) -> bool:
	var numbers = []
	for c in cards:
		if not c.number in numbers:
			numbers.append(c.number)
	numbers.sort()
	
	if numbers.size() < 5: return false

	var consecutive_count = 1
	for i in range(numbers.size() - 1):
		if numbers[i + 1] == numbers[i] + 1:
			consecutive_count += 1
			if consecutive_count >= 5: return true
		else:
			consecutive_count = 1
	return false
