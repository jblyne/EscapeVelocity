extends SceneTree
const Awards=preload("res://scripts/achievements.gd")
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-achievements-pilot.json";game.controls.path="/tmp/ev-achievements-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.pilot=game.Pilot.new()
	check(game.achievements.badges().all(func(b):return not b.earned),"New pilots start with locked achievement badges")
	check(game.achievements.progress().overall>0 and game.achievements.progress().overall<.01,"Starting system contributes only its actual exploration fraction")
	game.pilot.credits=1000000
	check(game.achievements.update(false),"Reaching a wealth threshold earns badges")
	check(game.pilot.achievements.earned.has("credits_1m"),"Millionaire badge is recorded")
	game.pilot.credits=10000;game.achievements.update(false)
	check(game.pilot.achievements.earned.has("credits_1m") and game.pilot.achievements.peak_credits==1000000,"Spending credits never removes the badge or peak")
	check(not game.achievements.update(false),"Earned achievements never repeatedly retrigger")
	var visited: Array=game.catalog.data.systems.keys().map(func(id):return int(id))
	game.pilot.visited=visited;game.achievements.update(false)
	check(game.pilot.achievements.earned.has("explore_all"),"Full visited galaxy earns exploration medal")
	for branch in ["Confederation","Rebellion"]:
		game.pilot.campaign=game.Pilot.CampaignState.fresh()
		for track in Awards.COMMON: game.pilot.campaign.completed.append_array(track.missions)
		game.pilot.campaign.completed.append_array(Awards.CONFED if branch=="Confederation" else Awards.REBEL)
		game.pilot.campaign.completed.append_array(Awards.CARRIER if branch=="Confederation" else Awards.ASTRODYNE)
		var progress: Dictionary=game.achievements.progress()
		check(progress.branch==branch and is_equal_approx(progress.overall,1.0),"100% is reachable on "+branch+" route without the opposing faction or repeat jobs")
	game.achievements.update(false)
	check(game.pilot.achievements.earned.has("war_hero"),"Military story completion awards its badge")
	var saved: Dictionary=game.pilot.snapshot()
	var copy=game.Pilot.new()
	check(copy.restore(saved,game.catalog) and copy.achievements==game.pilot.achievements,"Badges and lifetime milestones survive save restoration")
	var legacy: Dictionary=saved.duplicate(true);legacy.erase("achievements")
	check(copy.restore(legacy,game.catalog),"Existing pilot saves without achievement data remain compatible")
	game.pilot=copy;game.achievements.update(false)
	check(game.pilot.achievements.earned.has("war_hero") and game.pilot.achievements.earned.has("explore_all"),"Existing story and exploration milestones are awarded retrospectively")
	var malformed: Dictionary=saved.duplicate(true);malformed.achievements={"earned":[],"peak_credits":-1}
	check(not copy.restore(malformed,game.catalog),"Malformed achievement data is rejected")
	check(not Awards.valid({"earned":{"bad":-1}}),"Invalid earned day is rejected")
	game.pilot=game.Pilot.new();game.pilot.mission={"system":128,"object":128,"reward":1200}
	game.pilot.deliver(128);game.achievements.update(false)
	check(game.pilot.achievements.earned.has("first_job") and game.pilot.achievements.contracts_completed==1,"Introductory courier completion counts toward contract badges")
	game.pilot.deliver(128)
	check(game.pilot.achievements.contracts_completed==1,"Delivered courier cannot award a second completion")
	game.pilot=game.Pilot.new()
	for i in 2:
		var job: Dictionary=game.missions.offer(130,128)
		game.pilot.campaign.active.append(job);game.missions.finish(job,true)
	check(game.pilot.achievements.contracts_completed==2 and game.pilot.campaign.completed.count(130)==1,"Repeated original jobs count as new contracts without duplicating story completion")
	game.set_mode("pause");game.open_achievements()
	check(game.mode=="achievements" and game.hud.modal_root.find_child("BadgeCollection",true,false)!=null,"Pause opens the classic badge collection and progress screen")
	game.hud.modal_root.find_child("AchievementsBack",true,false).pressed.emit()
	check(game.mode=="pause","Badge screen returns to its opening menu")
	game.pilot.campaign.rating=8000;game.achievements.update()
	check(is_instance_valid(game.hud.achievement_toast) and game.hud.achievement_toast.mouse_filter==Control.MOUSE_FILTER_IGNORE,"New milestones display a nonblocking badge notification")
	game.free();await process_frame
	print("ACHIEVEMENTS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
