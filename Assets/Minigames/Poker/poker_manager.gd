extends Node3D
class_name PokerManager

@export var p_interaction: Node # Change to your interaction node type
@export var deck: Array[PokerCard] = []

@export var p_card1: Node3D
@export var p_card2: Node3D

@export var npc1_cards: Node3D
@export var npc2_cards: Node3D

@export var t_cards: Array[Node3D] = []

#@export var action_buttons: Control
#@export var raise_bet_hud: Control
#@export var poker_scene: Control
#@export var back_card_sprite: Texture2D

#------------------------------------------------
var npc1_hand: Array[PokerCard] = [null, null]
var npc2_hand: Array[PokerCard] = [null, null]
var player_hand: Array[PokerCard] = [null, null]
var table_cards: Array[PokerCard] = [null, null, null, null, null, null]

var waiting_player: bool = false
var turn_index: int = 0
var current_bet: int = 0
var raise_bet: int = 0

var npc1_folded: bool = false
var npc2_folded: bool = false

var global_bet: int = 0
var npc1_bet: int = 0
var npc2_bet: int = 0

var current_min_bet: int = 5
var player_bet: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_poker()
	create_round()
	print(npc1_hand)

func start_poker():
	#set things up
	current_min_bet = 5
	player_bet = 5
	npc1_bet = 5
	npc2_bet = 5
	global_bet = 15
	
	#GameManager.instance.current_money -= 5
	
	shuffle_deck()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
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

	p_card1.texture = player_hand[0].card_sprite
	p_card2.texture = player_hand[1].card_sprite
