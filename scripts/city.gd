extends Control
# Město po případu: vlevo slumy s barem (černý trh), vpravo stav krysy
# (groše, debuffy a buffy) a pod tím úřad, kde se platí za další kolo.

const CASE_SCENE := "res://scenes/main.tscn"
const BAR_SCENE := "res://scenes/bar.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const SLUMS_SIZE := Vector2(860, 636)
const BAR_POS := Vector2(580, 178)  # (BAR_POS z tools/gen_world.py - 2px okraj sprite) × 2
const CAPTION_IDLE := "Dolní město. Sem končí každý, koho úřad oškube."
const FIRE_POS := Vector2(302, 480)  # FIRE_POS z tools/gen_world.py × 2

var fire: TextureRect
var fire_frames: Array = []
var fire_t := 0.0
var bar_btn: TextureButton
var bar_hovered := false
var neon_t := 2.0

var caption: Label
var urad_btn: TextureButton
var urad_note: Label


func _ready() -> void:
	theme = UiKit.theme()
	RenderingServer.set_default_clear_color(UiKit.C_DARK)

	var bg := TextureRect.new()
	bg.texture = UiKit.tex("bg/city.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(main)
	main.add_child(_make_slums())
	main.add_child(_make_side())

	if GameState.is_stuck():
		_career_over.call_deferred()


func _make_header() -> Control:
	var header := PanelContainer.new()
	var sb := UiKit.tex_style("ui/plaque.png", 12)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	header.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	header.add_child(hb)
	hb.add_child(UiKit.label("SLUMY", UiKit.FS_M, UiKit.C_GOLD_LIGHT, true))
	hb.add_child(UiKit.label("  ·  ", UiKit.FS_M, UiKit.C_PAPER, true))
	hb.add_child(_make_career())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spacer)
	hb.add_child(UiKit.label(GameState.diff()["name"].to_upper(), UiKit.FS_M, UiKit.C_PAPER_DIM, true))
	return header


# Slumy: obrázek, na něm klikatelný bar. Pod myší se rozsvítí a změní se popisek.
func _make_slums() -> Control:
	var frame := UiKit.panel("ui/panel_frame.png", 12, 6)
	var area := Control.new()
	area.custom_minimum_size = SLUMS_SIZE
	area.clip_contents = true
	frame.add_child(area)
	var pic := TextureRect.new()
	pic.texture = UiKit.tex("world/slums.png")
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(pic)

	fire_frames = [UiKit.tex("world/fire_0.png"), UiKit.tex("world/fire_1.png"), UiKit.tex("world/fire_2.png")]
	fire = TextureRect.new()
	fire.texture = fire_frames[0]
	fire.position = FIRE_POS
	fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(fire)

	var bar := UiKit.hotspot("world/bar.png", "world/bar_hover.png")
	bar.position = BAR_POS
	bar.pressed.connect(func() -> void: GameState.goto(BAR_SCENE))
	bar.mouse_entered.connect(_on_bar_hover.bind(true))
	bar.mouse_exited.connect(_on_bar_hover.bind(false))
	area.add_child(bar)
	bar_btn = bar

	var plate := UiKit.panel("ui/plaque_dark.png", 12, 10)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.position = Vector2(12, SLUMS_SIZE.y - 56)
	area.add_child(plate)
	caption = UiKit.label(CAPTION_IDLE, UiKit.FS_M, UiKit.C_PAPER)
	plate.add_child(caption)
	return frame


func _on_bar_hover(inside: bool) -> void:
	bar_hovered = inside
	bar_btn.texture_normal = UiKit.tex("world/bar.png")
	if inside:
		_set_caption("BAR U ZLATÉ KRYSY · černý trh. Heslo znáš.", UiKit.C_PINK)
	else:
		_set_caption(CAPTION_IDLE, UiKit.C_PAPER)


