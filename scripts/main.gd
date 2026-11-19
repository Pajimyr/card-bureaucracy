extends Control

# Vizuální prototyp: jeden úředník proti hráči, střídání tahů.
# Každá strana má 6 míst: 3 pruhy × 2 řady (přední a zadní).
# Index slotu: 0..2 = přední řada pruhů 1..3, 3..5 = zadní řada pruhů 1..3.
# Karta má sílu (ÚT) a health (ŽIV). Oba mají HP.
# V pruhu bojuje přední karta proti přední kartě protivníka.
# Když protivník v pruhu nemá přední kartu, útok jde přímo na jeho HP.
# Když přední karta umře, zadní karta v tom pruhu postoupí a hned útočí.
# Karta na nule je ztracená. Speciální schopnosti zatím nejsou.
# Karty z ruky lze přetáhnout na slot (nebo kliknout kartu a pak slot). Tažená karta se kývá.

const LANE_COUNT := 3
const SLOT_COUNT := 6
const HAND_SIZE := 5
const PLAYER_DECK_SIZE := 10
const ENEMY_DECK_SIZE := 9
const PLAYER_MAX_HP := 20
const OFFICIAL_MAX_HP := 20
const OFFICIAL_NAME := "Úředník"
const ENEMY_TURN_DELAY := 0.8
const SIDE_COLUMN_WIDTH := 220
const MAX_CARDS_PER_TURN := 3
const EFFECT_STEP := 0.3
const CARD_SIZE := Vector2(170, 110)
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
const SWING_GAIN := 0.2# jak silně vodorovné zrychlení ruky houpe kartou
const MAX_PHI := 0.5  # max. náklon karty (rad), aby se nikdy neprotočila
const MAX_PHI_VEL := 8.0

enum Phase { PLAYER, ENEMY, OVER }

# Šablony karet. Každá instance dostane vlastní uid, max_hp a aktuální hp.
const CARD_POOL := [
	{"name": "Formulář B-7", "atk": 2, "hp": 3},
	{"name": "Razítko", "atk": 3, "hp": 2},
	{"name": "Žádost o žádost", "atk": 1, "hp": 5},
	{"name": "Úřední lhůta", "atk": 4, "hp": 2},
	{"name": "Kopie kopie", "atk": 1, "hp": 2},
	{"name": "Nahlédnutí do spisu", "atk": 1, "hp": 4},
	{"name": "Podpis pod tlakem", "atk": 5, "hp": 4},
	{"name": "Ověřená kopie", "atk": 2, "hp": 4},
	{"name": "Stížnost", "atk": 2, "hp": 3},
	{"name": "Výpis z rejstříku", "atk": 3, "hp": 3},
]

const ENEMY_POOL := [
	{"name": "Referent", "atk": 2, "hp": 4},
	{"name": "Revizor", "atk": 3, "hp": 3},
	{"name": "Vedoucí odboru", "atk": 4, "hp": 4},
	{"name": "Úředník podatelny", "atk": 1, "hp": 3},
	{"name": "Kontrolor", "atk": 3, "hp": 5},
]

const COLOR_ENEMY := Color(0.36, 0.2, 0.2)
const COLOR_PLAYER := Color(0.2, 0.3, 0.36)
const COLOR_CARD := Color(0.93, 0.9, 0.8)
const COLOR_TEXT := Color(0.95, 0.95, 0.95)
const COLOR_CARD_TEXT := Color(0.15, 0.12, 0.1)
const COLOR_MUTED := Color(0.7, 0.7, 0.7)
const COLOR_ATTACK := Color(1.0, 0.92, 0.45)
const COLOR_HIT := Color(1.0, 0.4, 0.4)
const COLOR_PLACE := Color(0.6, 1.0, 0.6)
const COLOR_ENEMY_PLACE := Color(1.0, 0.75, 0.75)

var phase: Phase = Phase.PLAYER
var turn: int = 1
var next_uid: int = 0
var selected_uid: int = -1
var player_hp: int = PLAYER_MAX_HP
var official_hp: int = OFFICIAL_MAX_HP
var placed_this_turn: int = 0
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

var hand_box: HBoxContainer
var turn_label: Label
var phase_label: Label
var confirm_btn: Button
var log_label: Label
var official_bar: ProgressBar
var official_label: Label
var player_bar: ProgressBar
var player_label: Label
var player_deck_label: Label
var player_slot_contents: Array = []  # VBoxContainer podle indexu slotu
var enemy_slot_contents: Array = []
var player_slot_panels: Array = []
var enemy_slot_panels: Array = []
var official_panel: PanelContainer
var player_panel: PanelContainer
var log_lines: Array[String] = []


