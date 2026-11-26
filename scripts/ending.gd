extends Control
# Konec hry, výhra: krysa porazila ředitele na posledním patře (GameState.career_won).
# Krátký dialog se šarlatánem, pak razítko KARIÉRA DOKONČENA a statistiky celé hry.

const MENU_SCENE := "res://scenes/menu.tscn"
const CHARLATAN := "portraits/charlatan.png"
const RAT := "portraits/player.png"
const CHARLATAN_COLOR := Color("#b45cff")

var dialog: DialogBox
var content: VBoxContainer


func _ready() -> void:
	theme = UiKit.theme()
	RenderingServer.set_default_clear_color(UiKit.C_DARK)
	var bg := TextureRect.new()
	bg.texture = UiKit.tex("bg/city.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(UiKit.C_DARK, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	center.add_child(content)

	dialog = DialogBox.new()
	add_child(dialog)
	_play.call_deferred()


func _play() -> void:
	await dialog.run([
		{"who": "Ty", "portrait": RAT, "color": UiKit.C_BLUE_LIGHT,
			"text": "Ředitelská kancelář. Koberec, výhled na celé město. A slumy odsud vůbec nejsou vidět."},
		{"who": "Šarlatán", "portrait": CHARLATAN, "color": CHARLATAN_COLOR,
			"text": "Tak co, krysáku? Razítko máš. Teď můžeš oškubávat ty ostatní."},
		{"who": "Ty", "portrait": RAT, "color": UiKit.C_BLUE_LIGHT,
			"text": "Peníze mám. Jenom ty ruce a žebra už mi nikdo nevrátí."},
		{"who": "Šarlatán", "portrait": CHARLATAN, "color": CHARLATAN_COLOR,
			"text": "Vítej nahoře. Peníze nejsou všechno. Ale tady nahoře se to říká snadno."},
	])
	_show_results()


func _show_results() -> void:
	var frame := UiKit.panel("ui/plaque.png", 8, 4)
	var pic := CharacterPortrait.new()
	pic.setup(RAT, 120)
	frame.add_child(pic)
	_centered(frame)
	_centered(UiKit.label("KARIÉRA DOKONČENA", UiKit.FS_XL, UiKit.C_GOLD_LIGHT, true))
	_centered(UiKit.label("Krysa ze slumů porazila ředitele. Vyhrál jsi.", UiKit.FS_M, UiKit.C_PAPER, true))

	var stats := UiKit.panel("ui/panel_frame.png", 12, 16)
	stats.custom_minimum_size = Vector2(520, 0)
	_centered(stats)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	stats.add_child(vb)
	vb.add_child(_row("Obtížnost", GameState.diff()["name"]))
	vb.add_child(_row("Případů celkem", str(GameState.case_number)))
	vb.add_child(_row("Výhry / prohry", "%d / %d" % [GameState.cases_won, GameState.cases_lost]))
	vb.add_child(_row("Groše na konci", "%d" % GameState.grose))
	vb.add_child(_row("Zlomená žebra", str(GameState.ribs())))
	vb.add_child(_row("Prodané ruce", str(GameState.hands_lost() + GameState.count_effect("prosthesis"))))

	var btn := UiKit.button("HLAVNÍ MENU", Vector2(320, 60))
	btn.pressed.connect(func() -> void: GameState.goto(MENU_SCENE))
	_centered(btn)
	btn.grab_focus.call_deferred()
	var stamp: Control
	stamp = UiKit.stamp_overlay(self, "POVÝŠEN", "Patro %d/%d: %s" % [GameState.RANKS.size(), GameState.RANKS.size(), GameState.RANKS[-1]["name"]],
		UiKit.C_GOLD, "DÁL", func() -> void: stamp.queue_free())


func _centered(node: Control) -> Control:
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(node)
	return node


func _row(what: String, value: String) -> Control:
	var hb := HBoxContainer.new()
	hb.add_child(UiKit.label(what, UiKit.FS_M, UiKit.C_GREY))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(gap)
	hb.add_child(UiKit.label(value, UiKit.FS_M, UiKit.C_GOLD))
	return hb