# Plamen v sudu se míhá, neon baru občas zabliká (rozbitý trafo, co jiného).
func _process(delta: float) -> void:
	fire_t += delta
	if fire_t >= 0.12:
		fire_t = 0.0
		fire.texture = fire_frames[randi() % fire_frames.size()]
	neon_t -= delta
	if neon_t <= 0.0 and not bar_hovered:
		_flicker_neon()
		neon_t = randf_range(2.0, 6.0)


func _flicker_neon() -> void:
	var on := UiKit.tex("world/bar.png")
	var off := UiKit.tex("world/bar_off.png")
	var tw := create_tween()
	for i in randi_range(1, 3):
		tw.tween_callback(func() -> void: if not bar_hovered: bar_btn.texture_normal = off)
		tw.tween_interval(randf_range(0.05, 0.15))
		tw.tween_callback(func() -> void: bar_btn.texture_normal = on)
		tw.tween_interval(randf_range(0.05, 0.2))


func _set_caption(text: String, color: Color) -> void:
	caption.text = text
	caption.add_theme_color_override("font_color", color)


func _make_side() -> Control:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 10)

	# Stav krysy
	var info := UiKit.panel("ui/panel_player.png", 12, 14)
	side.add_child(info)
	var ivb := VBoxContainer.new()
	ivb.add_theme_constant_override("separation", 4)
	info.add_child(ivb)
	ivb.add_child(UiKit.label("STAV KRYSY", UiKit.FS_S, UiKit.C_GREY))
	var money := HBoxContainer.new()
	money.add_theme_constant_override("separation", 10)
	ivb.add_child(money)
	var coin := TextureRect.new()
	coin.texture = UiKit.tex("icons/grose.png")
	coin.custom_minimum_size = Vector2(48, 48)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_SCALE
	money.add_child(coin)
	money.add_child(UiKit.label("%d grošů" % GameState.grose, UiKit.FS_L, UiKit.C_GOLD, true))
	var result := "Poslední případ: "
	var res_color := UiKit.C_GREY
	match GameState.last_result:
		"win":
			result += "VÝHRA (+%d)" % GameState.WIN_REWARD
			res_color = UiKit.C_GREEN
		"lose":
			result += "PROHRA"
			res_color = UiKit.C_RED_LIGHT
		_:
			result += "žádný"
	ivb.add_child(UiKit.label(result, UiKit.FS_M, res_color))
	ivb.add_child(UiKit.label("Karet za tah: %d · Max HP: %d" % [GameState.cards_per_turn(), GameState.player_max_hp()], UiKit.FS_M, UiKit.C_PAPER))

	# Debuffy a buffy jako karty
	var fx := UiKit.panel("ui/panel_frame.png", 12, 14)
	side.add_child(fx)
	var fvb := VBoxContainer.new()
	fvb.add_theme_constant_override("separation", 6)
	fx.add_child(fvb)
	fvb.add_child(UiKit.label("DEBUFFY A BUFFY", UiKit.FS_S, UiKit.C_GREY))
	# Do dvou efektů velké karty, víc se nevejde, tak kompaktní žetony ve dvou sloupcích.
	# Stejné efekty bez strany (žebra, vesty, razítka) se sčítají do jednoho žetonu.
	var groups := _effect_groups()
	if groups.is_empty():
		fvb.add_child(UiKit.label("Zatím celá krysa.", UiKit.FS_M, UiKit.C_PAPER_DIM))
	elif groups.size() <= 2:
		var cards := HBoxContainer.new()
		cards.add_theme_constant_override("separation", 10)
		fvb.add_child(cards)
		for g in groups:
			cards.add_child(UiKit.effect_card(g["icon"], g["title"], g["short"], g["buff"]))
	else:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		fvb.add_child(grid)
		for g in groups:
			grid.add_child(_effect_row(g))

	# Úřad: další kolo za poplatek
	var urad_box := VBoxContainer.new()
	urad_box.add_theme_constant_override("separation", 4)
	urad_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	urad_box.alignment = BoxContainer.ALIGNMENT_END
	side.add_child(urad_box)
	urad_btn = UiKit.hotspot("world/urad.png", "world/urad_hover.png", "world/urad_disabled.png")
	urad_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	urad_btn.disabled = not GameState.can_afford_round()
	urad_btn.pressed.connect(_on_urad)
	urad_box.add_child(urad_btn)
	var what := "PATRO %d: %s" % [GameState.rank + 1, GameState.current_rank()["name"].to_upper()]
	if GameState.last_result == "lose":
		what = "ZNOVU " + what
	var title := UiKit.label("ÚŘAD · %s" % what, UiKit.FS_M, UiKit.C_GOLD_LIGHT, true)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	urad_box.add_child(title)
	urad_note = UiKit.label("", UiKit.FS_M, UiKit.C_PAPER, true)
	urad_note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	urad_box.add_child(urad_note)
	if urad_btn.disabled:
		urad_note.text = "Nemáš na poplatek (%d g). Zkus bar." % GameState.round_cost()
		urad_note.add_theme_color_override("font_color", UiKit.C_RED_LIGHT)
		urad_btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		urad_note.text = "Poplatek: %d grošů" % GameState.round_cost()
	return side


