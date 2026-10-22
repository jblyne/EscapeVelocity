extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev180-reconstruction.json";game.controls.path="/tmp/ev180-reconstruction-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false);game.pilot=game.Pilot.new()
 game.pilot.campaign.day=100;game.pilot.system_id=129;game.pilot.cheat_world_killer=true
 game.pilot.achievements.earned.world_killer=100
 game.pilot.world_killer.destroyed=[128,129];game.pilot.world_killer.destroyed_at={"128":100,"129":100}
 game.load_system();game.set_mode("flight")
 for id in [128,129]:
  check(game.world_killer.destroyed(id) and not game.planets.any(func(p):return int(p.id)==id),"Day zero excludes shattered world %d from docking and gravity" % id)
  check(not game.world_activity.landing_reason(id).is_empty(),"Day zero refuses landing at %d" % id)
 for days in [1,19,20,21,39,40,41,59,60,61,79,80,81,200]:
  game.pilot.campaign.day=100+days;game.load_system();game.set_mode("flight")
  for id in [128,129]:
   var expected: int=mini(4,1+int((days-1)/20))
   var status: Dictionary=game.world_killer.reconstruction(id)
   check(status.stage==expected and status.complete==(days>=80) and is_equal_approx(status.progress,minf(1,float(days)/80)),"Correct 20-day milestones and continuous growth at day %d for %d" % [days,id])
   check(not game.world_killer.destroyed(id) and game.world_activity.landing_reason(id).is_empty(),"Every nonzero stage provides temporary landing despite hostile record")
   var bodies: Array=game.planets.filter(func(p):return int(p.id)==id)
   check(bodies.size()==1 and bodies[0].node.has_meta("rebuild_id"),"One steel world replaces debris on return/reload")
   game.landing_target=id;game.landing_clearance=id;game.pilot.position=bodies[0].position;game.velocity=Vector2.ZERO;game.land()
   check(game.mode=="dock" and game.docked_id==id,"Actual landing works at stage %d, world %d" % [expected,id])
   check(game.hud.modal_root.find_child("PortDescription",true,false).text.contains("reconstruction") or game.hud.modal_root.find_child("PortDescription",true,false).text.contains("Steel skeleton") or game.hud.modal_root.find_child("PortDescription",true,false).text.contains("assembly") or game.hud.modal_root.find_child("PortDescription",true,false).text.contains("fitting") or game.hud.modal_root.find_child("PortDescription",true,false).text.contains("Final steel"),"Landing describes current work")
   if "--visual" in OS.get_cmdline_user_args() and days in [20,40,60,80] and id==128:
    await create_timer(.3).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("/tmp/ev180-landing-%d.png" % days)
   game.set_mode("flight")
 var saved: Dictionary=JSON.parse_string(JSON.stringify(game.pilot.snapshot()));var restored=game.Pilot.new()
 check(restored.restore(saved,game.catalog) and restored.world_killer.destroyed_at==game.pilot.world_killer.destroyed_at,"Reconstruction dates survive validated JSON save")
 var old: Dictionary=saved.duplicate(true);old.world_killer.erase("destroyed_at")
 check(restored.restore(old,game.catalog) and int(restored.world_killer.destroyed_at["128"])==int(restored.campaign.day),"Legacy ruins start their clock on migration, never instantly complete")
 var bad: Dictionary=saved.duplicate(true);bad.world_killer.destroyed_at["128"]=game.pilot.campaign.day+1
 check(not restored.restore(bad,game.catalog),"Future destruction dates rejected")
 bad=saved.duplicate(true);bad.world_killer.destroyed_at["999"]=1
 check(not restored.restore(bad,game.catalog),"Dates for unknown or never-destroyed bodies rejected")
 # Every catalog identity has a distinct complete mesh and artwork pair at each milestone.
 var art_count: int=0
 for record in ([] if "--skip-art" in OS.get_cmdline_user_args() else game.catalog.data.objects.values()):
  for phase in range(1,5):
   for kind in ["landing","orbital"]:
    var path: String="res://assets/reconstruction/%s/%d_%d.webp" % [kind,int(record.id),phase]
    check(ResourceLoader.exists(path),"Stage artwork exists: "+path);art_count+=1
 for id in [128,129]:
  var early=game.world_killer.Rebuilt.create(game.world,Vector3.ZERO,10,id,id==129,.5)
  var late=game.world_killer.Rebuilt.create(game.world,Vector3.ZERO,10,id,id==129,1)
  check(int(early.get_meta("soil_tiles"))==0 and int(early.get_meta("water_tiles"))==0,"Early reconstruction stays a steel structure")
  check((int(late.get_meta("soil_tiles"))>0 and int(late.get_meta("water_tiles"))>0) if id==128 else (int(late.get_meta("soil_tiles"))==0 and int(late.get_meta("water_tiles"))==0),"Late planets reclaim soil/water while stations retain steel construction")
  early.free();late.free()
 var day_before: int=int(game.pilot.campaign.day)
 game.missions.jumped()
 check(int(game.pilot.campaign.day)>day_before,"Normal hyperspace advances the existing game-day calendar")
 check(int(game.world_killer.reconstruction(128).days)==int(game.pilot.campaign.day)-100,"Reconstruction follows actual game days, including travel elsewhere")
 check(art_count==856 or "--skip-art" in OS.get_cmdline_user_args(),"All 107 worlds have four landing pictures and four orbital pictures")
 game.pilot.campaign.day=340;game.pilot.world_killer.destroyed_at={"128":300,"129":300};game.load_system();game.set_mode("map");game.map_selected=129
 var map=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1);map.refresh_details()
 var readout=map.readouts[str(Vector2(656,130))]
 check(readout.ports==[128,129] and readout.tooltip_text.contains("day 40"),"Map exposes reconstruction stage and unique orbital previews")
 game.set_mode("flight");game.landing_target=128
 check(game.world_killer.reason(128).is_empty(),"Rebuilt steel planet can be threatened again")
 game.world_activity.contact_id=128;game.set_mode("world_comms");game.world_killer.threaten();check(game.world_killer.deploy(),"Rebuilt world can receive a new valid deployment")
 check(game.Pilot.new().restore(JSON.parse_string(JSON.stringify(game.pilot.snapshot())),game.catalog),"Active attack on a rebuilt world passes save validation")
 game.world_killer.detonate()
 check(game.world_killer.destroyed(128) and game.pilot.world_killer.destroyed.count(128)==1 and int(game.pilot.world_killer.destroyed_at["128"])==340,"Reshattering restarts the clock without duplicating destruction history")
 check(game.Pilot.new().restore(JSON.parse_string(JSON.stringify(game.pilot.snapshot())),game.catalog),"Reshattered pilot remains save-valid")
 game.free();await process_frame
 print("RECONSTRUCTION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
