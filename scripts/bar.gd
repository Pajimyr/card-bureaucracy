extends Control
# Bar U Zlaté krysy. Barman, heslo „Jdu sem pro Honzu“, závěs, a za ním
# Honzův obchod: výkup rukou (groše za debuff) a protézy (buff za groše).

const CITY_SCENE := "res://scenes/city.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const BARMAN := "portraits/barman.png"
const RAT := "portraits/player.png"
const BARMAN_COLOR := Color("#ee6b55")

var bg: TextureRect
var dialog: DialogBox
var shop: Control
var money_label: Label
var status_label: Label
var sell_btn: Button
var buy_btn: Button
var leave_btn: Button


func _ready() -> void:
	theme = UiKit.theme()
	RenderingServer.set_default_clear_color(UiKit.C_DARK)
	bg = TextureRect.new()
	bg.texture = UiKit.tex("world/bar_inside.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	dialog = DialogBox.new()
	add_child(dialog)
	_talk.call_deferred()


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
	bg.texture = UiKit.tex("world/bar_inside_open.png")
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
	var box := UiKit.panel("ui/panel_frame.png", 12, 22)
	shop.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
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

	var quote := UiKit.label("Honza si tě změří jedním okem. „Ruka je ruka. Beru každou.“", UiKit.FS_M, UiKit.C_PAPER)
	vb.add_child(quote)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	vb.add_child(cols)
	sell_btn = UiKit.button("PRODAT", Vector2(200, 56))
	sell_btn.pressed.connect(_on_sell)
	cols.add_child(_offer("PRODEJ",
		UiKit.effect_card("paw", "Tvoje ruka", "-1 karta/tah", false),
		"+%d grošů" % GameState.hand_price(), UiKit.C_GOLD,
		"Která, rozhodne Honza.", sell_btn))
	buy_btn = UiKit.button("KOUPIT", Vector2(200, 56))
	buy_btn.pressed.connect(_on_buy)
	cols.add_child(_offer("NÁKUP",
		UiKit.effect_card("prosthesis", "Protéza", "karta zpět", true),
		"-%d grošů" % GameState.prosthesis_price(), UiKit.C_RED_LIGHT,
		"Jizva zůstane.", buy_btn))

	status_label = UiKit.label("", UiKit.FS_M, UiKit.C_PAPER_DIM)
	status_label.custom_minimum_size = Vector2(0, 24)
	vb.add_child(status_label)
	leave_btn = UiKit.button("ODEJÍT", Vector2(240, 56))
	leave_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leave_btn.pressed.connect(_leave)
	vb.add_child(leave_btn)
	_refresh_shop()


func _offer(title: String, card: Control, price: String, price_color: Color, note: String, btn: Button) -> Control:
	var panel := UiKit.panel("ui/plaque_dark.png", 12, 16)
	panel.custom_minimum_size = Vector2(300, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	vb.add_child(UiKit.label(title, UiKit.FS_S, UiKit.C_GREY))
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(card)
	var p := UiKit.label(price, UiKit.FS_L, price_color, true)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(p)
	var n := UiKit.label(note, UiKit.FS_M, UiKit.C_PAPER_DIM)
	n.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(n)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(btn)
	return panel


func _refresh_shop() -> void:
	money_label.text = "%d grošů" % GameState.grose
	sell_btn.disabled = not GameState.can_sell_hand()
	sell_btn.text = "PRODAT" if GameState.can_sell_hand() else "UŽ NEMÁŠ"
	buy_btn.disabled = not GameState.can_buy_prosthesis()
	if GameState.hands_lost() == 0:
		buy_btn.text = "NEPOTŘEBUJEŠ"
	elif GameState.grose < GameState.prosthesis_price():
		buy_btn.text = "NEMÁŠ NA TO"
	else:
		buy_btn.text = "KOUPIT"


func _on_sell() -> void:
	var e := GameState.sell_hand()
	if e.is_empty():
		return
	status_label.text = "Honza ti vzal %s ruku. Bude ti chybět jedna karta za tah." % GameState.SIDE_ACC[e["side"]]
	status_label.add_theme_color_override("font_color", UiKit.C_RED_LIGHT)
	UiKit.shake(self, 8.0)
	UiKit.float_text(self, money_label.get_global_rect().get_center(), "+%d" % GameState.hand_price(), UiKit.C_GOLD_LIGHT)
	_refresh_shop()


func _on_buy() -> void:
	var e := GameState.buy_prosthesis()
	if e.is_empty():
		return
	status_label.text = "%s protéza sedí. Skoro jako vlastní." % GameState.SIDE_ADJ[e["side"]]
	status_label.add_theme_color_override("font_color", UiKit.C_GREEN)
	UiKit.float_text(self, money_label.get_global_rect().get_center(), "-%d" % GameState.prosthesis_price(), UiKit.C_RED_LIGHT)
	_refresh_shop()


func _leave() -> void:
	if GameState.is_stuck():
		if shop:
			shop.visible = false
		UiKit.stamp_overlay(self, "KONEC KARIÉRY", "Bez grošů a bez rukou. Úřad vyhrál.", UiKit.C_RED, "HLAVNÍ MENU",
			func() -> void: GameState.goto(MENU_SCENE))
		return
	GameState.goto(CITY_SCENE)
