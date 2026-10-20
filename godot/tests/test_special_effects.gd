extends SceneTree
var game
var failures=0
var count=0
var visible_brightness=0.0
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	count+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func capture(name: String):
	game.hud._process(0)
	for i in 90: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/special-"+name+".png"))
func ship_brightness() -> float:
	var im=root.get_texture().get_image()
	var center=Vector2i(game.camera.unproject_position(game.player_model.global_position))
	var total=0.0
	for y in range(center.y-100,center.y+100):
		for x in range(center.x-45,center.x+45):
			var c=im.get_pixel(x,y);total+=c.r+c.g+c.b
	return total
func run():
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-special-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false
	root.add_child(game)
	game.set_physics_process(false);game.set_process(false)
	game.set_mode("flight")
	game.pilot.cheat_all_weapons=true;game.select_weapon(191);game.cooldown=0
	check(game.fire_player(),"forklift fires from the real player input path")
	var shot=game.shots.back()
	check(shot.node.name=="Forklift" and shot.node.find_children("ForkTine*","MeshInstance3D",true,false).size()==2,"forklift has two distinct forward tines")
	check(shot.node.find_children("*","MeshInstance3D",true,false).size()>20,"forklift is a complete model, not a projectile box")
	var forklift_audio=game.audio[game.arsenal.weapon_sound_key(191)]
	check(forklift_audio.playing and not game.audio.laser.playing,"forklift plays original engine sample instead of laser")
	check(is_equal_approx(game.audio.forklift.stream.get_length(),35282.0/11127.0),"forklift sample has original PCM duration")
	check(is_equal_approx(game.audio.cloak_on.stream.get_length(),13918.0/11127.0),"cloak sample has original PCM duration")
	game.set_mode("pause");check(forklift_audio.stream_paused,"pause freezes forklift audio")
	game.set_mode("flight")
	if "--visual" in OS.get_cmdline_user_args():
		game.camera.position=game.v3(shot.position,1200);game.camera.size=100;game.camera.h_offset=15
		await capture("forklift")
	game.pilot.cheat_cloak=false;game.pilot.outfits.erase("167")
	check(not game.cloak.toggle() and game.messages[0].begins_with("No cloaking"),"missing cloak gives an actionable message")
	game.set_mode("cheats")
	var toggle=game.hud.modal_root.find_child("CloakingDeviceToggle",true,false)
	check(toggle!=null,"cheat menu exposes a dedicated cloaking toggle")
	toggle.button_pressed=true
	check(game.pilot.cheat_cloak and game.cloak.available(),"cheat UI makes device available without changing mission equipment")
	var saved=game.pilot.snapshot()
	var restored=game.Pilot.new()
	check(restored.restore(saved,game.catalog) and restored.cheat_cloak,"cloak cheat survives save/load")
	saved.cheats.cloak="bad"
	check(not restored.restore(saved,game.catalog),"cloak save field rejects invalid types")
	game.set_mode("flight")
	game.camera.position=game.v3(game.pilot.position,1200);game.camera.size=150;game.camera.h_offset=22.5
	if "--visual" in OS.get_cmdline_user_args():
		await capture("visible")
		visible_brightness=ship_brightness()
	check(game.cloak.toggle() and game.audio.cloak_on.playing,"K-equivalent activation plays original cloak-on recording")
	check(not game.cloak.materials.is_empty(),"cloak uses renderer-supported instance materials")
	var item=game.cloak.materials[0]
	game.cloak.update_visual(.625)
	check(is_equal_approx(game.cloak.amount,.5),"cloak fades over time rather than popping")
	if "--visual" in OS.get_cmdline_user_args(): await capture("fading")
	game.cloak.update_visual(.625)
	check(item.copy.albedo_color.a<.2 and item.copy.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"fully cloaked ship uses translucent silhouette")
	if "--visual" in OS.get_cmdline_user_args():
		await capture("cloaked")
		check(ship_brightness()<visible_brightness*.55,"rendered cloak is visibly dimmer than the normal ship")
	var shield=game.pilot.shield;var fuel=game.pilot.fuel
	game.cloak.advance(1)
	check(game.pilot.shield==shield-8 and game.pilot.fuel==fuel-2,"cloak consumes shield power and fuel")
	game.cooldown=0
	check(game.fire_player() and game.cloak.active,"firing preserves active cloak")
	check(not game.fire_player() and game.cloak.active,"cloaked weapons retain reload timing")
	var npc=game.traffic.spawn(134,128,4,game.pilot.position+Vector2(100,0));npc.hostile=true
	check(not game.traffic.opponent(npc).get("player",false),"hostile targeting loses cloaked player")
	game.audio.cloak_on.play();game.set_mode("pause");var amount=game.cloak.amount;game._process(.2)
	check(game.cloak.amount==amount and game.audio.cloak_on.stream_paused,"pause freezes cloak visuals and sound")
	game.set_mode("flight")
	check(game.cloak.toggle() and game.audio.cloak_off.playing and not game.audio.cloak_on.playing,"decloak plays original off sound without overlapping on sound")
	game.cloak.update_visual(1.25)
	check(game.cloak.amount==0 and game.cloak.materials.is_empty(),"decloak restores original materials")
	if "--visual" in OS.get_cmdline_user_args():
		await capture("restored")
		check(ship_brightness()>visible_brightness*.9,"rendered decloak restores ship brightness")
	game.pilot.cheat_infinite_fuel=true;game.pilot.fuel=0;game.pilot.shield=100
	check(game.cloak.toggle(),"infinite fuel allows cloak with empty tank")
	game.cloak.advance(1);check(game.cloak.active,"empty tank does not cancel infinite-fuel cloak")
	game.pilot.cheat_infinite_fuel=false;game.pilot.fuel=.1
	game.cloak.advance(1)
	check(not game.cloak.active and "fuel depleted" in game.messages[0],"fuel exhaustion reports its exact cause")
	game.pilot.cheat_infinite_fuel=true
	game.cloak.toggle()
	game.pilot.shield=.1;game.cloak.advance(1)
	check("shield power depleted" in game.messages[0],"shield exhaustion reports its exact cause")
	check(not game.cloak.active and game.audio.cloak_off.playing,"power depletion uncloaks with off sound")
	game.cloak.update_visual(1.25)
	game.pilot.shield=100;game.muted=true
	game.audio.cloak_on.stop();game.cloak.toggle()
	check(not game.audio.cloak_on.playing,"mute suppresses original cloak recording")
	game.load_system()
	check(not game.cloak.active and game.cloak.amount==0 and game.cloak.materials.is_empty(),"system load clears cloak materials and state")
	game.free();await process_frame
	print("SPECIAL EFFECTS RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
