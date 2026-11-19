extends Control
# Hlavní menu: Hrát → výběr obtížnosti → úvodní dialog se šarlatánem → první případ.

const CASE_SCENE := "res://scenes/main.tscn"
const CHARLATAN := "portraits/charlatan.png"
const RAT := "portraits/player.png"

var content: VBoxContainer
var dialog: DialogBox


func _ready() -> void:
	theme = UiKit.theme()
	RenderingServer.set_default_clear_color(UiKit.C_DARK)

	var bg := TextureRect.new()
	bg.texture = UiKit.tex("bg/city.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(UiKit.C_DARK, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	center.add_child(content)

	dialog = DialogBox.new()
	add_child(dialog)
	_show_main()


func _clear() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()


func _centered(node: Control) -> Control:
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(node)
	return node


func _show_main() -> void:
	_clear()
	var frame := UiKit.panel("ui/plaque.png", 8, 4)
	var pic := TextureRect.new()
	pic.texture = UiKit.tex(RAT)
	pic.custom_minimum_size = Vector2(160, 160)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	frame.add_child(pic)
	_centered(frame)
	_centered(UiKit.label("CARD BUREAUCRACY", UiKit.FS_S * 6, UiKit.C_GOLD_LIGHT, true))
	_centered(UiKit.label("Kariéra jedné krysy", UiKit.FS_M, UiKit.C_PAPER, true))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	content.add_child(gap)
	var play := UiKit.button("HRÁT", Vector2(320, 64))
	play.pressed.connect(_show_difficulty)
	_centered(play)
	var quit := UiKit.button("KONEC", Vector2(320, 64))
	quit.pressed.connect(func() -> void: get_tree().quit())
	_centered(quit)
	play.grab_focus.call_deferred()


func _show_difficulty() -> void:
	_clear()
	_centered(UiKit.label("VYBER SI OBTÍŽNOST", UiKit.FS_XL, UiKit.C_GOLD_LIGHT, true))
	_centered(UiKit.label("Mění velikost balíčku, ceny na úřadě a v baru.", UiKit.FS_M, UiKit.C_PAPER, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_centered(row)
	for i in GameState.DIFFICULTIES.size():
		row.add_child(_difficulty_card(i))
	var back := UiKit.button("ZPĚT", Vector2(240, 56))
	back.pressed.connect(_show_main)
	_centered(back)


# Obtížnost jako velké klikatelné okno: název, popis, ceny.
func _difficulty_card(i: int) -> Control:
	var d: Dictionary = GameState.DIFFICULTIES[i]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(300, 280)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", UiKit.tex_style("ui/panel_frame.png", 12, 16))
	btn.add_theme_stylebox_override("hover", UiKit.tex_style("ui/plaque.png", 12, 16))
	btn.add_theme_stylebox_override("pressed", UiKit.tex_style("ui/plaque.png", 12, 16))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_start_game.bind(i))

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 18
	vb.offset_top = 16
	vb.offset_right = -18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 8)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)
	var colors := [UiKit.C_GREEN, UiKit.C_GOLD_LIGHT, UiKit.C_RED_LIGHT]
	vb.add_child(UiKit.label(d["name"], UiKit.FS_M, colors[i], true))
	var desc := UiKit.label(d["desc"], UiKit.FS_M, UiKit.C_PAPER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(264, 0)
	vb.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)
	vb.add_child(_price_row("Tvůj balíček", "%d karet" % d["deck_size"]))
	vb.add_child(_price_row("Další kolo", "%d g" % d["round_cost"]))
	vb.add_child(_price_row("Výkup ruky", "%d g" % d["hand_price"]))
	vb.add_child(_price_row("Protéza", "%d g" % d["prosthesis_price"]))
	UiKit.ignore_mouse(vb)
	return btn


func _price_row(what: String, price: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_child(UiKit.label(what, UiKit.FS_S, UiKit.C_GREY))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(gap)
	hb.add_child(UiKit.label(price, UiKit.FS_M, UiKit.C_GOLD))
	return hb


func _start_game(diff: int) -> void:
	GameState.new_game(diff)
	content.get_parent().visible = false
	await _intro()
	GameState.goto(CASE_SCENE)


# Tutoriál: šarlatán na ulici prozradí heslo do baru ve slumech.
func _intro() -> void:
	var who := "Šarlatán"
	var col := Color("#b45cff")
	var choice: String = await dialog.run([
		{"who": who, "portrait": CHARLATAN, "color": col, "text": "Psst. Ty. Jo, ty s tím ocasem."},
		{"who": who, "portrait": CHARLATAN, "color": col, "text": "Jdeš na úřad? S tímhle čumákem? Tam ti sežerou i fousky."},
		{"who": who, "portrait": CHARLATAN, "color": col, "text": "Až tě oškubou, a oni tě oškubou, zajdi dolů do slumů. Bar U Zlaté krysy."},
		{"who": who, "portrait": CHARLATAN, "color": col,
			"text": "Barmanovi řekneš: „Jdu sem pro Honzu.“ Zapamatuj si to. Za radu nic nechci. Zatím.",
			"choices": [
				{"id": "ok", "text": "Jdu sem pro Honzu. Zapamatováno."},
				{"id": "no", "text": "Do slumů? Já? Nikdy."},
			]},
	])
	GameState.knows_password = true
	var reply := "Chytrá krysa. Tak běž, úřad zavírá za deset minut. Jako vždycky."
	if choice == "no":
		reply = "Jasně. Všichni to říkají. Heslo si stejně pamatuješ, viď?"
	await dialog.run([
		{"who": who, "portrait": CHARLATAN, "color": col, "text": reply},
		{"who": "Ty", "portrait": RAT, "color": UiKit.C_BLUE_LIGHT, "text": "„Jdu sem pro Honzu.“ Jasně. A teď razítko."},
	])
