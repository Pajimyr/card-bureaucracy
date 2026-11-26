extends SceneTree
# Automatické testy herní logiky. Bez pluginů, stačí Godot 4.7:
#   godot --headless --path . -s tests/test_runner.gd
# Vrací exit code 0, když všechno prošlo, jinak 1.
#
# Testuje GameState (kariéra, groše, obchod, efekty) a souboj v main.gd
# (zásahy, přebytek, postup zadní karty, start případu podle patra a zboží).

var gs: Node
var passed := 0
var failed := 0
var current := ""


func _initialize() -> void:
	gs = root.get_node("GameState")
	var tests := [
		"test_new_game_defaults",
		"test_win_moves_up_a_floor",
		"test_tutorial_win_does_not_move_up",
		"test_loss_keeps_floor",
		"test_beating_director_wins_career",
		"test_stuck_is_career_over",
		"test_pay_round",
		"test_shop_prices_scale_with_difficulty",
		"test_shop_limits",
		"test_salve_heals_rib",
		"test_vest_and_ribs_change_max_hp",
		"test_sell_hand_and_prosthesis",
		"test_once_items_are_consumed",
		"test_rank_data_is_valid",
	]
	for t in tests:
		current = t
		gs.new_game(1)
		call(t)
	# Testy souboje potřebují instanci scény main, ta žije přes snímky.
	for t in ["test_combat_direct_hit", "test_combat_overflow_and_promotion", "test_case_start_uses_floor_and_items"]:
		current = t
		gs.new_game(1)
		gs.tutorial_done = true
		await call(t)
	print("\n%d prošlo, %d selhalo" % [passed, failed])
	quit(0 if failed == 0 else 1)


