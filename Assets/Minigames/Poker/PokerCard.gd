extends Resource
class_name PokerCard

enum Suit { CLUB, DIAMOND, SPADE, HEART }

@export var number: int
@export var suit: Suit
@export var card_sprite: Texture2D
