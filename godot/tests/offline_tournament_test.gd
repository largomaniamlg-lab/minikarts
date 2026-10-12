extends SceneTree
var failures:=0
func check(ok: bool,text: String) -> void:
	if not ok: failures+=1; push_error(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var network=root.get_node("Network")
	network.selected_mode="tournament"; network.selected_bots=3
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(4): await physics_frame
	game.start_offline()
	var race=game.offline_race
	check(race.lap_target==3 and game.get_node("Track").layout_id==0,"Offline tournament starts original qualifying")
	var results:=[]
	for id in range(4): results.append({"id":id,"name":race.racers[id].name,"time":60.0+id,"best_lap":20.0-id})
	race.tournament.finish(results)
	race.continue_tournament()
	check(race.tournament.stage==1 and game.get_node("Track").layout_id==1,"Offline continuation selects race one")
	check(game.kart.spawn_transform.origin.is_equal_approx(game.get_node("Track").grid_transform(3).origin),"Offline player starts by best lap rank")
	game.race_menu.select(4)
	check(race.tournament.table[0].driver==4,"Podium follows a changed player character")
	race.tournament.finish(results)
	race.continue_tournament()
	check(race.racers[1].kart.get_node("Driver").face_id==1 and race.racers[1].name==race.tournament.table[1].name,"AI identities remain consistent between tournament races")
	var points: int=race.tournament.table[0].points
	game.race_menu.open(); game.race_menu.resume()
	check(race.tournament.table[0].points==points,"Pausing and resuming preserves championship points")
	game.reset_race()
	check(race.tournament.stage==0 and race.tournament.table[0].points==0,"Explicit restart clears the tournament")
	print("Offline tournament: 7 checks, %d failures" % failures)
	quit(0 if failures==0 else 1)
