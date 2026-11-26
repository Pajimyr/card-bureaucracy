extends Control

# Jeden případ: úředník daného patra (GameState.RANKS) proti hráči, střídání tahů.
# Každá strana má 6 míst: 3 pruhy × 2 řady (přední a zadní).
# Index slotu: 0..2 = přední řada pruhů 1..3, 3..5 = zadní řada pruhů 1..3.
# Karta má sílu (ÚT) a health (ŽIV). Oba mají HP.
# V pruhu bojuje přední karta proti přední kartě protivníka.
# Když protivník v pruhu nemá přední kartu, útok jde přímo na jeho HP.
# Když přední karta umře, zadní karta v tom pruhu postoupí a hned útočí.
# Karta na nule je ztracená. Speciální schopnosti zatím nejsou.
# Karty z ruky lze přetáhnout na slot (nebo kliknout kartu a pak slot). Tažená karta se kývá.
#
# Grafika je pixel art v mřížce 640x360 zvětšené 2x. Textury generuje tools/gen_assets.py.

const LANE_COUNT := 3
const SLOT_COUNT := 6
const HAND_SIZE := 5
# Velikost hráčova balíčku a tempo úředníka určuje obtížnost (GameState.DIFFICULTIES, docs/balance.md).
# HP a balíček úředníka určuje patro úřadu (GameState.RANKS).
const PLAYER_MAX_HP := 20  # bez žeber a vest, viz GameState.player_max_hp()
const TUT_OFFICIAL_HP := 20  # HP úředníka v tutorialu; jinak podle patra (GameState.RANKS)
const OFFICIAL_NAME := "Úředník"
const ENEMY_TURN_DELAY := 0.8
const SIDE_COLUMN_WIDTH := 230
const MAX_CARDS_PER_TURN := 3  # základ pro hráče; useknuté ruce ho snižují (GameState.cards_per_turn)
const MAX_ENERGY_ICONS := 4  # 3 + kafe z automatu

# Tutorial (první případ, dokud GameState.tutorial_done není true): menší balíčky, jeden úředník
# za tah a nejde prohrát. Mrtvé karty se vracejí do balíčku, HP hráče neklesne pod 1.
const TUT_PLAYER_CARDS := ["Razítko", "Formulář B-7", "Úřední lhůta", "Ověřená kopie", "Podpis pod tlakem", "Výpis z rejstříku", "Kopie kopie", "Stížnost"]
const TUT_ENEMY_CARDS := ["Referent", "Úředník podatelny", "Revizor"]
const TUT_ENEMY_CARDS_PER_TURN := 1
const EFFECT_STEP := 0.3
const CARD_SIZE := Vector2(160, 104)
const HAND_LIFT := 14.0  # o kolik se karta v ruce zvedne pod myší
const FLY_TIME := 0.4
const DRAG_THRESHOLD := 8.0
const DRAG_SCALE := 0.75
const PENDULUM_G := 2000.0
const PENDULUM_DAMP := 6.0
const ENEMY_HAND_SHOWN := 3
const PHYS_STEP := 1.0 / 240.0
const VEL_SMOOTH := 40.0  # jak rychle se vyhlazuje rychlost myši (vyšší = méně zpoždění, víc šumu)
const ACC_SMOOTH := 25.0  # vyhlazení zrychlení myši
const MAX_HAND_ACC := 6000.0
const SWING_GAIN := 0.2  # jak silně vodorovné zrychlení ruky houpe kartou
const MAX_PHI := 0.5  # max. náklon karty (rad), aby se nikdy neprotočila
const MAX_PHI_VEL := 8.0

# Pixel font má základní velikost 12 a škáluje se jen celočíselně.
const FS_S := UiKit.FS_S
const FS_M := UiKit.FS_M
const FS_L := UiKit.FS_L
const FS_XL := UiKit.FS_XL

enum Phase { PLAYER, ENEMY, OVER }

# Šablony karet. Každá instance dostane vlastní uid, max_hp a aktuální hp.
# icon = soubor assets/icons/card_<icon>.png
const CARD_POOL := [
	{"name": "Formulář B-7", "atk": 2, "hp": 3, "icon": "form"},
	{"name": "Razítko", "atk": 3, "hp": 2, "icon": "stamp"},
	{"name": "Žádost o žádost", "atk": 1, "hp": 5, "icon": "envelope"},
	{"name": "Úřední lhůta", "atk": 4, "hp": 2, "icon": "hourglass"},
	{"name": "Kopie kopie", "atk": 1, "hp": 2, "icon": "copies"},
	{"name": "Nahlédnutí do spisu", "atk": 1, "hp": 4, "icon": "magnifier"},
	{"name": "Podpis pod tlakem", "atk": 5, "hp": 4, "icon": "pen"},
	{"name": "Ověřená kopie", "atk": 2, "hp": 4, "icon": "certified"},
	{"name": "Stížnost", "atk": 2, "hp": 3, "icon": "complaint"},
	{"name": "Výpis z rejstříku", "atk": 3, "hp": 3, "icon": "folder"},
]

const ENEMY_POOL := [
	{"name": "Referent", "atk": 2, "hp": 4, "icon": "referent"},
	{"name": "Revizor", "atk": 3, "hp": 3, "icon": "revizor"},
	{"name": "Vedoucí odboru", "atk": 4, "hp": 4, "icon": "vedouci"},
	{"name": "Úředník podatelny", "atk": 1, "hp": 3, "icon": "podatelna"},
	{"name": "Kontrolor", "atk": 3, "hp": 5, "icon": "kontrolor"},
	{"name": "Tajemník", "atk": 3, "hp": 6, "icon": "vedouci"},
	{"name": "Ředitel", "atk": 5, "hp": 6, "icon": "reditel"},
]

# Karty z černého trhu: do balíčku se přidají navíc podle efektů krysy (GameState.ITEMS).
const BLACK_MARKET_CARDS := {
	"fake_stamp": {"name": "Padělané razítko", "atk": 4, "hp": 4, "icon": "fake_stamp"},
}

# Paleta a velikosti fontu jsou v UiKit.
const C_INK := UiKit.C_INK
const C_PAPER := UiKit.C_PAPER
const C_PAPER_DIM := UiKit.C_PAPER_DIM
const C_GOLD := UiKit.C_GOLD
const C_GOLD_LIGHT := UiKit.C_GOLD_LIGHT
const C_RED := UiKit.C_RED
const C_RED_LIGHT := UiKit.C_RED_LIGHT
const C_BLUE_LIGHT := UiKit.C_BLUE_LIGHT
const C_GREEN := UiKit.C_GREEN
const C_GREY := UiKit.C_GREY
const C_DARK := UiKit.C_DARK

const COLOR_TEXT := C_PAPER
const COLOR_MUTED := C_GREY
const COLOR_ATTACK := Color(1.0, 0.92, 0.45)
const COLOR_HIT := Color(1.0, 0.4, 0.4)
const COLOR_PLACE := Color(0.6, 1.0, 0.6)
const COLOR_ENEMY_PLACE := Color(1.0, 0.75, 0.75)

var phase: Phase = Phase.PLAYER
var turn: int = 1
var next_uid: int = 0
var selected_uid: int = -1
var player_hp: int = PLAYER_MAX_HP
var player_max_hp: int = PLAYER_MAX_HP  # sníží ho zlomená žebra z rulety
var official_max_hp: int = TUT_OFFICIAL_HP
var official_hp: int = TUT_OFFICIAL_HP
var coffee_bonus: int = 0  # kafe z automatu: +1 karta za tah, jen v tomto případu
var placed_this_turn: int = 0
var cards_per_turn: int = MAX_CARDS_PER_TURN  # hráčův limit, viz GameState.cards_per_turn()
var enemy_cards_per_turn: int = 2
var tutorial: bool = false
var tut_dialog: DialogBox
# Zásahy a útoky z aktuálního tahu, přehrají se postupně jako vizuální efekty.
var hit_events: Array = []