func _ready() -> void:
	randomize()
	player_board = _empty_board()
	enemy_board = _empty_board()
	player_deck = _make_deck(CARD_POOL, PLAYER_DECK_SIZE)
	enemy_deck = _make_deck(ENEMY_POOL, ENEMY_DECK_SIZE)
	_build_ui()
	_fill_hand()
	_begin()


# Úvod: úředník nasadí svoje karty animovaně, až potom můžeš hrát ty.
func _begin() -> void:
	# Hraješ první. Úředník nasazuje až po potvrzení tvého tahu.
	phase = Phase.PLAYER
	_log("Případ začíná. Přetáhni kartu z ruky na volný slot, nebo klikni kartu a pak slot.")
	_refresh()


func _empty_board() -> Array:
	var board: Array = []
	board.resize(SLOT_COUNT)
	board.fill(null)
	return board


# --- Stavba UI -------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.13, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# Hlavička
	var header := HBoxContainer.new()
	root.add_child(header)
	header.add_child(_make_label("Případ č. 1: Žádost o potvrzení totožnosti", 20))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	turn_label = _make_label("", 16)
	header.add_child(turn_label)
	phase_label = _make_label("", 16)
	header.add_child(phase_label)

	# Střed: levý sloupec (strany) + pravý sloupec (řady slotů)
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(SIDE_COLUMN_WIDTH, 0)
	left.add_theme_constant_override("separation", 12)
	main.add_child(left)
	left.add_child(_make_official_panel())
	left.add_child(_make_player_panel())

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(right)

	enemy_slot_contents.resize(SLOT_COUNT)
	player_slot_contents.resize(SLOT_COUNT)
	enemy_slot_panels.resize(SLOT_COUNT)
	player_slot_panels.resize(SLOT_COUNT)
	_add_board_row(right, "Úředník, zadní", enemy_slot_contents, enemy_slot_panels, LANE_COUNT, COLOR_ENEMY, false)
	_add_board_row(right, "Úředník, přední", enemy_slot_contents, enemy_slot_panels, 0, COLOR_ENEMY, false)
	_add_board_row(right, "Tvoje, přední", player_slot_contents, player_slot_panels, 0, COLOR_PLAYER, true)
	_add_board_row(right, "Tvoje, zadní", player_slot_contents, player_slot_panels, LANE_COUNT, COLOR_PLAYER, true)

	# Ruka
	root.add_child(_make_label("RUKA", 12, COLOR_MUTED))
	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 12)
	hand_box.custom_minimum_size = Vector2(0, 130)
	root.add_child(hand_box)

	# Spodní lišta
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)
	confirm_btn = Button.new()
	confirm_btn.text = "Potvrdit tah"
	confirm_btn.custom_minimum_size = Vector2(180, 40)
	confirm_btn.pressed.connect(_on_confirm_turn)
	bottom.add_child(confirm_btn)
	log_label = _make_label("", 14)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(log_label)


# Jedna řada: 3 sloty. Pokud is_player, jsou klikatelné a index slotu je first_index + pruh.
func _add_board_row(parent: Control, row_name: String, contents: Array, panels: Array, first_index: int, color: Color, is_player: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	for lane in LANE_COUNT:
		var idx := first_index + lane
		var click_index := idx if is_player else -1
		var slot := _make_slot(row, "%s, pruh %d" % [row_name, lane + 1], color, click_index)
		contents[idx] = slot["content"]
		panels[idx] = slot["panel"]


func _make_official_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	official_panel = panel
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_style(COLOR_ENEMY))
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	vb.add_child(_make_label(OFFICIAL_NAME, 18))
	official_label = _make_label("", 14)
	vb.add_child(official_label)
	official_bar = _make_bar(OFFICIAL_MAX_HP, Color(0.85, 0.3, 0.3))
	official_bar.custom_minimum_size = Vector2(0, 20)
	vb.add_child(official_bar)
	vb.add_child(_make_enemy_hand())
	return panel


