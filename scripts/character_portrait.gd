class_name CharacterPortrait
extends Control
# Animovaný portrét postavy ze sheetu tools/gen_characters.py.
# Sheet má 8 snímků 40x40 (ve hře 80x80): idle_0, idle_1, blink_0, blink_1,
# talk_0, talk_1, hurt_0, hurt_1. Číslo je fáze dechu.
#
#   var p := CharacterPortrait.new()
#   p.setup("portraits/official.png", 80)   # cesta ke statickému portrétu
#   p.set_talking(true)                       # pusa se hýbe
#   p.hurt()                                  # záškub, zčervenání

const FRAME := 80  # velikost snímku v textuře (40 herních pixelů × 2)
const STATE_COL := {"idle": 0, "blink": 2, "talk": 4, "hurt": 6}
const BREATH_TIME := 0.9
const TALK_TIME := 0.12
const BLINK_TIME := 0.12
const HURT_TIME := 0.5
const SMOKE_TIME := 0.2

var _pic: TextureRect
var _atlas: AtlasTexture
var _smoke: TextureRect
var _smoke_atlas: AtlasTexture
var _breath := 0
var _breath_t := 0.0
var _talking := false
var _mouth_open := false
var _talk_t := 0.0
var _blink_left := 0.0
var _next_blink := 2.0
var _hurt_left := 0.0
var _smoke_t := 0.0
var _smoke_frame := 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_SCALE
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pic)
	_atlas = AtlasTexture.new()
	_pic.texture = _atlas


# portrait = "portraits/<jméno>.png"; sheet a kouř se dohledají podle jména.
func setup(portrait: String, display: int = 80) -> void:
	var base := portrait.trim_suffix(".png")
	var sheet_path := UiKit.ASSETS + base + "_sheet.png"
	if ResourceLoader.exists(sheet_path):
		_atlas.atlas = load(sheet_path)
	else:
		_atlas.atlas = UiKit.tex(portrait)
	custom_minimum_size = Vector2(display, display)
	_pic.size = Vector2(display, display)
	_pic.position = Vector2.ZERO
	var smoke_path := UiKit.ASSETS + base + "_smoke.png"
	if _smoke:
		_smoke.queue_free()
		_smoke = null
	if ResourceLoader.exists(smoke_path):
		_smoke_atlas = AtlasTexture.new()
		_smoke_atlas.atlas = load(smoke_path)
		_smoke = TextureRect.new()
		_smoke.texture = _smoke_atlas
		_smoke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_smoke.stretch_mode = TextureRect.STRETCH_SCALE
		_smoke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_smoke.size = Vector2(display, display)
		add_child(_smoke)
	_next_blink = randf_range(1.5, 4.0)
	_breath_t = randf() * BREATH_TIME  # ať nedýchají všichni naráz
	_update()


func set_talking(on: bool) -> void:
	_talking = on
	if not on:
		_mouth_open = false
	_update()


func hurt() -> void:
	_hurt_left = HURT_TIME
	_pic.modulate = Color(1.0, 0.45, 0.45)
	create_tween().tween_property(_pic, "modulate", Color.WHITE, HURT_TIME)
	var tw := create_tween()
	for off in [Vector2(-4, 0), Vector2(4, 2), Vector2(-2, -2), Vector2(2, 0), Vector2.ZERO]:
		tw.tween_property(_pic, "position", off, 0.05)
	_update()


func _process(delta: float) -> void:
	_breath_t += delta
	if _breath_t >= BREATH_TIME:
		_breath_t -= BREATH_TIME
		_breath = 1 - _breath
	if _talking:
		_talk_t += delta
		if _talk_t >= TALK_TIME:
			_talk_t = 0.0
			_mouth_open = not _mouth_open
	if _blink_left > 0.0:
		_blink_left -= delta
	else:
		_next_blink -= delta
		if _next_blink <= 0.0:
			_blink_left = BLINK_TIME
			_next_blink = randf_range(2.0, 5.0)
	if _hurt_left > 0.0:
		_hurt_left -= delta
	if _smoke:
		_smoke_t += delta
		if _smoke_t >= SMOKE_TIME:
			_smoke_t = 0.0
			_smoke_frame = (_smoke_frame + 1) % 4
	_update()


func _update() -> void:
	if _atlas.atlas == null:
		return
	var state := "idle"
	if _hurt_left > 0.0:
		state = "hurt"
	elif _talking and _mouth_open:
		state = "talk"
	elif _blink_left > 0.0:
		state = "blink"
	var col: int = STATE_COL[state] + _breath
	if _atlas.atlas.get_width() < FRAME * 8:
		col = 0  # statický obrázek bez sheetu
	_atlas.region = Rect2(col * FRAME, 0, FRAME, FRAME)
	if _smoke:
		_smoke_atlas.region = Rect2(_smoke_frame * FRAME, 0, FRAME, FRAME)