# Balíčky obsahují všechny živé karty dané strany (včetně karet na stole a v ruce).
var player_deck: Array = []
var enemy_deck: Array = []
# Ruka hráče a obsazení slotů (null = prázdný slot). Indexy viz záhlaví souboru.
var hand: Array = []
var player_board: Array = []
var enemy_board: Array = []

# Sloty, do kterých právě letí karta. Jejich obsah se do konce letu nevykresluje.
var hidden_slots: Dictionary = {}
# Panely karet v ruce podle uid.
var hand_panels: Dictionary = {}

# Stav tažení karty.
var drag_pending: bool = false
var dragging: bool = false
var drag_uid: int = -1
var drag_start: Vector2 = Vector2.ZERO
var drag_node: PanelContainer = null
var hand_pos: Vector2 = Vector2.ZERO  # pozice ruky = kurzor
var drag_last_mouse: Vector2 = Vector2.ZERO
var drag_vel_s: Vector2 = Vector2.ZERO  # vyhlazená rychlost myši
var drag_acc_s: Vector2 = Vector2.ZERO  # vyhlazené zrychlení myši
var drag_acc_time: float = 0.0
var drag_grab: Vector2 = Vector2.ZERO  # bod uchopení v lokálních souřadnicích karty
var drag_phi: float = 0.0  # výchylka kyvadla
var drag_phi_vel: float = 0.0
var enemy_hand_area: Control
var enemy_hand_label: Label
var enemy_hand_backs: Array = []

var font: FontFile
var hand_box: HBoxContainer
var turn_label: Label
var phase_label: Label
var energy_icons: Array = []
var confirm_btn: Button
var log_label: RichTextLabel
var official_bar: ProgressBar
var official_label: Label
var player_bar: ProgressBar
var player_label: Label
var player_deck_label: Label
var player_slot_contents: Array = []  # CenterContainer podle indexu slotu
var enemy_slot_contents: Array = []
var player_slot_panels: Array = []
var enemy_slot_panels: Array = []
var official_panel: PanelContainer
var official_portrait: CharacterPortrait
var player_portrait: CharacterPortrait
var player_panel: PanelContainer
var log_lines: Array[String] = []

var style_slot_player: StyleBoxTexture
var style_slot_valid: StyleBoxTexture


func _ready() -> void:
	randomize()
	RenderingServer.set_default_clear_color(C_DARK)
	player_max_hp = GameState.player_max_hp()
	player_hp = player_max_hp
	tutorial = not GameState.tutorial_done
	player_board = _empty_board()
	enemy_board = _empty_board()
	var used := {}
	if tutorial:
		player_deck = _make_fixed_deck(TUT_PLAYER_CARDS, CARD_POOL)
		enemy_deck = _make_fixed_deck(TUT_ENEMY_CARDS, ENEMY_POOL)
		enemy_cards_per_turn = TUT_ENEMY_CARDS_PER_TURN
	else:
		var rank: Dictionary = GameState.current_rank()
		player_deck = _make_deck(CARD_POOL, GameState.diff()["deck_size"])
		for id in BLACK_MARKET_CARDS:
			player_deck += _make_fixed_deck([BLACK_MARKET_CARDS[id]["name"]], [BLACK_MARKET_CARDS[id]], GameState.count_effect(id))
		var pool := ENEMY_POOL.filter(func(c: Dictionary) -> bool: return rank["pool"].has(c["name"]))
		enemy_deck = _make_deck(pool, rank["deck"])
		enemy_cards_per_turn = GameState.diff()["enemy_per_turn"]
		official_max_hp = rank["hp"]
		# Jednorázové zboží z baru se spotřebuje teď, na začátku případu.
		used = GameState.consume_case_items()
		coffee_bonus = used.get("coffee", 0)
	official_hp = maxi(1, official_max_hp - used.get("bribe", 0) * GameState.BRIBE_HP)
	cards_per_turn = GameState.cards_per_turn() + coffee_bonus
	_build_ui()
	tut_dialog = DialogBox.new()
	add_child(tut_dialog)
	_fill_hand()
	_begin()


# Balíček z pojmenovaných šablon (tutorial, karty z černého trhu). Každá karta dostane
# vlastní uid. copies = kolik kusů od každého jména.
func _make_fixed_deck(names: Array, pool: Array, copies: int = 1) -> Array:
	var deck: Array = []
	for n in names:
		for tpl in pool:
			if tpl["name"] == n:
				for i in copies:
					var card: Dictionary = tpl.duplicate()
					card["uid"] = next_uid
					next_uid += 1
					card["max_hp"] = card["hp"]
					deck.append(card)
	return deck


# Úvod: hraješ první, úředník nasazuje až po potvrzení tvého tahu.
func _begin() -> void:
	phase = Phase.PLAYER
	_log("Případ začíná. Přetáhni kartu z ruky na volný slot, nebo klikni kartu a pak slot.")
	if official_hp < official_max_hp:
		_log("Úplatek zabral: úředník začíná na %d HP." % official_hp)
	if coffee_bonus > 0:
		_log("Kafe z automatu: tento případ hraješ o kartu víc za tah.")
	_refresh()
	_banner("TVŮJ TAH", C_GOLD_LIGHT)
	if tutorial:
		_tutorial_intro.call_deferred()


# --- Tutorial --------------------------------------------------------------
# Blokující dialogy v předem daných bodech tahu. Běží jen v prvním případu.

func _tut(lines: Array) -> void:
	if tutorial:
		await tut_dialog.run(lines)


func _tutorial_intro() -> void:
	await _tut([
		{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": Color("#b45cff"),
			"text": "Zkouška. Úřad tě nechce zabít, jen zkontrolovat, jestli umíš číst formuláře."},
		{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": Color("#b45cff"),
			"text": "Dole máš karty v ruce. Přetáhni jednu na volný slot ve své přední řadě (horní řada zdola)."},
		{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": Color("#b45cff"),
			"text": "Na tah smíš zahrát tři karty. Až budeš hotov, klikni na POTVRDIT TAH. Úředník pak odpovídá."},
		{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": Color("#b45cff"),
			"text": "Tady prohrát nemůžeš. Padlé karty se ti vrátí. Venku už ti nikdo nic nevrátí."},
	])


func _empty_board() -> Array:
	var board: Array = []
	board.resize(SLOT_COUNT)
	board.fill(null)
	return board


# --- Styl: textury, font, téma ---------------------------------------------

# Sdílené styly žijí v UiKit, tady jen krátké zkratky.
func _tex(file: String) -> Texture2D:
	return UiKit.tex(file)


func _tex_style(file: String, margin: int, content: int = -1, tile: bool = false) -> StyleBoxTexture:
	return UiKit.tex_style(file, margin, content, tile)


func _make_label(text: String, font_size: int, color: Color = COLOR_TEXT, shadow: bool = false) -> Label:
	return UiKit.label(text, font_size, color, shadow)


# --- Stavba UI -------------------------------------------------------------