# Ruka úředníka: rubové strany karet, ze kterých jeho karty vylétají.
func _make_enemy_hand() -> Control:
	var area := Control.new()
	area.custom_minimum_size = Vector2(0, 74)
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_hand_area = area
	var offsets := [Vector2(40, 12), Vector2(70, 6), Vector2(100, 12)]
	var rots := [-0.14, 0.0, 0.14]
	for i in ENEMY_HAND_SHOWN:
		var back := Panel.new()
		back.size = Vector2(46, 60)
		back.position = offsets[i]
		back.pivot_offset = back.size / 2.0
		back.rotation = rots[i]
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_theme_stylebox_override("panel", _make_back_style())
		area.add_child(back)
		enemy_hand_backs.append(back)
	enemy_hand_label = _make_label("", 12, COLOR_MUTED)
	enemy_hand_label.position = Vector2(0, 52)
	area.add_child(enemy_hand_label)
	return area


func _make_back_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.15, 0.15)
	sb.border_color = Color(0.6, 0.4, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	return sb


func _make_player_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	player_panel = panel
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_style(COLOR_PLAYER))
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	vb.add_child(_make_label("Ty", 18))
	player_label = _make_label("", 14)
	vb.add_child(player_label)
	player_bar = _make_bar(PLAYER_MAX_HP, Color(0.35, 0.75, 0.35))
	player_bar.custom_minimum_size = Vector2(0, 20)
	vb.add_child(player_bar)
	player_deck_label = _make_label("", 14)
	vb.add_child(player_deck_label)
	return panel


func _make_slot(parent: Control, title: String, color: Color, click_index: int = -1) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 92)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_style(color))
	parent.add_child(panel)

	var vb := VBoxContainer.new()
	panel.add_child(vb)
	vb.add_child(_make_label(title, 11, COLOR_MUTED))

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(content)

	if click_index >= 0:
		panel.gui_input.connect(_on_slot_input.bind(click_index))
	return {"panel": panel, "content": content}


func _make_card_panel(card: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_style(COLOR_CARD))
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	_populate_card_view(vb, card, COLOR_CARD_TEXT)
	panel.gui_input.connect(_on_card_input.bind(card["uid"]))
	return panel


# Naplní kontejner obsahem karty (jméno, staty, ŽIV bar), nebo textem "prázdné".
func _populate_card_view(container: VBoxContainer, card: Variant, text_color: Color) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	if card == null:
		container.add_child(_make_label("prázdné", 15, text_color))
		return
	# Bez zalamování: jinak se výška počítá při šířce 0 a karta se natáhne na stovky pixelů.
	var name_label := _make_label(card["name"], 14, text_color)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	container.add_child(name_label)
	container.add_child(_make_label(_stats_text(card), 12, text_color))
	var bar := _make_bar(card["max_hp"], Color(0.35, 0.75, 0.35))
	bar.value = maxi(card["hp"], 0)
	container.add_child(bar)


func _make_bar(max_value: int, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = max_value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.1, 0.1)
	back.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", back)
	return bar


