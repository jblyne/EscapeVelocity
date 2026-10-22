extends SceneTree
const Awards=preload("res://scripts/achievements.gd")
var failures=0
func check(ok: bool,message: String):
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev214-alien-award.json";game.controls.path="/tmp/ev214-alien-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.pilot=game.Pilot.new()
 var guidance=game.achievements.guidance("alien_threat")
 check(guidance.text.contains("CONFEDERATION") and guidance.text.contains("REBELLION") and not guidance.destinations.is_empty(),"Undecided pilot gets both entry paths and navigation")
 for rebel in [true,false]:
  game.pilot=game.Pilot.new()
  var route: Array=Awards.ALIEN_REBEL if rebel else Awards.ALIEN_CONFED
  game.pilot.campaign.bits=[44] if rebel else [43]
  for index in route.size()-1:
   game.pilot.campaign.completed.append(route[index])
   game.achievements.update(false)
   var badge: Dictionary=game.achievements.badges().filter(func(b):return b.id=="alien_threat")[0]
   check(not badge.earned and is_equal_approx(badge.fraction,float(index+1)/route.size()),"Alien progress uses only milestones on a single faction route")
  var finale: int=int(route.back())
  game.pilot.campaign.bits.append(int(game.catalog.field("missions",finale,"AvailBitSet")))
  var mission: Dictionary=game.missions.offer(finale,int(game.catalog.field("missions",finale,"AvailStel")))
  game.pilot.campaign.active.append(mission)
  check(game.achievements.next_steps("alien_threat").contains("Continue accepted mission: Destroy Alien Cruiser"),"Active alien finale appears in next-step guidance")
  game.pilot.campaign.active.clear();game.pilot.campaign.completed.append(finale)
  check(game.achievements.update(false) and game.pilot.achievements.earned.has("alien_threat"),"Either completed alien chain earns badge retrospectively")
  check(not game.achievements.update(false),"Alien badge awards once")
  var saved: Dictionary=game.pilot.snapshot();var copy=game.Pilot.new()
  check(copy.restore(saved,game.catalog) and copy.achievements.earned.has("alien_threat"),"Alien achievement survives save restoration")
 game.pilot=game.Pilot.new();game.pilot.system_id=170;game.pilot.campaign.bits=[44,57]
 game.pilot.campaign.completed=[184,185];game.load_system();game.docked_id=210
 game.set_mode("dock");game.hud.port_page="bar";game.missions.begin_bar_approach()
 check(not 186 in game.missions.bar_queue,"Sirgil Starport does not offer Sirgil III's spy mission")
 var exact: String=game.achievements.next_steps("alien_threat")
 check(exact.contains("This offer does not appear at Sirgil Starport") and exact.contains("F1"),"Guidance distinguishes the exact planet from its neighboring starport")
 game.docked_id=209;game.missions.begin_bar_approach()
 check(186 in game.missions.bar_queue,"Sirgil III queues Rescue Rebel Spy for the eligible pilot")
 for frame in 100:
  game.missions.advance_bar(.1)
  if game.mode=="mission_offer": break
 check(game.mode=="mission_offer" and int(game.missions.approach.id)==186,"Correct planet presents the spy mission offer")
 game.free();await process_frame
 print("ALIEN ACHIEVEMENT: %d failures" % failures);quit(1 if failures else 0)
