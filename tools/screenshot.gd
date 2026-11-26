extends SceneTree
# Spustí scénu v SubViewportu 1280x720, chvíli počká a uloží snímek.
#   godot --path . -s tools/screenshot.gd -- out=/tmp/shot.png [scene=main] [frames=60]
#       [setup=poor|hands|rich] [action=...] [after=40]
# scene: main, menu, city, bar, ending (scenes/<name>.tscn)
# setup: stav GameState před načtením scény
#   poor  = prohra, 0 grošů        hands = prohra, 5 grošů, obě ruce pryč
#   rich  = výhra, 70 grošů, jedna ruka pryč a jedna protéza
#   boss  = poslední patro (ředitel), úplatek, kafe, razítko, vesta
#   won   = kariéra dokončená (pro scénu ending)
#   shop  = patro 3, 60 grošů, ruka, žebro, vesta a dvě razítka (pro bar + action=honza)
# action (po frames snímcích):
#   main: end_win, end_lose, enemy, select, roulette_offer, roulette, roulette_spin, rib
#   ending: results
#   menu: difficulty, intro       bar: honza (projde dialog až do obchodu)
#   city: hover_bar

var vp: SubViewport


func _initialize() -> void:
	var opts := {"out": "/tmp/shot.png", "scene": "main", "frames": "60", "setup": "", "action": "", "after": "40"}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var gs: Node = root.get_node("GameState")
	match opts["setup"]:
		"poor":
			gs.new_game(1)
			gs.grose = 0
			gs.last_result = "lose"
		"hands":
			gs.new_game(1)
			gs.grose = 5
			gs.last_result = "lose"
			gs.effects = [{"id": "no_hand", "side": "left"}, {"id": "no_hand", "side": "right"}]
		"rich":
			gs.new_game(2)
			gs.grose = 70
			gs.last_result = "win"
			gs.case_number = 3
			gs.knows_password = true
			gs.effects = [{"id": "no_hand", "side": "left"}, {"id": "prosthesis", "side": "right"}, {"id": "broken_rib"}, {"id": "broken_rib"}]
			gs.tutorial_done = true
		"boss":
			gs.new_game(1)
			gs.tutorial_done = true
			gs.rank = 3
			gs.case_number = 5
			gs.grose = 40
			gs.effects = [{"id": "bribe"}, {"id": "coffee"}, {"id": "fake_stamp"}, {"id": "vest"}]
		"won":
			gs.new_game(1)
			gs.tutorial_done = true
			gs.rank = gs.RANKS.size()
			gs.case_number = 6
			gs.cases_won = 4
			gs.cases_lost = 1
			gs.grose = 85
			gs.effects = [{"id": "prosthesis", "side": "left"}, {"id": "broken_rib"}]
		"shop":
			gs.new_game(1)
			gs.tutorial_done = true
			gs.rank = 2
			gs.grose = 60
			gs.last_result = "win"
			gs.effects = [{"id": "no_hand", "side": "left"}, {"id": "broken_rib"}, {"id": "vest"}, {"id": "fake_stamp"}, {"id": "fake_stamp"}]
	gs.knows_password = true

	vp = SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# SubViewport má vlastní filtr (výchozí lineární), nastavení projektu platí jen pro okno.
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(vp)
	var scene: PackedScene = load("res://scenes/%s.tscn" % opts["scene"])
	var node := scene.instantiate()
	vp.add_child(node)
	await _frames(int(opts["frames"]))

	match opts["action"]:
		"end_win":
			node._end_stamp(true)
		"end_lose":
			node._end_stamp(false)
		"enemy":
			node._on_confirm_turn()
		"select":
			node.selected_uid = node.hand[0]["uid"]
			node._refresh()
		"roulette_offer":
			node.hand.clear()
			node._refresh()
			node._offer_roulette()
		"roulette", "roulette_spin":
			Roulette.spin(node)
			if opts["action"] == "roulette_spin":
				await _frames(5)
				for c in node.get_children():
					if c is Roulette:
						c._on_spin()
		"roulette_flow", "skip_flow":
			# Prázdná ruka → dialog → volba → (ruleta → POKRAČOVAT). Vypíše výsledek.
			node.hand.clear()
			node._refresh()
			node._offer_roulette()
			await _frames(90)
			node.tut_dialog._on_choice("spin" if opts["action"] == "roulette_flow" else "skip")
			await _frames(10)
			for c in node.get_children():
				if c is Roulette:
					c._on_spin()
					await _frames(600)
					c._btn.pressed.emit()
			await _frames(60)
			print("FLOW hand=%d phase=%s hp=%d/%d cpt=%d effects=%s" % [node.hand.size(), node.phase, node.player_hp, node.player_max_hp, node.cards_per_turn, gs.effects])
		"rib":
			node._apply_roulette({"kind": "rib"})
			node._apply_roulette({"kind": "cards", "n": 3})
		"difficulty":
			node._show_difficulty()
		"intro":
			node._start_game(1)
		"results":  # ending: přeskočí dialog a ukáže statistiky (razítko odklikne)
			node.dialog.visible = false
			node._show_results()
			await _frames(30)
			for c in node.get_children():
				if c.z_index == 45:
					c.queue_free()
		"hover_bar":
			node._set_caption("BAR U ZLATÉ KRYSY · černý trh. Heslo znáš.", UiKit.C_PINK)
		"tutorial_play":
			# Projde tutorial: dialogy odklikává, karty klade do volných slotů, potvrzuje tahy.
			for turn_i in 12:
				for i in 12:
					if node.tut_dialog.visible:
						node.tut_dialog._proceed()
					await _frames(12)
				if node.phase == node.Phase.OVER:
					break
				if node.phase != node.Phase.PLAYER:
					continue
				var idx := 0
				for c in node.hand.duplicate():
					if node.placed_this_turn >= node.cards_per_turn:
						break
					while idx < 6 and (node.player_board[idx] != null or (idx >= 3 and node.player_board[idx - 3] == null)):
						idx += 1
					if idx >= 6:
						break
					node._commit_drop_direct(c, idx)
				await _frames(40)
				node._on_confirm_turn()
			for i in 40:
				if node.tut_dialog.visible:
					node.tut_dialog._proceed()
				await _frames(20)
			print("TUT result: phase=%s official=%d player=%d done=%s" % [node.phase, node.official_hp, node.player_hp, root.get_node("GameState").tutorial_done])
		"honza":
			# proklikat barmana: pozdrav, volba hesla, odpověď
			for i in 6:
				node.dialog._proceed()
				await _frames(5)
				if node.dialog._has_choices and not node.dialog._is_typing():
					node.dialog._on_choice("honza")
					await _frames(5)
			for i in 4:
				node.dialog._proceed()
				await _frames(5)
	if opts["action"] != "":
		await _frames(int(opts["after"]))
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(opts["out"])
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame
