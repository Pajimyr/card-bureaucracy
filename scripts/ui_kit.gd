class_name UiKit
extends RefCounted
# Sdílené stavební kameny UI pro všechny scény: pixel font, téma, 9-slice styly,
# popisky, karty efektů, otřes a razítko přes obrazovku.
# Textury jsou už zvětšené 2x, okraje se zadávají v obrazovkových pixelech.

const ASSETS := "res://assets/"

# Pixel font má základní velikost 12 a škáluje se jen celočíselně.
const FS_S := 12
const FS_M := 24
const FS_L := 36
const FS_XL := 48

# Paleta (stejná jako v tools/gen_assets.py)
const C_INK := Color("#1c1726")
const C_PAPER := Color("#eee2bb")
const C_PAPER_DIM := Color("#a8905f")
const C_GOLD := Color("#f2c14e")
const C_GOLD_LIGHT := Color("#fff08a")
const C_RED := Color("#c43a3a")
const C_RED_DARK := Color("#8a1e28")
const C_RED_LIGHT := Color("#ee6b55")
const C_BLUE_LIGHT := Color("#6f95e0")
const C_GREEN := Color("#5fd35f")
const C_GREEN_DARK := Color("#2f8a44")
const C_GREY := Color("#9a9aab")
const C_DARK := Color("#0e0b14")
const C_PINK := Color("#e88ca0")

static var _font: FontFile
static var _theme: Theme


static func font() -> FontFile:
	if _font == null:
		_font = load(ASSETS + "fonts/bureau.fnt")
		_font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	return _font


static func tex(file: String) -> Texture2D:
	return load(ASSETS + file)


# 9-slice styl z textury. tile = střed se dlaždicuje (šum, dřevo), jinak se natahuje.
static func tex_style(file: String, margin: int, content: int = -1, tile: bool = false) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(file)
	sb.set_texture_margin_all(margin)
	sb.set_content_margin_all(content if content >= 0 else margin)
	if tile:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var th := Theme.new()
	th.default_font = font()
	th.default_font_size = FS_M
	th.set_color("font_color", "Label", C_PAPER)

	var normal := tex_style("ui/btn_normal.png", 12)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 16
	var hover := tex_style("ui/btn_hover.png", 12)
	hover.content_margin_top = 8
	hover.content_margin_bottom = 16
	var pressed := tex_style("ui/btn_pressed.png", 12)
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 12
	var disabled := tex_style("ui/btn_disabled.png", 12)
	disabled.content_margin_top = 12
	disabled.content_margin_bottom = 12
	for sb in [normal, hover, pressed, disabled]:
		sb.content_margin_left = 20
		sb.content_margin_right = 20
	th.set_stylebox("normal", "Button", normal)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("disabled", "Button", disabled)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color("#fff6da"))
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", C_GOLD_LIGHT)
	th.set_color("font_disabled_color", "Button", C_GREY)
	th.set_color("font_shadow_color", "Button", Color("#4a0f18"))
	th.set_constant("shadow_offset_x", "Button", 2)
	th.set_constant("shadow_offset_y", "Button", 2)

	# Volby v dialogu: tmavá cedulka, pod myší zlatá mosaz.
	var choice := tex_style("ui/plaque_dark.png", 12)
	choice.content_margin_left = 16
	choice.content_margin_right = 16
	choice.content_margin_top = 6
	choice.content_margin_bottom = 6
	var choice_hover := tex_style("ui/plaque.png", 12)
	choice_hover.content_margin_left = 16
	choice_hover.content_margin_right = 16
	choice_hover.content_margin_top = 6
	choice_hover.content_margin_bottom = 6
	th.set_type_variation("ChoiceButton", "Button")
	th.set_stylebox("normal", "ChoiceButton", choice)
	th.set_stylebox("hover", "ChoiceButton", choice_hover)
	th.set_stylebox("pressed", "ChoiceButton", choice_hover)
	th.set_stylebox("focus", "ChoiceButton", StyleBoxEmpty.new())
	th.set_color("font_color", "ChoiceButton", C_PAPER)
	th.set_color("font_hover_color", "ChoiceButton", C_GOLD_LIGHT)
	th.set_color("font_pressed_color", "ChoiceButton", C_GOLD_LIGHT)
	_theme = th
	return th


