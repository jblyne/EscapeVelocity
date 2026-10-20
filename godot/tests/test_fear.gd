extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-fear-test.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 var service=game.world_activity
 var victim: int=193
 game.pilot.local_records[str(game.missions.system_of(victim))]=-10000
 game.pilot.world_killer.destroyed=[]
 check(not service.landing_reason(victim).is_empty(),"bad legal record blocks landing without fear")
 check(service.fear(victim).score==0 and not service.fear(victim).compliant,"new pilot has no destructive reputation")
 game.pilot.world_killer.destroyed=[129]
 var station_fear: int=service.fear(victim).score
 check(station_fear>=20,"destroyed station contributes fear")
 game.pilot.world_killer.destroyed=[128]
 check(service.fear(victim).score>station_fear,"destroyed planet contributes more fear than station")
 game.pilot.world_killer.destroyed=[128,132]
 check(service.fear(victim).compliant and service.landing_reason(victim).is_empty(),"destruction history overrides hostile landing record")
 check(game.world_killer.greeting(victim).contains("spare us"),"intimidated authority acknowledges fear")
 if "--visual" in OS.get_cmdline_user_args():
  game.pilot.system_id=game.missions.system_of(victim);game.load_system();game.set_mode("flight")
  game.landing_target=victim;game.world_activity.open_contact()
  await create_timer(.5).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev-fear-hail.png")
 var copy=game.Pilot.new()
 check(copy.restore(game.pilot.snapshot(),game.catalog),"fear history saves without new save fields")
 var before=service.fear(victim)
 game.pilot=copy
 check(service.fear(victim)==before,"fear remains identical after reload")
 service.siege={"port":victim}
 check(not service.landing_reason(victim).is_empty(),"active defense battle still blocks landing")
 service.siege={}
 game.pilot.world_killer.destroyed.append(victim)
 check(not service.fear(victim).compliant and not service.landing_reason(victim).is_empty(),"fear cannot reopen destroyed facilities")
 game.pilot.world_killer.destroyed=[]
 var targets: Array=[]
 for obj in game.catalog.data.objects.values():
  if int(obj.fields.Flags)&1 and not int(obj.fields.Flags)&32: targets.append(int(obj.id))
 game.pilot.world_killer.destroyed=targets.slice(0,4)
 check(service.fear(victim).score<=100,"fear score is capped")
 game.free();await process_frame
 print("FEAR: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
