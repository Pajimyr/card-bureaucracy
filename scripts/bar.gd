extends Control
# Bar U Zlaté krysy. Barman, heslo „Jdu sem pro Honzu“, závěs, a za ním
# Honzův obchod: výkup rukou (groše za debuff), protézy a další zboží (GameState.SHOP_ORDER).

const CITY_SCENE := "res://scenes/city.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const BARMAN := "portraits/barman.png"
const RAT := "portraits/player.png"
const BARMAN_COLOR := Color("#ee6b55")
const BARMAN_SPRITE_POS := Vector2(564, 280)  # BARMAN_POS z tools/gen_world.py × 2

var barman_sprite: TextureRect
var barman_frames: Array = []
var barman_t := 0.0

var bg: TextureRect
var dialog: DialogBox
var shop: Control
var money_label: Label
var status_label: Label
var shop_buttons: Dictionary = {}  # id zboží -> Button
var leave_btn: Button


func _ready() -> void:
	theme = UiKit.theme()
	RenderingServer.set_default_clear_color(UiKit.C_DARK)
	bg = TextureRect.new()
	bg.texture = UiKit.tex("world/bar_inside.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	barman_frames = [UiKit.tex("world/barman_0.png"), UiKit.tex("world/barman_1.png")]
	barman_sprite = TextureRect.new()
	barman_sprite.texture = barman_frames[0]
	barman_sprite.position = BARMAN_SPRITE_POS
	barman_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(barman_sprite)
	dialog = DialogBox.new()
	add_child(dialog)
	_talk.call_deferred()


# Barman za pultem dýchá (2 snímky).
func _process(delta: float) -> void:
	barman_t += delta
	if barman_t >= 0.9:
		barman_t = 0.0
		barman_sprite.texture = barman_frames[1] if barman_sprite.texture == barman_frames[0] else barman_frames[0]


func _barman(text: String, choices: Array = []) -> Dictionary:
	var line := {"who": "Barman", "portrait": BARMAN, "color": BARMAN_COLOR, "text": text}
	if not choices.is_empty():
		line["choices"] = choices
	return line


func _talk() -> void:
	var forced := GameState.last_result == "lose" and not GameState.can_afford_round()
	if forced:
		await dialog.run([
			_barman("Zase z úřadu, co? Vidím ti to na fouskách."),
			_barman("Bez grošů tě tam znova nepustí. Takže buď prodáš, nebo spíš pod mostem."),
		])
	await _ask()


func _ask() -> void:
	var choices := []
	if GameState.knows_password:
		choices.append({"id": "honza", "text": "Jdu sem pro Honzu."})
	choices.append({"id": "beer", "text": "Dám si pivo."})
	choices.append({"id": "leave", "text": "Nic. Jdu pryč."})
	var choice: String = await dialog.run([_barman("Co to bude, krysáku?", choices)])
	match choice:
		"honza":
			await dialog.run([
				{"who": "Ty", "portrait": RAT, "color": UiKit.C_BLUE_LIGHT, "text": "Jdu sem pro Honzu."},
				_barman("…Honza, říkáš. Tak pojď. A na nic nesahej."),
			])
			_enter_back_room()
		"beer":
			await dialog.run([_barman("Pivo je pro lidi. Ty bys potřeboval spíš peníze. Další.")])
			await _ask()
		_:
			_leave()


# Barman odhrne závěs, scéna se ztmaví a za ní je zadní místnost s obchodem.
func _enter_back_room() -> void:
	# Barman odešel odhrnout závěs.
	bg.texture = UiKit.tex("world/bar_inside_open.png")
	barman_sprite.visible = false
	await get_tree().create_timer(0.4).timeout
	var black := ColorRect.new()
	black.color = Color(UiKit.C_DARK, 0.0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.z_index = 60
	add_child(black)
	var tw := create_tween()
	tw.tween_property(black, "color:a", 1.0, 0.3)
	await tw.finished
	bg.texture = UiKit.tex("world/back_room.png")
	_build_shop()
	var back := create_tween()
	back.tween_property(black, "color:a", 0.0, 0.3)
	back.tween_callback(black.queue_free)


func _build_shop() -> void:
	shop = CenterContainer.new()
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shop)
	var box := UiKit.panel("ui/panel_frame.png", 12, 18)
	shop.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	box.add_child(vb)

	var head := HBoxContainer.new()
	vb.add_child(head)
	head.add_child(UiKit.label("U HONZY · VÝKUP A PRODEJ", UiKit.FS_M, UiKit.C_GOLD_LIGHT, true))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var coin := TextureRect.new()
	coin.texture = UiKit.tex("icons/grose.png")
	coin.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	head.add_child(coin)
	money_label = UiKit.label("", UiKit.FS_M, UiKit.C_GOLD, true)
	head.add_child(money_label)

	var quote := UiKit.label("Honza si tě změří jedním okem. „Ruka je ruka. Beru každou. A prodám ti cokoli.“", UiKit.FS_M, UiKit.C_PAPER)
	vb.add_child(quote)

	# Zboží v mřížce 3 sloupce, pořadí podle GameState.SHOP_ORDER.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(grid)
	for id in GameState.SHOP_ORDER:
		grid.add_child(_offer(id))

	status_label = UiKit.label("", UiKit.FS_M, UiKit.C_PAPER_DIM)
	status_label.custom_minimum_size = Vector2(0, 24)
	vb.add_child(status_label)
	leave_btn = UiKit.button("ODEJÍT", Vector2(240, 52))
	leave_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leave_btn.pressed.connect(_leave)
	vb.add_child(leave_btn)
	_refresh_shop()


# Jedna nabídka: karta zboží vlevo, cena, poznámka a tlačítko vpravo.
func _offer(id: String) -> Control:
	var title: String
	var short: String
	var note: String
	var icon: String
	var is_buff := true
	match id:
		"sell_hand":
			title = "Tvoje ruka"
			short = "-1 karta/tah"
			note = "Výkup. Kterou, rozhodne Honza."
			icon = "paw"
			is_buff = false
		"prosthesis":
			title = "Protéza"
			short = "karta zpět"
			note = "Nahradí ruku. Jizva zůstane."
			icon = "prosthesis"
		_:
			var item: Dictionary = GameState.ITEMS[id]
			title = item["title"]
			short = item["short"]
			note = item["note"]
			icon = GameState.EFFECTS[id]["icon"] if GameState.EFFECTS.has(id) else id
	var panel := UiKit.panel("ui/plaque_dark.png", 12, 10)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)
	hb.add_child(UiKit.effect_card(icon, title, short, is_buff))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.custom_minimum_size = Vector2(200, 0)
	hb.add_child(right)
	var selling := id == "sell_hand"
	var price := UiKit.label(("+%d g" if selling else "-%d g") % GameState.item_price(id), UiKit.FS_M,
		UiKit.C_GOLD if selling else UiKit.C_RED_LIGHT, true)
	right.add_child(price)
	var n := UiKit.label(note, UiKit.FS_S * 2, UiKit.C_PAPER_DIM)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(200, 0)
	right.add_child(n)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	var btn := UiKit.button("PRODAT" if selling else "KOUPIT", Vector2(200, 40))
	btn.pressed.connect(_on_trade.bind(id))
	right.add_child(btn)
	shop_buttons[id] = btn
	return panel