static func label(text: String, font_size: int = FS_M, color: Color = C_PAPER, shadow: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if shadow:
		l.add_theme_color_override("font_shadow_color", C_DARK)
		# 1 herní pixel stínu na každý stupeň zvětšení fontu
		@warning_ignore("integer_division")
		var off := maxi(font_size / FS_S, 1)
		l.add_theme_constant_override("shadow_offset_x", off)
		l.add_theme_constant_override("shadow_offset_y", off)
	return l


static func panel(file: String, margin: int = 12, content: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", tex_style(file, margin, content))
	return p


static func icon(file: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(file)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


static func button(text: String, min_size: Vector2 = Vector2(0, 56)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_mouse(child)


# Karta efektu (debuff nebo buff) ve stejném stylu jako hrací karty: 160x104.
static func effect_card(icon_name: String, title: String, short: String, is_buff: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 104)
	var sb := tex_style("ui/card_player.png", 12, 8)
	card.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	card.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)
	var pic := TextureRect.new()
	pic.texture = tex("icons/card_%s.png" % icon_name)
	pic.custom_minimum_size = Vector2(32, 32)
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(pic)
	var name_label := label(title, FS_M, C_INK)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(160 - 16 - 32 - 6 - 4, 0)
	name_label.max_lines_visible = 2
	top.add_child(name_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)
	vb.add_child(label(short, FS_M, C_GREEN_DARK if is_buff else C_RED_DARK))
	ignore_mouse(card)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


# Klikatelný obrázek ve světě (bar, úřad): pod myší se rozsvítí.
static func hotspot(normal: String, hover: String, disabled: String = "") -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex(normal)
	b.texture_hover = tex(hover)
	b.texture_pressed = tex(hover)
	if disabled != "":
		b.texture_disabled = tex(disabled)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


# Otřes: uzel poskočí o pár pixelů a vrátí se na své místo.
static func shake(node: Control, strength: float) -> void:
	# Výchozí pozice se pamatuje z prvního otřesu, aby se rozběhnutý otřes nesčítal s novým.
	var home: Vector2 = node.get_meta("shake_home", node.position)
	node.set_meta("shake_home", home)
	if node.has_meta("shake_tween"):
		var old: Tween = node.get_meta("shake_tween")
		if old.is_valid():
			old.kill()
	var tw := node.create_tween()
	for i in 6:
		var amount := strength * (1.0 - i / 6.0)
		var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * amount
		tw.tween_property(node, "position", home + off.round(), 0.04)
	tw.tween_property(node, "position", home, 0.04)
	node.set_meta("shake_tween", tw)


# Velké razítko přes celou obrazovku s tlačítkem pod ním. Vrací overlay.
static func stamp_overlay(parent: Control, title: String, subtitle: String, color: Color, button_text: String, on_press: Callable) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 45
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	var view := parent.size

	var dim := ColorRect.new()
	dim.color = Color(C_DARK, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	overlay.create_tween().tween_property(dim, "color:a", 0.65, 0.3)

	var stamp := PanelContainer.new()
	var sb := tex_style("ui/stamp_frame.png", 12, 24)
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	stamp.add_theme_stylebox_override("panel", sb)
	stamp.self_modulate = color
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb := VBoxContainer.new()
	stamp.add_child(vb)
	var big := label(title, FS_XL * 2, color)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(big)
	var small := label(subtitle, FS_M, color)
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(small)
	overlay.add_child(stamp)
	stamp.reset_size()
	stamp.pivot_offset = stamp.size / 2.0
	stamp.position = (view - stamp.size) / 2.0 - Vector2(0, 40)
	stamp.rotation = -0.12
	stamp.scale = Vector2(3, 3)
	stamp.modulate.a = 0.0
	var tw := overlay.create_tween().set_parallel(true)
	tw.tween_property(stamp, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(stamp, "modulate:a", 1.0, 0.1)
	tw.chain().tween_callback(shake.bind(parent, 10.0))

	var btn := button(button_text, Vector2(320, 64))
	btn.pressed.connect(on_press)
	overlay.add_child(btn)
	btn.reset_size()
	btn.position = Vector2((view.x - btn.size.x) / 2.0, stamp.position.y + stamp.size.y + 60)
	btn.modulate.a = 0.0
	overlay.create_tween().tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(0.6)
	return overlay


# Plovoucí text (např. "+20"), vyskočí a zmizí.
static func float_text(parent: Control, at: Vector2, text: String, color: Color) -> void:
	var l := label(text, FS_L, color, true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 40
	parent.add_child(l)
	l.global_position = at - Vector2(text.length() * 9, 20)
	l.pivot_offset = Vector2(text.length() * 9, 18)
	l.scale = Vector2(0.5, 0.5)
	var start_y := l.global_position.y
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", start_y - 44.0, 0.9).set_delay(0.12)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)
