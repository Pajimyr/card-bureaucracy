class_name Roulette
extends Control
# Šarlatánova ruleta. Když krysa nemá v ruce žádnou kartu, může zkusit štěstí.
# 8 dlaždic v elipse kolem šarlatána, zvýraznění skáče po kruhu a zpomaluje.
#
#   var seg: Dictionary = await Roulette.spin(self)
#   # seg = {"kind": "cards", "n": 2} | {"kind": "rib"} | {"kind": "hand"}
#
# Výsledek uplatňuje volající (main.gd), ruleta ho jen vylosuje a ukáže.

signal _finished(result: Dictionary)

const CHARLATAN := "portraits/charlatan.png"
const CHARLATAN_COLOR := Color("#b45cff")
# Pořadí po kruhu od vrchu po směru hodinových ručiček. 3 výhry z 8, viz docs/balance.md.
const SEGMENTS := [
	{"kind": "cards", "n": 2},
	{"kind": "rib"},
	{"kind": "cards", "n": 3},
	{"kind": "hand"},
	{"kind": "rib"},
	{"kind": "cards", "n": 2},
	{"kind": "rib"},
	{"kind": "rib"},
]
const TILE_SIZE := Vector2(136, 96)
const CENTER := Vector2(640, 320)
const RADIUS := Vector2(340, 205)
const DIM := Color(0.5, 0.5, 0.58)

var _tiles: Array = []
var _lit := 0
var _pic: CharacterPortrait
var _say: Label
var _btn: Button


static func spin(parent: Control) -> Dictionary:
	var r := Roulette.new()
	parent.add_child(r)
	var result: Dictionary = await r._finished
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.2)
	await tw.finished
	r.queue_free()
	return result


static func is_win(seg: Dictionary) -> bool:
	return seg["kind"] == "cards"


static func seg_icon(seg: Dictionary) -> String:
	match seg["kind"]:
		"cards":
			return "copies"
		"hand":
			return "paw"
	return "rib"


static func seg_title(seg: Dictionary) -> String:
	match seg["kind"]:
		"cards":
			return "+%d karty" % seg["n"]
		"hand":
			return "RUKA"
	return "ŽEBRO"


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	theme = UiKit.theme()

	var dim := ColorRect.new()
	dim.color = Color(UiKit.C_DARK, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var title := UiKit.label("ŠARLATÁNOVA RULETA", UiKit.FS_XL, UiKit.C_GOLD_LIGHT, true)
	title.position = Vector2(0, 22)
	title.size = Vector2(1280, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var frame := UiKit.panel("ui/plaque.png", 8, 4)
	add_child(frame)
	_pic = CharacterPortrait.new()
	_pic.setup(CHARLATAN, 160)
	frame.add_child(_pic)
	frame.reset_size()
	frame.position = CENTER - frame.size / 2.0 - Vector2(0, 16)

	_say = UiKit.label("Ruka prázdná? Zatoč. Nebo nezatoč. Mně je to jedno.", UiKit.FS_M, CHARLATAN_COLOR, true)
	_say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_say.position = Vector2(CENTER.x - 300, CENTER.y + 82)
	_say.size = Vector2(600, 24)
	add_child(_say)

	for i in SEGMENTS.size():
		var tile := _make_tile(SEGMENTS[i])
		var a := -PI / 2.0 + TAU * i / SEGMENTS.size()
		tile.position = CENTER + Vector2(cos(a), sin(a)) * RADIUS - TILE_SIZE / 2.0
		add_child(tile)
		_tiles.append(tile)

	_btn = UiKit.button("ZATOČIT!", Vector2(320, 64))
	_btn.position = Vector2(640 - 160, 636)
	_btn.pressed.connect(_on_spin)
	add_child(_btn)
	_light(0)


func _make_tile(seg: Dictionary) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.size = TILE_SIZE
	tile.pivot_offset = TILE_SIZE / 2.0
	tile.add_theme_stylebox_override("panel", UiKit.tex_style("ui/card_player.png", 12, 6))
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	tile.add_child(vb)
	var icon := TextureRect.new()
	icon.texture = UiKit.tex("icons/card_%s.png" % seg_icon(seg))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64, 64)
	vb.add_child(icon)
	var l := UiKit.label(seg_title(seg), UiKit.FS_M, UiKit.C_GREEN_DARK if is_win(seg) else UiKit.C_RED_DARK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	UiKit.ignore_mouse(tile)
	return tile


func _light(i: int) -> void:
	_lit = i
	for k in _tiles.size():
		var t: Control = _tiles[k]
		var on := k == i
		t.modulate = Color.WHITE if on else DIM
		t.scale = Vector2(1.15, 1.15) if on else Vector2.ONE
		t.z_index = 1 if on else 0


func _on_spin() -> void:
	_btn.disabled = true
	_btn.text = "…"
	_say.text = "Točí se, točí. Jako úřední šiml."
	_pic.set_talking(true)
	var target := randi() % SEGMENTS.size()
	# Aspoň dvě celá kola, pak doběhnout na cíl.
	var steps := SEGMENTS.size() * 2 + posmod(target - _lit, SEGMENTS.size())
	for s in steps:
		var t := float(s) / steps
		await get_tree().create_timer(lerpf(0.04, 0.38, t * t * t)).timeout
		_light((_lit + 1) % SEGMENTS.size())
		if s == 4:
			_pic.set_talking(false)
	await _reveal(SEGMENTS[target])


func _reveal(seg: Dictionary) -> void:
	var tile: Control = _tiles[_lit]
	var win := is_win(seg)
	for k in 3:
		tile.modulate = DIM
		await get_tree().create_timer(0.1).timeout
		tile.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
	var tw := create_tween()
	tw.tween_property(tile, "scale", Vector2(1.35, 1.35), 0.08)
	tw.tween_property(tile, "scale", Vector2(1.15, 1.15), 0.12)
	if win:
		_say.text = "Štěstí přeje krysám. Zatím."
		_say.add_theme_color_override("font_color", UiKit.C_GREEN)
	else:
		_say.text = "Dům vždycky vyhrává."
		_say.add_theme_color_override("font_color", UiKit.C_RED_LIGHT)
		UiKit.shake(self, 8.0)
	_pic.set_talking(true)
	await get_tree().create_timer(0.6).timeout
	_pic.set_talking(false)
	_btn.text = "POKRAČOVAT"
	_btn.disabled = false
	_btn.pressed.disconnect(_on_spin)
	_btn.pressed.connect(func() -> void: _finished.emit(seg))