func check(cond: bool, what: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("FAIL %s: %s" % [current, what])


func eq(a: Variant, b: Variant, what: String) -> void:
	check(a == b, "%s (čekal jsem %s, je %s)" % [what, str(b), str(a)])


# --- GameState: kariéra -------------------------------------------------------

func test_new_game_defaults() -> void:
	eq(gs.grose, gs.START_GROSE, "startovní groše")
	eq(gs.rank, 0, "začíná se v přízemí")
	eq(gs.effects.size(), 0, "bez efektů")
	check(not gs.career_won(), "nová hra není vyhraná")
	check(not gs.is_stuck(), "nová hra není prohraná")


func test_win_moves_up_a_floor() -> void:
	gs.tutorial_done = true
	gs.finish_case(true)
	eq(gs.rank, 1, "výhra posune o patro")
	eq(gs.grose, gs.START_GROSE + gs.WIN_REWARD, "výhra přidá odměnu")
	eq(gs.cases_won, 1, "počítadlo výher")


func test_tutorial_win_does_not_move_up() -> void:
	gs.finish_case(true, true)
	eq(gs.rank, 0, "tutorial patro nepřidá")
	check(gs.tutorial_done, "tutorial je hotový")


func test_loss_keeps_floor() -> void:
	gs.rank = 2
	gs.finish_case(false)
	eq(gs.rank, 2, "prohra patro nemění")
	eq(gs.last_result, "lose", "výsledek je prohra")
	eq(gs.grose, gs.START_GROSE, "prohra nic nepřidá")


func test_beating_director_wins_career() -> void:
	gs.rank = gs.RANKS.size() - 1
	check(gs.is_boss_case(), "poslední patro je boss")
	gs.finish_case(true)
	check(gs.career_won(), "porážka ředitele = výhra hry")
	check(not gs.is_stuck(), "vyhraná hra není prohraná ani bez grošů")


func test_stuck_is_career_over() -> void:
	gs.grose = 0
	check(not gs.is_stuck(), "s rukama na prodej ještě není konec")
	gs.effects = [{"id": "no_hand", "side": "left"}, {"id": "no_hand", "side": "right"}]
	check(gs.is_stuck(), "bez grošů a bez rukou je konec kariéry")


func test_pay_round() -> void:
	var cost: int = gs.round_cost()
	check(gs.pay_round(), "na kolo je dost grošů")
	eq(gs.grose, gs.START_GROSE - cost, "poplatek se strhne")
	eq(gs.case_number, 2, "číslo případu roste")
	gs.grose = cost - 1
	check(not gs.pay_round(), "bez peněz kolo nejde zaplatit")


# --- GameState: obchod a efekty ---------------------------------------------------

func test_shop_prices_scale_with_difficulty() -> void:
	gs.new_game(0)
	var easy: int = gs.item_price("vest")
	gs.new_game(2)
	var hard: int = gs.item_price("vest")
	check(easy < hard, "na Pátek 14:55 je zboží dražší (%d < %d)" % [easy, hard])
	gs.new_game(1)
	eq(gs.item_price("vest"), gs.ITEMS["vest"]["price"], "na Pondělí ráno základní cena")


func test_shop_limits() -> void:
	gs.grose = 1000
	check(gs.buy_item("bribe"), "úplatek jde koupit")
	eq(gs.item_problem("bribe"), "MÁŠ DOST", "druhý úplatek už ne")
	check(not gs.buy_item("bribe"), "nákup nad limit selže")
	for i in 3:
		check(gs.buy_item("fake_stamp"), "razítko %d" % (i + 1))
	eq(gs.count_effect("fake_stamp"), 3, "max 3 razítka")
	check(not gs.buy_item("fake_stamp"), "čtvrté razítko ne")
	gs.grose = 0
	eq(gs.item_problem("coffee"), "NEMÁŠ NA TO", "bez peněz nic")


func test_salve_heals_rib() -> void:
	gs.grose = 100
	eq(gs.item_problem("salve"), "NEPOTŘEBUJEŠ", "bez žebra mast nejde")
	gs.break_rib()
	gs.break_rib()
	check(gs.buy_item("salve"), "mast jde koupit")
	eq(gs.ribs(), 1, "mast zahojí jedno žebro")
	eq(gs.grose, 100 - gs.item_price("salve"), "mast stojí groše")


func test_vest_and_ribs_change_max_hp() -> void:
	eq(gs.player_max_hp(), gs.PLAYER_MAX_HP, "základ")
	gs.break_rib()
	eq(gs.player_max_hp(), gs.PLAYER_MAX_HP - gs.RIB_HP, "žebro bere HP")
	gs.grose = 100
	gs.buy_item("vest")
	eq(gs.player_max_hp(), gs.PLAYER_MAX_HP - gs.RIB_HP + gs.VEST_HP, "vesta přidá HP")
	for i in 3:
		gs.break_rib()
	eq(gs.ribs(), gs.MAX_RIBS, "víc než 3 žebra se nezlomí")


func test_sell_hand_and_prosthesis() -> void:
	gs.grose = 0
	check(gs.buy_item("sell_hand"), "ruka jde prodat")
	eq(gs.grose, gs.hand_price(), "za ruku jsou groše")
	eq(gs.cards_per_turn(), gs.BASE_CARDS_PER_TURN - 1, "o kartu méně za tah")
	gs.grose = 1000
	check(gs.buy_item("prosthesis"), "protéza jde koupit")
	eq(gs.cards_per_turn(), gs.BASE_CARDS_PER_TURN, "protéza vrátí kartu")
	eq(gs.item_problem("prosthesis"), "NEPOTŘEBUJEŠ", "další protéza není potřeba")
	check(gs.buy_item("sell_hand"), "druhá ruka jde prodat")
	eq(gs.item_problem("sell_hand"), "UŽ NEMÁŠ", "třetí ruka neexistuje")


func test_once_items_are_consumed() -> void:
	gs.grose = 1000
	gs.buy_item("bribe")
	gs.buy_item("coffee")
	gs.buy_item("vest")
	var used: Dictionary = gs.consume_case_items()
	eq(used.get("bribe", 0), 1, "úplatek spotřebován")
	eq(used.get("coffee", 0), 1, "kafe spotřebováno")
	eq(gs.count_effect("bribe") + gs.count_effect("coffee"), 0, "jednorázové efekty zmizí")
	eq(gs.count_effect("vest"), 1, "vesta zůstává")


func test_rank_data_is_valid() -> void:
	var main_script: GDScript = load("res://scripts/main.gd")
	var names := []
	for c in main_script.ENEMY_POOL:
		names.append(c["name"])
	for r in gs.RANKS:
		for n in r["pool"]:
			check(names.has(n), "karta %s z patra %s existuje v ENEMY_POOL" % [n, r["name"]])
		check(r["deck"] > 0 and r["hp"] > 0, "patro %s má balíček a HP" % r["name"])
	check(gs.RANKS[-1].get("boss", false), "poslední patro je boss")


# --- Souboj (scripts/main.gd) -----------------------------------------------------

func _make_case() -> Node:
	var node: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(node)
	await process_frame
	node.player_board = node._empty_board()
	node.enemy_board = node._empty_board()
	return node


func _card(atk: int, hp: int) -> Dictionary:
	return {"name": "Test", "atk": atk, "hp": hp, "max_hp": hp, "uid": randi(), "icon": "form"}


func test_combat_direct_hit() -> void:
	var node: Node = await _make_case()
	node.official_hp = 20
	node.player_board[0] = _card(5, 3)
	node._resolve_combat()
	eq(node.official_hp, 15, "prázdný pruh: útok jde přímo úředníkovi")
	node.queue_free()


func test_combat_overflow_and_promotion() -> void:
	var node: Node = await _make_case()
	node.official_hp = 20
	node.player_hp = 20
	node.player_board[0] = _card(6, 10)
	node.enemy_board[0] = _card(1, 2)   # padne, přebytek 4
	node.enemy_board[3] = _card(1, 10)  # zadní karta dostane přebytek a postoupí
	node._resolve_combat()
	# Průchod 1: hráč 6 → přední karta (2 ŽIV) padne, přebytek 4 jde na zadní (10 → 6).
	#            Přední karta úředníka ještě stihne udeřit (hráčova karta 10 → 9).
	# Úklid: zadní karta postoupí a v průchodu 2 útočí jen ona (9 → 8).
	check(node.enemy_board[3] == null, "zadní karta postoupila dopředu")
	check(node.enemy_board[0] != null, "v přední řadě je postoupivší karta")
	eq(node.enemy_board[0]["hp"], 6, "přebytek 4 propadl na zadní kartu")
	eq(node.player_board[0]["hp"], 8, "hráčova karta schytala dva údery po 1")
	eq(node.player_hp, 20, "hráč nic neschytal přímo")
	node.queue_free()


func test_case_start_uses_floor_and_items() -> void:
	gs.rank = gs.RANKS.size() - 1
	gs.grose = 1000
	gs.buy_item("bribe")
	gs.buy_item("coffee")
	gs.buy_item("fake_stamp")
	var node: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(node)
	await process_frame
	var boss: Dictionary = gs.RANKS[-1]
	eq(node.official_max_hp, boss["hp"], "úředník má HP podle patra")
	eq(node.official_hp, boss["hp"] - gs.BRIBE_HP, "úplatek ubral HP")
	eq(node.cards_per_turn, gs.BASE_CARDS_PER_TURN + 1, "kafe přidalo kartu za tah")
	eq(node.player_deck.size(), gs.diff()["deck_size"] + 1, "razítko je v balíčku navíc")
	eq(node.enemy_deck.size(), boss["deck"], "balíček úředníka podle patra")
	eq(gs.count_effect("bribe"), 0, "úplatek se spotřeboval")
	eq(gs.count_effect("fake_stamp"), 1, "razítko zůstává")
	node.queue_free()
