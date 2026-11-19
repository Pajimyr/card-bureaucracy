extends SceneTree
# Spustí hlavní scénu v SubViewportu 1280x720, chvíli počká a uloží snímek.
# godot --path . -s tools/screenshot.gd -- /tmp/shot.png [frames] [akce]
# akce: "end_win" / "end_lose" razítko konce, "enemy" tah úředníka, "select" vybraná karta.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp/shot.png"
	var frames := int(args[1]) if args.size() > 1 else 30
	var action := args[2] if args.size() > 2 else ""
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main := scene.instantiate()
	vp.add_child(main)
	for i in frames:
		await process_frame
	match action:
		"end_win":
			main._end_stamp(true)
		"end_lose":
			main._end_stamp(false)
		"enemy":
			main._on_confirm_turn()
		"select":
			main.selected_uid = main.hand[0]["uid"]
			main._refresh()
	if action != "":
		for i in int(args[3]) if args.size() > 3 else 40:
			await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out)
	quit()