func _build_ui() -> void:
	theme = UiKit.theme()
	font = UiKit.font()
	style_slot_player = _tex_style("ui/slot_player.png", 12, 4)
	style_slot_valid = _tex_style("ui/slot_valid.png", 12, 4)

	var bg := TextureRect.new()
	bg.texture = _tex("bg/city.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	root.add_child(_make_header())

	# Střed: levý sloupec (portréty), stůl s pruhy, pravý sloupec (stav, protokol, razítko)
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	left.add_theme_constant_override("separation", 10)
	main.add_child(left)
	left.add_child(_make_official_panel())
	left.add_child(_make_player_panel())

	main.add_child(_make_board())

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	right.add_theme_constant_override("separation", 10)
	main.add_child(right)
	right.add_child(_make_status_panel())
	right.add_child(_make_log_panel())
	confirm_btn = Button.new()
	confirm_btn.text = "POTVRDIT TAH"
	confirm_btn.custom_minimum_size = Vector2(0, 64)
	confirm_btn.pressed.connect(_on_confirm_turn)
	right.add_child(confirm_btn)

	# Ruka na hraně stolu
	var hand_area := PanelContainer.new()
	hand_area.custom_minimum_size = Vector2(0, CARD_SIZE.y + HAND_LIFT + 4)
	var strip := _tex_style("ui/hand_strip.png", 8, 0, true)
	strip.content_margin_top = 6
	hand_area.add_theme_stylebox_override("panel", strip)
	root.add_child(hand_area)
	hand_box = HBoxContainer.new()
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_box.add_theme_constant_override("separation", 14)
	hand_area.add_child(hand_box)


func _make_header() -> Control:
	var header := PanelContainer.new()
	var sb := _tex_style("ui/plaque.png", 12)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	header.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	header.add_child(hb)
	var rank: Dictionary = GameState.current_rank()
	hb.add_child(_make_label("PŘÍPAD Č. %d" % GameState.case_number, FS_M, C_GOLD_LIGHT, true))
	var what: String = "Zkouška: vyplň formulář" if tutorial else rank["case"]
	hb.add_child(_make_label("  ·  %s" % what, FS_M, C_PAPER, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spacer)
	var floor_text := "MĚSTSKÝ ÚŘAD · VRÁTNICE" if tutorial else \
		"PATRO %d/%d · %s" % [GameState.rank + 1, GameState.RANKS.size(), rank["name"].to_upper()]
	hb.add_child(_make_label(floor_text, FS_S * 2, C_RED_LIGHT if GameState.is_boss_case() and not tutorial else C_PAPER_DIM, true))
	return header


# Stůl: nahoře úředník za sklem, uprostřed hrana přepážky, dole tvůj stůl.
func _make_board() -> Control:
	var board := VBoxContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_theme_constant_override("separation", 0)

	enemy_slot_contents.resize(SLOT_COUNT)
	player_slot_contents.resize(SLOT_COUNT)
	enemy_slot_panels.resize(SLOT_COUNT)
	player_slot_panels.resize(SLOT_COUNT)

	var enemy_desk := _make_desk("ui/desk_enemy.png")
	board.add_child(enemy_desk)
	var ev: VBoxContainer = enemy_desk.get_child(0)
	_add_board_row(ev, "zadní", enemy_slot_contents, enemy_slot_panels, LANE_COUNT, false)
	_add_board_row(ev, "přední", enemy_slot_contents, enemy_slot_panels, 0, false)

	board.add_child(_make_counter())

	var player_desk := _make_desk("ui/desk_player.png")
	board.add_child(player_desk)
	var pv: VBoxContainer = player_desk.get_child(0)
	_add_board_row(pv, "přední", player_slot_contents, player_slot_panels, 0, true)
	_add_board_row(pv, "zadní", player_slot_contents, player_slot_panels, LANE_COUNT, true)
	return board


func _make_desk(file: String) -> PanelContainer:
	var desk := PanelContainer.new()
	desk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desk.add_theme_stylebox_override("panel", _tex_style(file, 4, 8, true))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	desk.add_child(vb)
	return desk


func _make_counter() -> Control:
	var counter := Control.new()
	counter.custom_minimum_size = Vector2(0, 24)
	var strip := TextureRect.new()
	strip.texture = _tex("ui/counter.png")
	strip.stretch_mode = TextureRect.STRETCH_TILE
	strip.set_anchors_preset(Control.PRESET_FULL_RECT)
	counter.add_child(strip)
	var sign := PanelContainer.new()
	var sb := _tex_style("ui/counter_sign.png", 8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 2
	sb.content_margin_bottom = 4
	sign.add_theme_stylebox_override("panel", sb)
	sign.add_child(_make_label("PŘEPÁŽKA Č. 3", FS_S, C_PAPER))
	sign.set_anchors_preset(Control.PRESET_CENTER)
	sign.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sign.grow_vertical = Control.GROW_DIRECTION_BOTH
	counter.add_child(sign)
	return counter


# Jedna řada: 3 sloty. Pokud is_player, jsou klikatelné a index slotu je first_index + pruh.
func _add_board_row(parent: Control, row_name: String, contents: Array, panels: Array, first_index: int, is_player: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	for lane in LANE_COUNT:
		var idx := first_index + lane
		var click_index := idx if is_player else -1
		var slot := _make_slot(row, row_name, is_player, click_index)
		contents[idx] = slot["content"]
		panels[idx] = slot["panel"]


func _make_slot(parent: Control, row_name: String, is_player: bool, click_index: int = -1) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, CARD_SIZE.y + 8)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", style_slot_player if is_player else _tex_style("ui/slot_enemy.png", 12, 4))
	panel.set_meta("row_name", row_name)
	parent.add_child(panel)

	var content := CenterContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	if click_index >= 0:
		panel.gui_input.connect(_on_slot_input.bind(click_index))
	return {"panel": panel, "content": content}


# Rám portrétu + jméno + HP. Vrací [panel, vbox pro další obsah, hp label, hp bar, portrét].
func _make_character_panel(style_file: String, portrait: String, title: String, subtitle: String, title_color: Color, bar_file: String, max_hp: int) -> Array:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _tex_style(style_file, 12, 14))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	vb.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _tex_style("ui/plaque.png", 8, 4))
	top.add_child(frame)
	var pic := CharacterPortrait.new()
	pic.setup(portrait, 80)
	frame.add_child(pic)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	top.add_child(info)
	info.add_child(_make_label(title, FS_M, title_color, true))
	info.add_child(_make_label(subtitle, FS_S, COLOR_MUTED))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_child(spacer)
	var hp_label := _make_label("", FS_M, COLOR_TEXT, true)
	info.add_child(hp_label)

	var bar := _make_bar(max_hp, bar_file, "ui/bar_bg.png", 4)
	bar.custom_minimum_size = Vector2(0, 18)
	vb.add_child(bar)
	return [panel, vb, hp_label, bar, pic]


func _make_official_panel() -> PanelContainer:
	var title := "ÚŘEDNÍK"
	var subtitle := "Vrátný zkoušející"
	if not tutorial:
		var rank: Dictionary = GameState.current_rank()
		title = rank["official"].to_upper()
		subtitle = "Boss · poslední patro" if rank.get("boss", false) else "Patro %d" % (GameState.rank + 1)
	var parts := _make_character_panel("ui/panel_enemy.png", "portraits/official.png", title, subtitle, C_RED_LIGHT, "ui/bar_red.png", official_max_hp)
	official_panel = parts[0]
	official_portrait = parts[4]
	official_label = parts[2]
	official_bar = parts[3]
	(parts[1] as VBoxContainer).add_child(_make_enemy_hand())
	return official_panel


# Ruka úředníka: rubové strany karet, ze kterých jeho karty vylétají.
func _make_enemy_hand() -> Control:
	var area := Control.new()
	area.custom_minimum_size = Vector2(0, 74)
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_hand_area = area
	var offsets := [Vector2(110, 12), Vector2(136, 6), Vector2(162, 12)]
	var rots := [-0.14, 0.0, 0.14]
	for i in ENEMY_HAND_SHOWN:
		var back := TextureRect.new()
		back.texture = _tex("ui/card_back_small.png")
		back.size = Vector2(46, 60)
		back.position = offsets[i]
		back.pivot_offset = back.size / 2.0
		back.rotation = rots[i]
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(back)
		enemy_hand_backs.append(back)
	var cap := _make_label("RUKA", FS_S, COLOR_MUTED)
	cap.position = Vector2(0, 14)
	area.add_child(cap)
	enemy_hand_label = _make_label("", FS_L, C_PAPER, true)
	enemy_hand_label.position = Vector2(0, 30)
	area.add_child(enemy_hand_label)
	return area


func _make_player_panel() -> PanelContainer:
	var parts := _make_character_panel("ui/panel_player.png", "portraits/player.png", "TY", "Krysa bez razítka", C_BLUE_LIGHT, "ui/bar_green.png", player_max_hp)
	player_panel = parts[0]
	player_portrait = parts[4]
	player_label = parts[2]
	player_bar = parts[3]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_icon("icons/deck.png"))
	player_deck_label = _make_label("", FS_M, COLOR_TEXT, true)
	row.add_child(player_deck_label)
	(parts[1] as VBoxContainer).add_child(row)
	return player_panel


func _make_status_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _tex_style("ui/panel_frame.png", 12, 14))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	turn_label = _make_label("", FS_L, C_GOLD, true)
	vb.add_child(turn_label)
	phase_label = _make_label("", FS_M, C_PAPER, true)
	vb.add_child(phase_label)
	vb.add_child(_make_label("ZAHRANÉ KARTY", FS_S, COLOR_MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	for i in MAX_ENERGY_ICONS:
		var icon := _make_icon("icons/energy_on.png")
		row.add_child(icon)
		energy_icons.append(icon)
	return panel


# Protokol: papír, nejnovější zápis dole. Starší řádky přetečou nahoru a oříznou se.
func _make_log_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := _tex_style("ui/paper.png", 12, 14)
	sb.content_margin_left = 18
	sb.content_margin_right = 16
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	vb.add_child(_make_label("PROTOKOL", FS_S, C_PAPER_DIM))
	var clip := Control.new()
	clip.clip_contents = true
	clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(clip)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.fit_content = true
	log_label.scroll_active = false
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_label.add_theme_font_override("normal_font", font)
	log_label.add_theme_font_size_override("normal_font_size", FS_M)
	log_label.add_theme_color_override("default_color", C_INK)
	log_label.add_theme_constant_override("paragraph_separation", 6)
	log_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	log_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	clip.add_child(log_label)
	return panel


func _make_icon(file: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = _tex(file)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


# Vizuál karty: papír (hráč) nebo služební průkaz (úředník), ikona, jméno, ÚT, ŽIV a pruh.
func _make_card_view(card: Dictionary, is_player: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	panel.size = CARD_SIZE
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_card(panel, card, is_player)
	return panel


func _fill_card(panel: PanelContainer, card: Dictionary, is_player: bool) -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	var sb := _tex_style("ui/card_player.png" if is_player else "ui/card_enemy.png", 12, 8)
	sb.content_margin_top = 8 if is_player else 14
	sb.content_margin_left = 8
	panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)
	var icon := TextureRect.new()
	icon.texture = _tex("icons/card_%s.png" % card.get("icon", "form"))
	icon.custom_minimum_size = Vector2(32, 32)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(icon)
	# Pevná šířka jména: bez ní se zalomení počítá při šířce 0 a karta se natáhne.
	var name_label := _make_label(card["name"], FS_M, C_INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(CARD_SIZE.x - 16 - 32 - 6 - 4, 0)
	name_label.max_lines_visible = 2
	top.add_child(name_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	vb.add_child(stats)
	stats.add_child(_make_icon("icons/atk.png"))
	stats.add_child(_make_label(str(card["atk"]), FS_M, Color("#8a1e28")))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(gap)
	stats.add_child(_make_icon("icons/hp.png"))
	var hp_now: int = maxi(card["hp"], 0)
	var hp_color := Color("#2f8a44") if hp_now >= card["max_hp"] else Color("#8a1e28")
	stats.add_child(_make_label("%d/%d" % [hp_now, card["max_hp"]], FS_M, hp_color))

	var bar := _make_bar(card["max_hp"], "ui/bar_small_fill.png", "ui/bar_small_bg.png", 2)
	bar.custom_minimum_size = Vector2(0, 6)
	bar.value = hp_now
	vb.add_child(bar)
	_ignore_mouse(panel)


func _fill_back(panel: PanelContainer) -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	panel.add_theme_stylebox_override("panel", _tex_style("ui/card_back.png", 12, 0))


func _ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(child)


func _make_card_panel(card: Dictionary) -> PanelContainer:
	var panel := _make_card_view(card, true)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_card_input.bind(card["uid"]))
	return panel


func _make_bar(max_value: int, fill_file: String, bg_file: String, margin: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = max_value
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("fill", _tex_style(fill_file, margin, 0))
	bar.add_theme_stylebox_override("background", _tex_style(bg_file, margin, 0))
	return bar


# --- Karty a balíčky ------------------------------------------------------

func _make_deck(pool: Array, count: int) -> Array:
	var deck: Array = []
	for i in count:
		var card: Dictionary = pool[randi() % pool.size()].duplicate()
		card["uid"] = next_uid
		next_uid += 1
		card["max_hp"] = card["hp"]
		deck.append(card)
	return deck


func _uids_of(cards: Array) -> Array:
	var out: Array = []
	for c in cards:
		if c != null:
			out.append(c["uid"])
	return out


func _available_cards(deck: Array, used_uids: Array) -> Array:
	var out: Array = []
	for c in deck:
		if not used_uids.has(c["uid"]):
			out.append(c)
	return out


func _find_in_hand(uid: int) -> Variant:
	for c in hand:
		if c["uid"] == uid:
			return c
	return null


func _board_of(is_player: bool) -> Array:
	return player_board if is_player else enemy_board


func _remove_from_deck(is_player: bool, uid: int) -> void:
	var dead_uid := uid
	if is_player:
		player_deck = player_deck.filter(func(c: Dictionary) -> bool: return c["uid"] != dead_uid)
	else:
		enemy_deck = enemy_deck.filter(func(c: Dictionary) -> bool: return c["uid"] != dead_uid)


# --- Tahy ------------------------------------------------------------------

func _fill_hand() -> void:
	while hand.size() < HAND_SIZE:
		var avail := _available_cards(player_deck, _uids_of(player_board) + _uids_of(hand))
		if avail.is_empty():
			break
		hand.append(avail.pick_random())


# Úředník nasadí karty animovaně: nejdřív přední řadu, zadní jen za obsazenou přední.
# Max enemy_cards_per_turn za tah.
func _enemy_place_animated() -> void:
	var placed := 0
	var from_center := enemy_hand_area.get_global_rect().get_center() + Vector2(50, 0)
	for idx in SLOT_COUNT:
		if placed >= enemy_cards_per_turn:
			return
		if enemy_board[idx] != null:
			continue
		if idx >= LANE_COUNT and enemy_board[idx - LANE_COUNT] == null:
			continue
		var avail := _available_cards(enemy_deck, _uids_of(enemy_board))
		if avail.is_empty():
			return
		var card = avail.pick_random()
		enemy_board[idx] = card
		placed += 1
		_log("Úředník nasadil %s (%s)." % [card["name"], _row_name(idx)])
		var tw := _fly_card(card, from_center, 0.0, false, idx, COLOR_ENEMY_PLACE, true)
		await tw.finished


func _row_name(idx: int) -> String:
	return "přední" if idx < LANE_COUNT else "zadní"


# Zaznamená událost pro vizuální efekt. kind: "attack", "slot", "official", "player".
func _record(kind: String, is_player: bool, idx: int, amount: int) -> void:
	hit_events.append({"kind": kind, "is_player": is_player, "idx": idx, "amount": amount})


func _play_hit_effects() -> void:
	var events := hit_events.duplicate()
	hit_events.clear()
	for ev in events:
		_show_event(ev)
		# Zvýraznění útočníka jde zároveň s jeho zásahem, takže čeká jen zásah.
		if ev["kind"] != "attack":
			await get_tree().create_timer(EFFECT_STEP).timeout


func _show_event(ev: Dictionary) -> void:
	var panel := _panel_for_event(ev)
	match ev["kind"]:
		"attack":
			# Zvýrazňuje se jen tvůj útok. Když útočí úředník, zasažená karta je jediná animace.
			if ev["is_player"]:
				_flash(panel, COLOR_ATTACK)
		"official":
			_flash(panel, COLOR_HIT)
			_flash(official_panel, COLOR_HIT)
			_float_text(panel, "-%d" % ev["amount"], C_GOLD_LIGHT)
			official_portrait.hurt()
			_shake(4.0)
		"player":
			_flash(panel, COLOR_HIT)
			_flash(player_panel, COLOR_HIT)
			_float_text(panel, "-%d" % ev["amount"], C_RED_LIGHT)
			player_portrait.hurt()
			_shake(7.0)
		_:
			_flash(panel, COLOR_HIT)
			_float_text(panel, "-%d" % ev["amount"], C_RED_LIGHT)


func _panel_for_event(ev: Dictionary) -> Control:
	# Zásah do tvého HP (bez karty) se ukáže na tvém slotu v daném pruhu, ne na panelu „Ty“.
	if ev["kind"] == "official":
		return official_panel
	var panels: Array = player_slot_panels if ev["is_player"] else enemy_slot_panels
	return panels[ev["idx"]]


# Krátké probliknutí panelu barvou, pak návrat do bílé.
func _flash(node: Control, color: Color) -> void:
	if node.has_meta("flash_tween"):
		var old: Tween = node.get_meta("flash_tween")
		if old.is_valid():
			old.kill()
	node.modulate = color
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color.WHITE, 0.6)
	node.set_meta("flash_tween", tw)


# Plovoucí číslo nad panelem: vyskočí, chvíli visí a zmizí.
func _float_text(node: Control, text: String, color: Color = COLOR_HIT) -> void:
	var label := _make_label(text, FS_L, color, true)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 40
	add_child(label)
	var center := node.get_global_rect().get_center()
	label.global_position = center - Vector2(text.length() * 9, 20)
	label.pivot_offset = Vector2(text.length() * 9, 18)
	label.scale = Vector2(0.5, 0.5)
	var start_y := label.global_position.y
	var tw := create_tween()
	tw.tween_property(label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(label, "global_position:y", start_y - 44.0, 0.9).set_delay(0.12)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.chain().tween_callback(label.queue_free)


# Otřes obrazovky: celé UI poskočí o pár pixelů a vrátí se.
func _shake(strength: float) -> void:
	UiKit.shake(self, strength)


# Velký nápis přes stůl při změně tahu.
func _banner(text: String, color: Color) -> void:
	var strip := PanelContainer.new()
	var sb := _tex_style("ui/plaque_dark.png", 12)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	strip.add_theme_stylebox_override("panel", sb)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.z_index = 30
	var label := _make_label(text, FS_XL, color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.add_child(label)
	add_child(strip)
	strip.size = Vector2(size.x, 0)
	strip.reset_size()
	strip.size.x = size.x
	var y := size.y * 0.42 - strip.size.y / 2.0
	strip.position = Vector2(-size.x, y)
	var tw := create_tween()
	tw.tween_property(strip, "position:x", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.55)
	tw.tween_property(strip, "position:x", size.x, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(strip.queue_free)


# Konec případu: přes obrazovku dopadne razítko SCHVÁLENO / ZAMÍTNUTO / POVÝŠEN.
func _end_stamp(won: bool) -> void:
	var color := Color("#4f9a5a") if won else C_RED
	var title := "SCHVÁLENO" if won else "ZAMÍTNUTO"
	var sub := "Úředník padl. +%d grošů. Postupuješ o patro výš." % GameState.WIN_REWARD
	if tutorial:
		sub = "Zkouška složena. +%d grošů." % GameState.WIN_REWARD
	elif won and GameState.is_boss_case():
		title = "POVÝŠEN"
		sub = "Ředitel padl. Kancelář nahoře je tvoje."
		color = C_GOLD
	elif not won:
		sub = "Případ prohrán. Patro musíš zkusit znova."
	UiKit.stamp_overlay(self, title, sub, color, "POKRAČOVAT", _on_case_finished.bind(won))


# Po razítku: výhra i prohra vedou do města. Kdo prohrál a nemá na další kolo, jde rovnou do baru.
# Výhra nad ředitelem končí celou hru scénou ending.
func _on_case_finished(won: bool) -> void:
	GameState.finish_case(won, tutorial)
	if GameState.career_won():
		GameState.goto("res://scenes/ending.tscn")
	elif not won and not GameState.can_afford_round():
		GameState.goto("res://scenes/bar.tscn")
	else:
		GameState.goto("res://scenes/city.tscn")


# --- Animace letu karty ----------------------------------------------------

func _hidden_key(is_player: bool, idx: int) -> String:
	return "%s%d" % ["p" if is_player else "e", idx]


# Posune uzel tak, aby jeho lokální bod local_point ležel přesně na global_point.
# Počítá se přes skutečnou transformaci uzlu (rotace, měřítko, pivot), takže to sedí
# i u zmenšené a natočené karty. Prosté global_position = cíl - bod tu nefunguje.
func _place_pivot_at(node: Control, local_point: Vector2, global_point: Vector2) -> void:
	var current: Vector2 = node.get_global_transform() * local_point
	var parent_xf: Transform2D = (node.get_parent() as CanvasItem).get_global_transform()
	node.position += parent_xf.affine_inverse().basis_xform(global_point - current)


# Pro tween_method: hodnota je cílový globální bod, uzel a lokální bod jsou navázané.
func _set_pivot_world(global_point: Vector2, node: Control, local_point: Vector2) -> void:
	if is_instance_valid(node):
		_place_pivot_at(node, local_point, global_point)


# Karta přiletí z from_center do slotu idx. Obsah slotu se ukáže až po přistání.
# Během letu se karta zvětší na plnou velikost, ve slotu leží v měřítku 1.
func _fly_card(card: Dictionary, from_center: Vector2, from_rot: float, is_player: bool, idx: int, color: Color, flip: bool = false) -> Tween:
	var panels: Array = player_slot_panels if is_player else enemy_slot_panels
	var slot_panel: Control = panels[idx]
	# Při flipu letí karta rubem nahoru a na půl cesty se otočí lícem.
	var ghost := _make_ghost(card, not flip, is_player)
	ghost.size = CARD_SIZE
	ghost.pivot_offset = CARD_SIZE / 2.0
	ghost.scale = Vector2(DRAG_SCALE, DRAG_SCALE)
	ghost.z_index = 20
	ghost.rotation = from_rot
	add_child(ghost)
	_place_pivot_at(ghost, CARD_SIZE / 2.0, from_center)

	var key := _hidden_key(is_player, idx)
	hidden_slots[key] = true
	var target_center := slot_panel.get_global_rect().get_center()

	var tw := create_tween().set_parallel(true)
	tw.tween_property(ghost, "rotation", 0.0, FLY_TIME)
	tw.tween_method(_set_pivot_world.bind(ghost, CARD_SIZE / 2.0), from_center, target_center, FLY_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "scale:y", 1.0, FLY_TIME)
	if flip:
		var ft := create_tween()
		ft.tween_property(ghost, "scale:x", 0.02, 0.15)
		ft.tween_callback(_fill_card.bind(ghost, card, is_player))
		ft.tween_property(ghost, "scale:x", 1.0, 0.15)
	else:
		tw.tween_property(ghost, "scale:x", 1.0, FLY_TIME)
	tw.finished.connect(_on_fly_done.bind(ghost, key, slot_panel, color))
	return tw


func _make_ghost(card: Dictionary, face_up: bool, is_player: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if face_up:
		_fill_card(panel, card, is_player)
	else:
		_fill_back(panel)
	return panel


func _on_fly_done(ghost: Control, key: String, slot_panel: Control, color: Color) -> void:
	if is_instance_valid(ghost):
		ghost.queue_free()
	hidden_slots.erase(key)
	_refresh()
	_flash(slot_panel, color)


# --- Tažení karty ----------------------------------------------------------

func _start_drag() -> void:
	var card = _find_in_hand(drag_uid)
	if card == null:
		drag_pending = false
		return
	drag_pending = false
	dragging = true
	drag_node = _make_card_panel(card)
	drag_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_node.size = CARD_SIZE
	# Karta visí na bodu uchopení: ten je pivot a zůstává přesně pod kurzorem.
	drag_node.pivot_offset = drag_grab
	drag_node.scale = Vector2(DRAG_SCALE, DRAG_SCALE)
	drag_node.z_index = 20
	add_child(drag_node)
	var mouse := get_global_mouse_position()
	_place_pivot_at(drag_node, drag_grab, mouse)
	hand_pos = mouse
	drag_last_mouse = mouse
	drag_vel_s = Vector2.ZERO
	drag_acc_s = Vector2.ZERO
	drag_acc_time = 0.0
	drag_phi = 0.0
	drag_phi_vel = 0.0
	var src = hand_panels.get(drag_uid)
	if src is Control:
		src.modulate.a = 0.25
	_update_slot_highlights()


func _process(delta: float) -> void:
	if not dragging or drag_node == null:
		return
	_update_drag(get_global_mouse_position(), delta)
	# Nejdřív rotace, pak posun: bod uchopení musí po natočení zůstat přesně pod kurzorem.
	drag_node.rotation = drag_phi
	_place_pivot_at(drag_node, drag_grab, hand_pos)


# Karta je přilepená na kurzor: pivot (bod uchopení) je přesně pod myší, bez zpoždění.
# Z pohybu myši se odvodí zrychlení ruky, to pak houpe kartou.
func _update_drag(mouse: Vector2, delta: float) -> void:
	hand_pos = mouse
	var dt := minf(delta, 1.0 / 30.0)
	if dt > 0.0:
		var v_raw := (mouse - drag_last_mouse) / dt
		drag_last_mouse = mouse
		var prev_v := drag_vel_s
		drag_vel_s = drag_vel_s.lerp(v_raw, 1.0 - exp(-VEL_SMOOTH * dt))
		var acc_raw := (drag_vel_s - prev_v) / dt
		drag_acc_s = drag_acc_s.lerp(acc_raw, 1.0 - exp(-ACC_SMOOTH * dt)).limit_length(MAX_HAND_ACC)
	# Pevný krok fyziky (akumulátor), aby kyvadlo nezáviselo na FPS.
	drag_acc_time = minf(drag_acc_time + dt, 0.1)
	while drag_acc_time >= PHYS_STEP:
		drag_acc_time -= PHYS_STEP
		_drag_physics_step(drag_acc_s, PHYS_STEP)


func _drag_physics_step(hand_acc: Vector2, h: float) -> void:
	# Karta v klidu stojí vzpřímeně. Bod uchopení je pivot, takže se naklání jen od zrychlení ruky
	# a vrací se zpět. Vodorovné zrychlení ruky dává moment proti pohybu. Pokud držíš kartu pod
	# středem, znaménko se obrátí (těžiště je nad pivotem).
	var length := maxf((CARD_SIZE / 2.0 - drag_grab).length() * DRAG_SCALE, 30.0)
	var side := 1.0 if drag_grab.y <= CARD_SIZE.y / 2.0 else -1.0
	var acc_phi := -(PENDULUM_G / length) * drag_phi + side * (SWING_GAIN * hand_acc.x / length) - PENDULUM_DAMP * drag_phi_vel
	drag_phi_vel = clampf(drag_phi_vel + acc_phi * h, -MAX_PHI_VEL, MAX_PHI_VEL)
	drag_phi = clampf(drag_phi + drag_phi_vel * h, -MAX_PHI, MAX_PHI)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if dragging:
			_end_drag()
		elif drag_pending:
			# Pustil jsi kartu bez tažení: je to klik, přepni výběr.
			drag_pending = false
			if phase == Phase.PLAYER:
				selected_uid = -1 if selected_uid == drag_uid else drag_uid
				_refresh()
	elif event is InputEventMouseMotion and drag_pending and not dragging:
		if get_global_mouse_position().distance_to(drag_start) > DRAG_THRESHOLD:
			_start_drag()


func _end_drag() -> void:
	dragging = false
	var mouse := get_global_mouse_position()
	var card = _find_in_hand(drag_uid)
	var idx := _slot_under(mouse)
	if card != null and idx != -1:
		var reason := _drop_problem(idx)
		if reason == "":
			_commit_drop(card, idx)
			return
		_log(reason)
	_return_drag()


func _slot_under(mouse: Vector2) -> int:
	for idx in SLOT_COUNT:
		var panel: Control = player_slot_panels[idx]
		if panel.get_global_rect().has_point(mouse):
			return idx
	return -1


# Vrací důvod, proč na slot nejde položit. Prázdný řetězec = jde.
func _drop_problem(idx: int) -> String:
	if phase != Phase.PLAYER:
		return "Teď nejsi na tahu."
	if player_board[idx] != null:
		return "Slot je obsazený."
	if idx >= LANE_COUNT and player_board[idx - LANE_COUNT] == null:
		return "Zadní řadu obsadíš až za kartou v přední řadě."
	if placed_this_turn >= cards_per_turn:
		return "Na tah můžeš zahrát jen %s." % _cards_word(cards_per_turn)
	return ""


func _cards_word(n: int) -> String:
	if n == 1:
		return "1 kartu"
	if n < 5:
		return "%d karty" % n
	return "%d karet" % n


func _commit_drop(card: Dictionary, idx: int) -> void:
	# Skutečný střed natočené a zmenšené karty, ne střed jejího obdélníku.
	var from_center: Vector2 = drag_node.get_global_transform() * (CARD_SIZE / 2.0)
	var from_rot := drag_node.rotation
	drag_node.queue_free()
	drag_node = null
	drag_uid = -1
	hand.erase(card)
	player_board[idx] = card
	placed_this_turn += 1
	_log("Položeno: %s (%s, pruh %d)." % [card["name"], _row_name(idx), (idx % LANE_COUNT) + 1])
	_fly_card(card, from_center, from_rot, true, idx, COLOR_PLACE)
	_refresh()


# Položí kartu bez tažení (testy a tutorial).
func _commit_drop_direct(card: Dictionary, idx: int) -> void:
	hand.erase(card)
	player_board[idx] = card
	placed_this_turn += 1
	_fly_card(card, Vector2(400, 300), 0.0, true, idx, COLOR_PLACE)
	_refresh()


# Karta se vrátí do ruky, kývne se pružinou.
func _return_drag() -> void:
	var node := drag_node
	drag_node = null
	var src = hand_panels.get(drag_uid)
	drag_uid = -1
	_update_slot_highlights()
	# Bod uchopení se vrací na místo, kde byl v ruce (karta v ruce má měřítko 1).
	var grab := drag_grab
	var start_point: Vector2 = node.get_global_transform() * grab
	var target_point := start_point
	if src is Control:
		target_point = src.get_global_rect().position + grab
	var tw := create_tween().set_parallel(true)
	tw.tween_method(_set_pivot_world.bind(node, grab), start_point, target_point, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "rotation", 0.0, 0.45)
	tw.tween_property(node, "scale", Vector2.ONE, 0.45)
	tw.finished.connect(_on_return_done.bind(node))


func _on_return_done(node: Control) -> void:
	if is_instance_valid(node):
		node.queue_free()
	_refresh()


func _on_card_input(event: InputEvent, uid: int) -> void:
	if phase != Phase.PLAYER or not _is_left_press(event):
		return
	drag_pending = true
	drag_uid = uid
	drag_start = get_global_mouse_position()
	drag_grab = (event as InputEventMouseButton).position


func _on_slot_input(event: InputEvent, idx: int) -> void:
	if phase != Phase.PLAYER or not _is_left_press(event):
		return
	if selected_uid == -1:
		_log("Nejdřív vyber kartu v ruce.")
		return
	var reason := _drop_problem(idx)
	if reason != "":
		_log(reason)
		return

	var card = _find_in_hand(selected_uid)
	if card == null:
		selected_uid = -1
		return
	var from_center: Vector2 = (player_slot_panels[idx] as Control).get_global_rect().get_center()
	var src = hand_panels.get(selected_uid)
	if src is Control:
		from_center = src.get_global_rect().get_center()
	selected_uid = -1
	hand.erase(card)
	player_board[idx] = card
	placed_this_turn += 1
	_log("Položeno: %s (%s, pruh %d)." % [card["name"], _row_name(idx), (idx % LANE_COUNT) + 1])
	_fly_card(card, from_center, 0.0, true, idx, COLOR_PLACE)
	_refresh()


func _is_left_press(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT


# --- Konec tahu a boj ------------------------------------------------------

func _attack_pass(attackers: Array) -> void:
	for a in attackers:
		var is_player: bool = a[0]
		var lane: int = a[1]
		var attacker = _board_of(is_player)[lane]
		if attacker == null:
			continue
		_record("attack", is_player, lane, 0)
		var target = _board_of(not is_player)[lane]
		var who := "Ty" if is_player else OFFICIAL_NAME
		if target != null:
			var hp_before: int = maxi(target["hp"], 0)
			target["hp"] -= attacker["atk"]
			_log("Pruh %d: %s zasahuje %s za %d ŽIV." % [lane + 1, attacker["name"], target["name"], attacker["atk"]])
			var applied: int = mini(attacker["atk"], hp_before)
			if applied > 0:
				_record("slot", not is_player, lane, applied)
			var overflow: int = attacker["atk"] - hp_before
			if overflow > 0:
				_overflow(not is_player, lane, overflow)
		elif is_player:
			official_hp -= attacker["atk"]
			_record("official", false, lane, attacker["atk"])
			_log("Pruh %d: %s zasahuje %s přímo za %d HP." % [lane + 1, attacker["name"], OFFICIAL_NAME, attacker["atk"]])
		else:
			player_hp -= attacker["atk"]
			_record("player", true, lane, attacker["atk"])
			_log("Pruh %d: %s zasahuje %s přímo za %d HP." % [lane + 1, attacker["name"], who, attacker["atk"]])


# Přebytek útoku, který nestačil zabít cíl, propadne na zadní kartu za cílem v tom pruhu.
# Když tam žádná není, jde přímo úředníkovi (útočí hráč), nebo hráči (útočí úředník).
func _overflow(defender_is_player: bool, lane: int, amount: int) -> void:
	var back = _board_of(defender_is_player)[lane + LANE_COUNT]
	if back != null:
		back["hp"] -= amount
		_record("slot", defender_is_player, lane + LANE_COUNT, amount)
		_log("Přebytek %d ŽIV propadá na %s v zadní řadě." % [amount, back["name"]])
	elif defender_is_player:
		player_hp -= amount
		_record("player", true, lane, amount)
		_log("Přebytek %d HP jde přímo tobě." % amount)
	else:
		official_hp -= amount
		_record("official", false, lane, amount)
		_log("Přebytek %d HP jde přímo úředníkovi." % amount)


# Úklid: mrtvé karty pryč (v obou řadách), zadní karta v pruhu postoupí, pokud je přední prázdná.
# Vrací postoupivší karty, ty pak ještě ten tah útočí.
func _cleanup_dead() -> Array:
	var promoted: Array = []
	for is_player in [true, false]:
		var board := _board_of(is_player)
		for idx in SLOT_COUNT:
			var card = board[idx]
			if card != null and card["hp"] <= 0:
				board[idx] = null
				if is_player and tutorial:
					# V tutorialu se karta vrací do balíčku, aby nešlo prohrát vyčerpáním.
					card["hp"] = card["max_hp"]
					_log("%s padá, ale vrací se do balíčku." % card["name"])
				else:
					_log("%s padá a je ztracen." % card["name"])
					_remove_from_deck(is_player, card["uid"])
		for lane in LANE_COUNT:
			var back_idx: int = lane + LANE_COUNT
			if board[lane] == null and board[back_idx] != null:
				board[lane] = board[back_idx]
				board[back_idx] = null
				_log("%s postupuje do přední řady, pruh %d, a hned útočí." % [board[lane]["name"], lane + 1])
				promoted.append([is_player, lane])
	return promoted


func _resolve_combat() -> void:
	var attackers: Array = []
	for lane in LANE_COUNT:
		if player_board[lane] != null:
			attackers.append([true, lane])
		if enemy_board[lane] != null:
			attackers.append([false, lane])

	var passes := 0
	while not attackers.is_empty() and passes < 20:
		passes += 1
		_attack_pass(attackers)
		attackers = _cleanup_dead()
	if tutorial:
		player_hp = maxi(player_hp, 1)


func _check_end() -> bool:
	if player_hp <= 0:
		player_hp = 0
		phase = Phase.OVER
		_log("Padl jsi. Případ prohrán.")
		return true
	if official_hp <= 0:
		official_hp = 0
		phase = Phase.OVER
		_log("%s padl. Případ vyhrán." % OFFICIAL_NAME)
		return true
	# Prázdný balíček už neprohrává: s prázdnou rukou nabídne šarlatán ruletu.
	return false


func _on_confirm_turn() -> void:
	if phase != Phase.PLAYER:
		return
	phase = Phase.ENEMY
	selected_uid = -1
	hit_events.clear()
	_log("Tah potvrzen. Úředník je na řadě.")
	_refresh()
	_banner("TAH ÚŘEDNÍKA", C_RED_LIGHT)

	await get_tree().create_timer(ENEMY_TURN_DELAY + 0.4).timeout
	await _enemy_place_animated()
	if turn == 1:
		await _tut([
			{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": Color("#b45cff"),
				"text": "Úředník nasadil své karty. Teď útočí: každá přední karta bije protější kartu ve svém pruhu."},
		])
	_resolve_combat()
	_refresh()
	await _play_hit_effects()
	if _check_end():
		_refresh()
		_end_stamp(official_hp <= 0 and player_hp > 0)
		return
	if turn == 1:
		await _tut([
			{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": Color("#b45cff"),
				"text": "Přebytek, který karta nezabije, propadne na zadní kartu za cílem. Když přední padne, zadní postoupí a hned útočí."},
			{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": Color("#b45cff"),
				"text": "Porazíš-li úředníka na nule, případ je tvůj. Dál to bude těžší. Hodně štěstí, krysáku."},
		])

	turn += 1
	placed_this_turn = 0
	_fill_hand()
	phase = Phase.PLAYER
	_log("Kolo %d. Na řadě jsi ty." % turn)
	_refresh()
	_banner("TVŮJ TAH", C_GOLD_LIGHT)
	if hand.is_empty() and not tutorial:
		await get_tree().create_timer(0.8).timeout
		await _offer_roulette()


# --- Ruleta ----------------------------------------------------------------
# Prázdná ruka: šarlatán nabídne ruletu (scripts/roulette.gd), nebo krysa ztratí tah.

func _offer_roulette() -> void:
	var col := Color("#b45cff")
	var choice: String = await tut_dialog.run([
		{"who": "Šarlatán", "portrait": "portraits/charlatan.png", "color": col,
			"text": "Prázdné packy, co? Mám tu kolo štěstí. Tři políčka z osmi ti dají karty. Zbytek si vezme něco tvého.",
			"choices": [
				{"id": "spin", "text": "Zatočit ruletou."},
				{"id": "skip", "text": "Ztratit tah."},
			]},
	])
	if choice != "spin":
		_log("Necháváš tah propadnout.")
		_on_confirm_turn()
		return
	var seg: Dictionary = await Roulette.spin(self)
	_apply_roulette(seg)


func _apply_roulette(seg: Dictionary) -> void:
	match seg["kind"]:
		"cards":
			for i in seg["n"]:
				var card: Dictionary = CARD_POOL.pick_random().duplicate()
				card["uid"] = next_uid
				next_uid += 1
				card["max_hp"] = card["hp"]
				player_deck.append(card)
				hand.append(card)
			_log("Ruleta: %d nové karty do ruky." % seg["n"])
			_float_text(player_panel, "+%d karty" % seg["n"], C_GOLD_LIGHT)
		"hand":
			var e := GameState.lose_hand()
			if e.is_empty():
				_break_rib()  # ruce už nejsou, tak aspoň žebro
			else:
				cards_per_turn = GameState.cards_per_turn() + coffee_bonus
				_log("Ruleta: šarlatán si bere tvou %s ruku. Hraješ o kartu méně." % GameState.SIDE_ACC[e["side"]])
				_float_text(player_panel, "-1 karta/tah", C_RED_LIGHT)
				player_portrait.hurt()
				_shake(8.0)
		_:
			_break_rib()
	_refresh()


# Zlomené žebro trvale sníží max HP. Aktuální HP se ořízne, ale nikdy ne pod 1.
func _break_rib() -> void:
	if GameState.break_rib():
		player_max_hp = GameState.player_max_hp()
		player_bar.max_value = player_max_hp
		player_hp = maxi(1, mini(player_hp, player_max_hp))
		_log("Ruleta: křup. Zlomené žebro, max HP je teď %d." % player_max_hp)
		_float_text(player_panel, "-%d max HP" % GameState.RIB_HP, C_RED_LIGHT)
	else:
		player_hp = maxi(1, player_hp - GameState.RIB_HP)
		_log("Ruleta: žebra už nemáš, tak tě šarlatán kopne. -%d HP." % GameState.RIB_HP)
		_float_text(player_panel, "-%d HP" % GameState.RIB_HP, C_RED_LIGHT)
	player_portrait.hurt()
	_shake(10.0)


# --- Zobrazení -------------------------------------------------------------

func _refresh() -> void:
	turn_label.text = "KOLO %d" % turn
	match phase:
		Phase.PLAYER:
			phase_label.text = "Tvůj tah"
			phase_label.add_theme_color_override("font_color", C_GOLD_LIGHT)
		Phase.ENEMY:
			phase_label.text = "Tah úředníka"
			phase_label.add_theme_color_override("font_color", C_RED_LIGHT)
		Phase.OVER:
			phase_label.text = "Konec případu"
			phase_label.add_theme_color_override("font_color", C_GREY)
	# Žetony: zlatý = ještě můžeš hrát, šedý = zahráno, rudý křížek = chybí ruka.
	for i in energy_icons.size():  # žetony podle hráčova limitu
		# Čtvrtý žeton je vidět jen s kafem; useknuté ruce se ukazují jako rudé křížky.
		(energy_icons[i] as TextureRect).visible = i < maxi(MAX_CARDS_PER_TURN, cards_per_turn)
		var file := "icons/energy_lost.png"
		if i < cards_per_turn:
			var lit := phase == Phase.PLAYER and i < cards_per_turn - placed_this_turn
			file = "icons/energy_on.png" if lit else "icons/energy_off.png"
		(energy_icons[i] as TextureRect).texture = _tex(file)
	confirm_btn.disabled = phase != Phase.PLAYER

	official_bar.value = maxi(official_hp, 0)
	official_label.text = "%d/%d" % [maxi(official_hp, 0), official_max_hp]
	player_bar.value = maxi(player_hp, 0)
	player_label.text = "%d/%d" % [maxi(player_hp, 0), player_max_hp]
	player_deck_label.text = "Balíček: %d" % player_deck.size()
	var in_hand := _available_cards(enemy_deck, _uids_of(enemy_board)).size()
	enemy_hand_label.text = "%d" % in_hand
	for i in enemy_hand_backs.size():
		enemy_hand_backs[i].visible = i < in_hand

	for idx in SLOT_COUNT:
		if not hidden_slots.has(_hidden_key(true, idx)):
			_show_slot(player_slot_panels[idx], player_slot_contents[idx], player_board[idx], true)
		if not hidden_slots.has(_hidden_key(false, idx)):
			_show_slot(enemy_slot_panels[idx], enemy_slot_contents[idx], enemy_board[idx], false)

	_update_slot_highlights()
	_rebuild_hand()


# Obsah slotu: karta, nebo nenápadný popisek řady.
func _show_slot(panel: Control, content: Control, card: Variant, is_player: bool) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if card == null:
		var label := _make_label(str(panel.get_meta("row_name")).to_upper(), FS_S, Color(1, 1, 1, 0.18))
		content.add_child(label)
		return
	content.add_child(_make_card_view(card, is_player))


# Volné sloty, kam teď jde položit vybranou nebo taženou kartu, svítí zlatě.
func _update_slot_highlights() -> void:
	var holding := phase == Phase.PLAYER and (dragging or selected_uid != -1)
	for idx in SLOT_COUNT:
		var valid := holding and _drop_problem(idx) == ""
		(player_slot_panels[idx] as Control).add_theme_stylebox_override("panel", style_slot_valid if valid else style_slot_player)


func _rebuild_hand() -> void:
	for child in hand_box.get_children():
		hand_box.remove_child(child)
		child.queue_free()
	hand_panels.clear()
	for card in hand:
		# Držák drží místo v řadě, karta v něm může vyjet nahoru.
		var holder := Control.new()
		holder.custom_minimum_size = CARD_SIZE + Vector2(0, HAND_LIFT)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var panel := _make_card_panel(card)
		panel.position = Vector2(0, HAND_LIFT)
		var is_selected: bool = card["uid"] == selected_uid
		if is_selected:
			panel.position.y = 0
			panel.modulate = Color(1.0, 0.95, 0.6)
		if dragging and card["uid"] == drag_uid:
			panel.modulate.a = 0.25
		panel.mouse_entered.connect(_on_hand_hover.bind(panel, true))
		panel.mouse_exited.connect(_on_hand_hover.bind(panel, false))
		holder.add_child(panel)
		hand_panels[card["uid"]] = panel
		hand_box.add_child(holder)


func _on_hand_hover(panel: Control, inside: bool) -> void:
	if not is_instance_valid(panel) or dragging:
		return
	var uid := -1
	for k in hand_panels:
		if hand_panels[k] == panel:
			uid = k
	var target := 0.0 if inside or uid == selected_uid else HAND_LIFT
	create_tween().tween_property(panel, "position:y", target, 0.1)


func _log(message: String) -> void:
	log_lines.append(message)
	while log_lines.size() > 5:
		log_lines.pop_front()
	var text := ""
	for i in log_lines.size():
		var newest := i == log_lines.size() - 1
		var color := "#1c1726" if newest else "#8a7550"
		text += "[color=%s]› %s[/color]" % [color, log_lines[i]]
		if not newest:
			text += "\n"
	log_label.text = text