func _make_label(text: String, font_size: int, color: Color = COLOR_TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	return sb


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


func _stats_text(card: Dictionary) -> String:
	return "ÚT %d   ŽIV %d/%d" % [card["atk"], maxi(card["hp"], 0), card["max_hp"]]


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
# Max MAX_CARDS_PER_TURN za tah.
func _enemy_place_animated() -> void:
	var placed := 0
	var from_center := enemy_hand_area.get_global_rect().get_center()
	for idx in SLOT_COUNT:
		if placed >= MAX_CARDS_PER_TURN:
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
		_:
			_flash(panel, COLOR_HIT)
			_float_text(panel, "-%d" % ev["amount"])


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


# Plovoucí číslo nad panelem, které vyjede nahoru a zmizí.
func _float_text(node: Control, text: String) -> void:
	var label := _make_label(text, 26, COLOR_HIT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var center := node.get_global_rect().get_center()
	label.global_position = center - Vector2(12, 16)
	var start_y := label.global_position.y
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "global_position:y", start_y - 40.0, 0.9)
	tw.tween_property(label, "modulate:a", 0.0, 0.9)
	tw.finished.connect(label.queue_free)


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
func _fly_card(card: Dictionary, from_center: Vector2, from_rot: float, is_player: bool, idx: int, color: Color, flip: bool = false) -> Tween:
	var panels: Array = player_slot_panels if is_player else enemy_slot_panels
	var slot_panel: Control = panels[idx]
	# Při flipu letí karta rubem nahoru a na půl cesty se otočí lícem.
	var ghost := _make_ghost(card, not flip)
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
	if flip:
		var ft := create_tween()
		ft.tween_property(ghost, "scale:x", 0.02, 0.15)
		ft.tween_callback(_apply_face.bind(ghost, card))
		ft.tween_property(ghost, "scale:x", DRAG_SCALE, 0.15)
	tw.finished.connect(_on_fly_done.bind(ghost, key, slot_panel, color))
	return tw


func _make_ghost(card: Dictionary, face_up: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if face_up:
		_apply_face(panel, card)
	else:
		panel.add_theme_stylebox_override("panel", _make_back_style())
	return panel


func _apply_face(panel: PanelContainer, card: Dictionary) -> void:
	panel.add_theme_stylebox_override("panel", _make_style(COLOR_CARD))
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	_populate_card_view(vb, card, COLOR_CARD_TEXT)


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
	if placed_this_turn >= MAX_CARDS_PER_TURN:
		return "Na tah můžeš zahrát jen %d karty." % MAX_CARDS_PER_TURN
	return ""


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


# Karta se vrátí do ruky, kývne se pružinou.
func _return_drag() -> void:
	var node := drag_node
	drag_node = null
	var src = hand_panels.get(drag_uid)
	drag_uid = -1
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
				_log("%s padá a je ztracen." % card["name"])
				_remove_from_deck(is_player, card["uid"])
				board[idx] = null
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
	if player_deck.is_empty():
		phase = Phase.OVER
		_log("Došly ti karty. Případ prohrán.")
		return true
	return false


func _on_confirm_turn() -> void:
	if phase != Phase.PLAYER:
		return
	phase = Phase.ENEMY
	selected_uid = -1
	hit_events.clear()
	_log("Tah potvrzen. Úředník je na řadě.")
	_refresh()

	await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
	await _enemy_place_animated()
	_resolve_combat()
	_refresh()
	await _play_hit_effects()
	if _check_end():
		_refresh()
		return

	turn += 1
	placed_this_turn = 0
	_fill_hand()
	phase = Phase.PLAYER
	_log("Kolo %d. Na řadě jsi ty." % turn)
	_refresh()


# --- Zobrazení -------------------------------------------------------------

func _refresh() -> void:
	turn_label.text = "Kolo %d" % turn
	match phase:
		Phase.PLAYER:
			phase_label.text = "Tvůj tah · zahráno %d / %d" % [placed_this_turn, MAX_CARDS_PER_TURN]
		Phase.ENEMY:
			phase_label.text = "Tah úředníka"
		Phase.OVER:
			phase_label.text = "Konec případu"
	confirm_btn.disabled = phase != Phase.PLAYER

	official_bar.value = maxi(official_hp, 0)
	official_label.text = "HP %d / %d" % [maxi(official_hp, 0), OFFICIAL_MAX_HP]
	player_bar.value = maxi(player_hp, 0)
	player_label.text = "HP %d / %d" % [maxi(player_hp, 0), PLAYER_MAX_HP]
	player_deck_label.text = "Karet v balíčku: %d" % player_deck.size()
	var in_hand := _available_cards(enemy_deck, _uids_of(enemy_board)).size()
	enemy_hand_label.text = "Ruka úředníka: %d" % in_hand
	for i in enemy_hand_backs.size():
		enemy_hand_backs[i].visible = i < in_hand

	for idx in SLOT_COUNT:
		if not hidden_slots.has(_hidden_key(true, idx)):
			_populate_card_view(player_slot_contents[idx], player_board[idx], COLOR_TEXT)
		if not hidden_slots.has(_hidden_key(false, idx)):
			_populate_card_view(enemy_slot_contents[idx], enemy_board[idx], COLOR_TEXT)

	_rebuild_hand()


func _rebuild_hand() -> void:
	for child in hand_box.get_children():
		hand_box.remove_child(child)
		child.queue_free()
	hand_panels.clear()
	for card in hand:
		var panel := _make_card_panel(card)
		panel.modulate = Color(1.0, 0.95, 0.5) if card["uid"] == selected_uid else Color.WHITE
		if dragging and card["uid"] == drag_uid:
			panel.modulate.a = 0.25
		hand_panels[card["uid"]] = panel
		hand_box.add_child(panel)


func _log(message: String) -> void:
	log_lines.append(message)
	while log_lines.size() > 3:
		log_lines.pop_front()
	var text := ""
	for line in log_lines:
		text += line + "\n"
	log_label.text = text.strip_edges()
