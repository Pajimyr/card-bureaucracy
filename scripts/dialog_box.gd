class_name DialogBox
extends Control
# Dialog přes celou obrazovku: portrét, jméno, text psaný po písmenech, volby.
#
#   var choice: String = await dialog.run([
#       {"who": "Šarlatán", "portrait": "portraits/charlatan.png", "text": "Psst."},
#       {"who": "Šarlatán", "portrait": "...", "text": "Bereš?",
#        "choices": [{"id": "yes", "text": "Beru."}, {"id": "no", "text": "Ne."}]},
#   ])
#
# run() vrací id poslední zvolené volby (nebo ""). Větvení řeší volající dalším run().
# Klik nebo Enter/mezerník: dopíše rozepsaný text, jinak pokračuje.

signal _advanced
signal _chosen(id: String)

const CHARS_PER_SEC := 55.0

var _name: Label
var _text: Label
var _pic: CharacterPortrait
var _choices: VBoxContainer
var _hint: Label
var _typing: Tween
var _has_choices := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 35
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(UiKit.C_DARK, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var box := UiKit.panel("ui/panel_frame.png", 12, 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 24
	box.offset_right = -24
	box.offset_bottom = -24
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)

	var frame := UiKit.panel("ui/plaque.png", 8, 4)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(frame)
	_pic = CharacterPortrait.new()
	frame.add_child(_pic)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)
	_name = UiKit.label("", UiKit.FS_M, UiKit.C_GOLD_LIGHT, true)
	col.add_child(_name)
	_text = UiKit.label("", UiKit.FS_M, UiKit.C_PAPER)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(700, 72)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 6)
	col.add_child(_choices)
	_hint = UiKit.label("klikni ›", UiKit.FS_S, UiKit.C_GREY)
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(_hint)
	UiKit.ignore_mouse(box)


func run(lines: Array) -> String:
	visible = true
	var last := ""
	for line in lines:
		_show_line(line)
		if _has_choices:
			last = await _chosen
		else:
			await _advanced
	visible = false
	return last


func _show_line(line: Dictionary) -> void:
	_name.text = str(line.get("who", ""))
	_name.add_theme_color_override("font_color", line.get("color", UiKit.C_GOLD_LIGHT))
	var portrait := str(line.get("portrait", ""))
	if portrait != "":
		_pic.setup(portrait, 160)
	_pic.get_parent().visible = portrait != ""
	_text.text = str(line.get("text", ""))
	_text.visible_ratio = 0.0
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	var choices: Array = line.get("choices", [])
	_has_choices = not choices.is_empty()
	for ch in choices:
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.text = "› " + str(ch["text"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.pressed.connect(_on_choice.bind(str(ch["id"])))
		_choices.add_child(b)
	_choices.visible = false
	_hint.visible = false
	if _typing and _typing.is_valid():
		_typing.kill()
	_typing = create_tween()
	var dur := maxf(_text.text.length() / CHARS_PER_SEC, 0.05)
	_typing.tween_property(_text, "visible_ratio", 1.0, dur)
	_typing.tween_callback(_finish_typing)
	_pic.set_talking(true)  # pusa se hýbe, dokud se píše text


func _finish_typing() -> void:
	if _typing and _typing.is_valid():
		_typing.kill()
	_text.visible_ratio = 1.0
	_pic.set_talking(false)
	_choices.visible = _has_choices
	_hint.visible = not _has_choices


func _is_typing() -> bool:
	return _text.visible_ratio < 1.0


func _proceed() -> void:
	if _is_typing():
		_finish_typing()
	elif not _has_choices:
		_advanced.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_proceed()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_proceed()
		get_viewport().set_input_as_handled()


func _on_choice(id: String) -> void:
	_chosen.emit(id)