func _refresh_shop() -> void:
	money_label.text = "%d grošů" % GameState.grose
	for id in shop_buttons:
		var btn: Button = shop_buttons[id]
		var problem := GameState.item_problem(id)
		btn.disabled = problem != ""
		btn.text = problem if problem != "" else ("PRODAT" if id == "sell_hand" else "KOUPIT")


func _on_trade(id: String) -> void:
	var price := GameState.item_price(id)
	var before := GameState.effects.duplicate(true)
	if not GameState.buy_item(id):
		return
	var good := true
	var text := ""
	match id:
		"sell_hand":
			var side: String = GameState.effects[-1]["side"]
			text = "Honza ti vzal %s ruku. Bude ti chybět jedna karta za tah." % GameState.SIDE_ACC[side]
			good = false
			UiKit.shake(self, 8.0)
		"prosthesis":
			var side := ""
			for i in GameState.effects.size():
				if GameState.effects[i]["id"] == "prosthesis" and before[i]["id"] == "no_hand":
					side = GameState.effects[i]["side"]
			text = "%s protéza sedí. Skoro jako vlastní." % GameState.SIDE_ADJ.get(side, "Nová")
		"salve":
			text = "Mast pálí jako čert, ale žebro srostlo. Max HP zpátky."
		"vest":
			text = "Vesta drží. Na úřadě vydržíš o %d HP víc." % GameState.VEST_HP
		"fake_stamp":
			text = "Razítko je skoro pravé. V každém případu máš kartu navíc."
		"bribe":
			text = "Obálka zmizí v kapse. Příští úředník začne o %d HP slabší." % GameState.BRIBE_HP
		"coffee":
			text = "Kafe je hnusné a silné. Příští případ hraješ o kartu víc."
	status_label.text = text
	status_label.add_theme_color_override("font_color", UiKit.C_RED_LIGHT if not good else UiKit.C_GREEN)
	var sign := "+" if id == "sell_hand" else "-"
	UiKit.float_text(self, money_label.get_global_rect().get_center(), "%s%d" % [sign, price],
		UiKit.C_GOLD_LIGHT if id == "sell_hand" else UiKit.C_RED_LIGHT)
	_refresh_shop()


func _leave() -> void:
	if GameState.is_stuck():
		if shop:
			shop.visible = false
		UiKit.stamp_overlay(self, "KONEC KARIÉRY", "Bez grošů a bez rukou. Úřad vyhrál.", UiKit.C_RED, "HLAVNÍ MENU",
			func() -> void: GameState.goto(MENU_SCENE))
		return
	GameState.goto(CITY_SCENE)
