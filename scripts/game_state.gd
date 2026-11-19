extends Node
# Stav jedné hry, přežívá přechody mezi scénami (autoload GameState).
# Groše, obtížnost, efekty na krysu (debuffy a buffy), číslo případu, heslo.
# Taky přechody mezi scénami se ztmavením obrazovky.

const START_GROSE := 50
const WIN_REWARD := 20
const BASE_CARDS_PER_TURN := 3
const HAND_SIDES := ["left", "right"]

# Obtížnost mění velikost hráčova balíčku, tempo úředníka (karty za tah), cenu dalšího
# kola a ceny v baru. Čísla vychází ze simulace, viz docs/balance.md.
const DIFFICULTIES := [
	{
		"name": "Úřední hodiny",
		"desc": "Úředníci mají dobrou náladu. Skoro.",
		"deck_size": 12, "enemy_per_turn": 2,
		"round_cost": 8, "hand_price": 25, "prosthesis_price": 30,
	},
	{
		"name": "Pondělí ráno",
		"desc": "Běžný provoz. Fronta až na chodbu.",
		"deck_size": 11, "enemy_per_turn": 2,
		"round_cost": 10, "hand_price": 20, "prosthesis_price": 40,
	},
	{
		"name": "Pátek 14:55",
		"desc": "Za pět minut zavírají. Všechno je dražší.",
		"deck_size": 10, "enemy_per_turn": 2,
		"round_cost": 15, "hand_price": 15, "prosthesis_price": 55,
	},
]

# Typy efektů. kind: "debuff" nebo "buff". icon = assets/icons/card_<icon>.png
const EFFECTS := {
	"no_hand": {"kind": "debuff", "icon": "paw", "short": "-1 karta/tah"},
	"prosthesis": {"kind": "buff", "icon": "prosthesis", "short": "karta zpět"},
}

const SIDE_ADJ := {"left": "Levá", "right": "Pravá"}
const SIDE_GEN := {"left": "levé", "right": "pravé"}
const SIDE_ACC := {"left": "levou", "right": "pravou"}

var difficulty: int = 1
var grose: int = START_GROSE
var case_number: int = 1
var knows_password: bool = false
var tutorial_done: bool = false  # první případ je tutorial; po jeho dohrání se už nehraje
var last_result: String = ""  # "", "win", "lose"
# Efekty na krysu, např. {"id": "no_hand", "side": "left"}.
var effects: Array = []

var _fade_layer: CanvasLayer
var _fade: ColorRect


func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(UiKit.C_DARK, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade)


func new_game(diff: int) -> void:
	difficulty = clampi(diff, 0, DIFFICULTIES.size() - 1)
	grose = START_GROSE
	case_number = 1
	knows_password = false
	tutorial_done = false
	last_result = ""
	effects.clear()


func diff() -> Dictionary:
	return DIFFICULTIES[difficulty]


# --- Groše a kola ----------------------------------------------------------

# Cena dalšího kola na úřadě. Úplně první kolo (z menu) se neplatí.
func round_cost() -> int:
	return diff()["round_cost"]


func can_afford_round() -> bool:
	return grose >= round_cost()


func pay_round() -> bool:
	if not can_afford_round():
		return false
	grose -= round_cost()
	case_number += 1
	return true


func finish_case(won: bool) -> void:
	last_result = "win" if won else "lose"
	if won:
		grose += WIN_REWARD


# Krysa nemá na úřad a už nemá co prodat: konec kariéry.
func is_stuck() -> bool:
	return not can_afford_round() and not can_sell_hand()


# --- Efekty ----------------------------------------------------------------

func count_effect(id: String) -> int:
	var n := 0
	for e in effects:
		if e["id"] == id:
			n += 1
	return n


func hands_lost() -> int:
	return count_effect("no_hand")


func cards_per_turn() -> int:
	return maxi(1, BASE_CARDS_PER_TURN - hands_lost())


func effect_title(e: Dictionary) -> String:
	match e["id"]:
		"no_hand":
			return "Bez %s ruky" % SIDE_GEN[e["side"]]
		"prosthesis":
			return "%s protéza" % SIDE_ADJ[e["side"]]
	return str(e["id"])


# Ruce, které krysa ještě má (prodaná ruka i s protézou už prodat nejde).
func sellable_sides() -> Array:
	var out: Array = []
	for side in HAND_SIDES:
		var taken := false
		for e in effects:
			if e.get("side", "") == side:
				taken = true
		if not taken:
			out.append(side)
	return out


func can_sell_hand() -> bool:
	return not sellable_sides().is_empty()


func hand_price() -> int:
	return diff()["hand_price"]


func prosthesis_price() -> int:
	return diff()["prosthesis_price"]


# Prodá náhodnou ruku. Vrací přidaný efekt, nebo prázdný slovník.
func sell_hand() -> Dictionary:
	var sides := sellable_sides()
	if sides.is_empty():
		return {}
	var e := {"id": "no_hand", "side": sides.pick_random()}
	effects.append(e)
	grose += hand_price()
	return e


func can_buy_prosthesis() -> bool:
	return hands_lost() > 0 and grose >= prosthesis_price()


# Protéza nahradí jednu chybějící ruku. Jizva zůstává vidět jako karta protézy.
func buy_prosthesis() -> Dictionary:
	if not can_buy_prosthesis():
		return {}
	for e in effects:
		if e["id"] == "no_hand":
			e["id"] = "prosthesis"
			grose -= prosthesis_price()
			return e
	return {}


# --- Přechody scén ---------------------------------------------------------

func goto(path: String) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.25)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, 0.3)
	await back.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
