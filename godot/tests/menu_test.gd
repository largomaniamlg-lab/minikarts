extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var menu=game.race_menu
	var network=root.get_node("Network")
	for mode in ["single","tournament"]:
		for friends in [false,true]:
			menu.open(); network.selected_mode=mode; menu.with_friends=friends; menu.set_step(0)
			check(menu.mode_buttons[1].button_pressed==(mode=="tournament") and menu.rival_buttons[1].button_pressed==friends,"Both independent choices match selection")
			check(not menu.cards[0].visible and menu.forward_button.visible,"Only mode choices at step one")
			menu.forward_button.pressed.emit()
			check(menu.step==1 and menu.circuit_choice.disabled==(mode=="tournament"),"Tournament fixes qualifying circuit")
			check(menu.bot_choice.visible==not friends and menu.lap_choice.visible,"Opponent-specific settings")
			menu.forward_button.pressed.emit()
			check(menu.summary.visible and menu.race_button.visible==not friends and menu.online.visible==friends,"Four combinations route to appropriate start")
			menu.back_button.pressed.emit()
			check(menu.step==1 and network.selected_mode==mode and menu.with_friends==friends,"Back preserves choices")
	for driver in range(16):
		menu.select(driver); menu.page=driver/4; menu.set_step(1)
		check(menu.cards[driver].visible and menu.garage.texture==network.Catalog.PORTRAITS[driver],"Full-body garage and page follow selected pilot")
		var portrait=menu.cards[driver].get_child(0)
		check(portrait.size.x<=menu.cards[driver].size.x and portrait.size.y<=menu.cards[driver].size.y,"Portrait stays inside card")
	network.selected_laps=9; network.selected_bots=15
	menu.open();menu.set_step(1)
	check(menu.lap_choice.get_selected_id()==9 and menu.bot_choice.get_selected_id()==15,"Reopening restores race settings")
	network.selected_mode="single"
	game.start_offline()
	menu.show_results([])
	check(menu.back_button.visible,"Results offer return to setup")
	menu.back_button.pressed.emit()
	check(menu.step==0 and not menu.result_text.visible,"Return from results restores mode choices")
	print("Menu wizard: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
