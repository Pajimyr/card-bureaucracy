extends Node
# Stav jedné hry, přežívá přechody mezi scénami (autoload GameState).
# Groše, obtížnost, patro kariéry, efekty na krysu (debuffy a buffy), číslo případu, heslo.
# Taky přechody mezi scénami se ztmavením obrazovky.
#
# Výhra: krysa vyhraje případ na každém ze čtyř pater úřadu (RANKS). Poslední patro je
# ředitel. Po jeho porážce je kariéra dokončená (career_won) a hra končí scénou ending.
# Prohra: krysa nemá na poplatek za další případ a už nemá ani ruku na prodej (is_stuck).

const START_GROSE := 50
const WIN_REWARD := 20
const BASE_CARDS_PER_TURN := 3
const HAND_SIDES := ["left", "right"]
const PLAYER_MAX_HP := 20
const RIB_HP := 4    # zlomené žebro z rulety bere tolik max HP
const MAX_RIBS := 3  # víc žeber se lámat nedá, další smůla bere aktuální HP
const VEST_HP := 4   # vatovaná vesta přidává tolik max HP
const BRIBE_HP := 6  # úplatek ubere úředníkovi tolik HP na začátku případu

# Patra úřadu. Každé vyhrané (netutoriálové) případy posunou krysu o patro výš.
# pool = jména karet z ENEMY_POOL v main.gd, ze kterých se losuje balíček úředníka.
# Čísla jsou ze simulace tools/balance_sim.py, viz docs/balance.md.
const RANKS := [
	{"name": "Podatelna", "official": "Vrchní podatelna", "case": "Žádost o potvrzení totožnosti",
		"hp": 16, "deck": 8, "pool": ["Úředník podatelny", "Referent", "Revizor"]},
	{"name": "Referát", "official": "Referent", "case": "Žádost o trvalý pobyt v kanálu",
		"hp": 20, "deck": 9, "pool": ["Referent", "Revizor", "Vedoucí odboru", "Úředník podatelny", "Kontrolor"]},
	{"name": "Odbor", "official": "Vedoucí odboru", "case": "Stavební povolení na díru ve zdi",
		"hp": 20, "deck": 8, "pool": ["Referent", "Revizor", "Vedoucí odboru", "Kontrolor"]},
	{"name": "Ředitelství", "official": "Ředitel", "case": "Žádost o povýšení",
		"hp": 24, "deck": 6, "pool": ["Referent", "Revizor", "Vedoucí odboru", "Kontrolor", "Tajemník", "Ředitel"], "boss": true},
]

# Obtížnost mění velikost hráčova balíčku, tempo úředníka (karty za tah), cenu dalšího
# kola a ceny v baru. Čísla vychází ze simulace, viz docs/balance.md.
const DIFFICULTIES := [
	{
		"name": "Úřední hodiny",
		"desc": "Úředníci mají dobrou náladu. Skoro.",
		"deck_size": 10, "enemy_per_turn": 2,
		"round_cost": 8, "hand_price": 25, "prosthesis_price": 30, "item_mult": 0.8,
	},
	{
		"name": "Pondělí ráno",
		"desc": "Běžný provoz. Fronta až na chodbu.",
		"deck_size": 9, "enemy_per_turn": 2,
		"round_cost": 10, "hand_price": 20, "prosthesis_price": 40, "item_mult": 1.0,
	},
	{
		"name": "Pátek 14:55",
		"desc": "Za pět minut zavírají. Všechno je dražší.",
		"deck_size": 8, "enemy_per_turn": 2,
		"round_cost": 15, "hand_price": 15, "prosthesis_price": 55, "item_mult": 1.3,
	},
]

# Typy efektů. kind: "debuff" nebo "buff". icon = assets/icons/card_<icon>.png
# once = efekt platí jen na jeden případ a na jeho začátku se spotřebuje.
const EFFECTS := {
	"no_hand": {"kind": "debuff", "icon": "paw", "short": "-1 karta/tah"},
	"prosthesis": {"kind": "buff", "icon": "prosthesis", "short": "karta zpět"},
	"broken_rib": {"kind": "debuff", "icon": "rib", "short": "-%d HP" % RIB_HP},
	"vest": {"kind": "buff", "icon": "vest", "short": "+%d HP" % VEST_HP},
	"fake_stamp": {"kind": "buff", "icon": "fake_stamp", "short": "+1 karta"},
	"bribe": {"kind": "buff", "icon": "bribe", "short": "úředník -%d" % BRIBE_HP, "once": true},
	"coffee": {"kind": "buff", "icon": "coffee", "short": "+1 karta/tah", "once": true},
}

# Zboží v Honzově obchodě za závěsem (kromě výkupu ruky a protézy, ty mají ceny v DIFFICULTIES).
# price se násobí item_mult obtížnosti. max = kolik kusů může krysa mít najednou.
const ITEMS := {
	"salve": {"title": "Šarlatánova mast", "short": "zahojí žebro", "price": 20, "max": 99,
		"note": "Smrdí, ale žebro sroste."},
	"vest": {"title": "Vatovaná vesta", "short": "+%d max HP" % VEST_HP, "price": 25, "max": 2,
		"note": "Z celty a starých novin."},
	"fake_stamp": {"title": "Padělané razítko", "short": "ÚT 4 / ŽIV 4", "price": 22, "max": 3,
		"note": "Karta navíc v každém případu."},
	"bribe": {"title": "Úplatek", "short": "úředník -%d HP" % BRIBE_HP, "price": 12, "max": 1,
		"note": "Platí na další případ."},
	"coffee": {"title": "Kafe z automatu", "short": "+1 karta/tah", "price": 15, "max": 1,
		"note": "Platí na další případ."},
}
const SHOP_ORDER := ["sell_hand", "prosthesis", "salve", "vest", "fake_stamp", "bribe", "coffee"]

const SIDE_ADJ := {"left": "Levá", "right": "Pravá"}
const SIDE_GEN := {"left": "levé", "right": "pravé"}
const SIDE_ACC := {"left": "levou", "right": "pravou"}

var difficulty: int = 1
var grose: int = START_GROSE
var case_number: int = 1
var rank: int = 0  # index do RANKS; RANKS.size() = kariéra dokončená
var cases_won: int = 0
var cases_lost: int = 0
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
	rank = 0
	cases_won = 0
	cases_lost = 0
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


# Zapíše výsledek případu. Výhra mimo tutorial posune krysu o patro výš.
func finish_case(won: bool, was_tutorial: bool = false) -> void:
	last_result = "win" if won else "lose"
	if won:
		grose += WIN_REWARD
		if was_tutorial:
			tutorial_done = true
		else:
			rank = mini(rank + 1, RANKS.size())
			cases_won += 1
	else:
		cases_lost += 1


# --- Kariéra ---------------------------------------------------------------

# Patro, na kterém se hraje příští (nebo právě běžící) případ.
func current_rank() -> Dictionary:
	return RANKS[mini(rank, RANKS.size() - 1)]


func is_boss_case() -> bool:
	return current_rank().get("boss", false)


# Výhra celé hry: krysa porazila ředitele na posledním patře.
func career_won() -> bool:
	return rank >= RANKS.size()


# Prohra celé hry: krysa nemá na úřad a už nemá co prodat.
func is_stuck() -> bool:
	return not career_won() and not can_afford_round() and not can_sell_hand()


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
		"broken_rib":
			return "Zlomené žebro"
	if ITEMS.has(e["id"]):
		return ITEMS[e["id"]]["title"]
	return str(e["id"])


# Krátký popis efektu pro count stejných kusů (žebra a vesty se sčítají).
func effect_short(id: String, count: int = 1) -> String:
	match id:
		"broken_rib":
			return "-%d HP" % (RIB_HP * count)
		"vest":
			return "+%d HP" % (VEST_HP * count)
		"fake_stamp":
			return "+%d karta" % count if count == 1 else "+%d karty" % count
	return EFFECTS[id]["short"]


func ribs() -> int:
	return count_effect("broken_rib")


func player_max_hp() -> int:
	return PLAYER_MAX_HP - ribs() * RIB_HP + count_effect("vest") * VEST_HP


# Spotřebuje jednorázové efekty (úplatek, kafe) na začátku případu.
# Vrací {"bribe": n, "coffee": n}.
func consume_case_items() -> Dictionary:
	var used := {}
	for id in EFFECTS:
		if EFFECTS[id].get("once", false):
			used[id] = count_effect(id)
	effects = effects.filter(func(e: Dictionary) -> bool: return not EFFECTS[e["id"]].get("once", false))
	return used


# Ruleta zlomí žebro. Vrací false, když už není co lámat.
func break_rib() -> bool:
	if ribs() >= MAX_RIBS:
		return false
	effects.append({"id": "broken_rib"})
	return true


# Ruleta vezme ruku zadarmo. Vrací efekt, nebo prázdný slovník, když už žádná nezbývá.
func lose_hand() -> Dictionary:
	var sides := sellable_sides()
	if sides.is_empty():
		return {}
	var e := {"id": "no_hand", "side": sides.pick_random()}
	effects.append(e)
	return e


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


# --- Honzův obchod: jednotné rozhraní pro všechno zboží (SHOP_ORDER) -----------

func item_price(id: String) -> int:
	match id:
		"sell_hand":
			return hand_price()
		"prosthesis":
			return prosthesis_price()
	return int(round(ITEMS[id]["price"] * diff()["item_mult"]))


# Proč zboží nejde koupit. Prázdný řetězec = jde. Text se ukáže na tlačítku.
func item_problem(id: String) -> String:
	match id:
		"sell_hand":
			return "" if can_sell_hand() else "UŽ NEMÁŠ"
		"prosthesis":
			if hands_lost() == 0:
				return "NEPOTŘEBUJEŠ"
			return "" if grose >= prosthesis_price() else "NEMÁŠ NA TO"
		"salve":
			if ribs() == 0:
				return "NEPOTŘEBUJEŠ"
	if count_effect(id) >= ITEMS[id]["max"]:
		return "MÁŠ DOST"
	if grose < item_price(id):
		return "NEMÁŠ NA TO"
	return ""


# Koupí (nebo u ruky prodá) zboží. Vrací true, když obchod proběhl.
func buy_item(id: String) -> bool:
	if item_problem(id) != "":
		return false
	match id:
		"sell_hand":
			return not sell_hand().is_empty()
		"prosthesis":
			return not buy_prosthesis().is_empty()
		"salve":
			for i in effects.size():
				if effects[i]["id"] == "broken_rib":
					effects.remove_at(i)
					break
		_:
			effects.append({"id": id})
	grose -= item_price(id)
	return true


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