func _on_urad() -> void:
	if GameState.pay_round():
		GameState.goto(CASE_SCENE)


# Kariéra v záhlaví: žeton za každé patro (zlatý = splněno), aktuální patro a cíl hry.
func _make_career() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(UiKit.label("KARIÉRA ", UiKit.FS_M, UiKit.C_PAPER, true))
	for i in GameState.RANKS.size():
		row.add_child(UiKit.icon("icons/energy_on.png" if i < GameState.rank else "icons/energy_off.png"))
	var r: Dictionary = GameState.current_rank()
	var boss := " (boss)" if r.get("boss", false) else ""
	row.add_child(UiKit.label("  Patro %d/%d: %s%s" % [GameState.rank + 1, GameState.RANKS.size(), r["name"], boss],
		UiKit.FS_M, UiKit.C_GOLD_LIGHT, true))
	row.add_child(UiKit.label("  ·  poraz ředitele a vyhraješ", UiKit.FS_M, UiKit.C_PAPER_DIM, true))
	return row


func _career_over() -> void:
	UiKit.stamp_overlay(self, "KONEC KARIÉRY", "Bez grošů a bez rukou. Úřad vyhrál.", UiKit.C_RED, "HLAVNÍ MENU",
		func() -> void: GameState.goto(MENU_SCENE))


func _effect_groups() -> Array:
	var out: Array = []
	var by_id := {}
	for e in GameState.effects:
		var def: Dictionary = GameState.EFFECTS[e["id"]]
		if not e.has("side") and by_id.has(e["id"]):
			by_id[e["id"]]["count"] += 1
			continue
		var g := {"id": e["id"], "icon": def["icon"], "title": GameState.effect_title(e), "short": def["short"],
			"buff": def["kind"] == "buff", "count": 1}
		out.append(g)
		if not e.has("side"):
			by_id[e["id"]] = g
	for g in out:
		if g["count"] > 1:
			g["title"] += " ×%d" % g["count"]
			g["short"] = GameState.effect_short(g["id"], g["count"])
	return out


func _effect_row(g: Dictionary) -> Control:
	var row := PanelContainer.new()
	var sb := UiKit.tex_style("ui/card_player.png", 12, 4)
	sb.content_margin_right = 14  # pravý horní roh karty je ohnutý
	row.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	row.add_child(hb)
	var pic := TextureRect.new()
	pic.texture = UiKit.tex("icons/card_%s.png" % g["icon"])
	pic.custom_minimum_size = Vector2(32, 32)
	hb.add_child(pic)
	var sh := UiKit.label(g["short"], UiKit.FS_M, UiKit.C_GREEN_DARK if g["buff"] else UiKit.C_RED_DARK)
	sh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(sh)
	UiKit.ignore_mouse(row)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.tooltip_text = g["title"]  # celý název efektu pod myší
	return row
