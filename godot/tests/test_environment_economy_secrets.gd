extends SceneTree
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-environment-tests.json"
 game.controls.path="/tmp/ev-environment-controls.json";game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 var c=game.catalog
 for object in c.data.objects.values():
  var prices: Array=c.prices(int(object.id))
  for good in c.data.commodities:
   var i: int=int(good.id);var band: int=(int(object.fields.Flags)>>(28-i*4))&7 if int(object.fields.Flags)&2 else 0
   check(c.commodity_band(int(object.id),i)==band,"source market flags: %s/%d" % [object.name,i])
   var expected: int=int(good.base_price/1.25) if band==1 else int(good.base_price) if band==2 else int(good.base_price*1.25) if band==4 else -1
   check(prices[i]==expected,"original default price arithmetic: %s/%d" % [object.name,i])
 check(c.prices(128)[2]==480 and c.prices(128)[0]==150,"Earth has cheap medical supplies and expensive food")
 game.pilot.system_id=128;game.load_system();game.set_mode("flight")
 var first: Array=game.environment_hazards.rocks.map(func(r):return r.position)
 check(not first.is_empty(),"source asteroid density creates a field")
 game.load_system();check(first==game.environment_hazards.rocks.map(func(r):return r.position),"asteroid field is stable across reloads")
 game.environment_hazards.rocks=[{"position":Vector2(100,0),"radius":20}]
 var hit=game.environment_hazards.obstruction(Vector2.ZERO,Vector2(200,0))
 check(not hit.is_empty() and is_equal_approx(hit.distance,80.0),"swept ray finds first asteroid surface")
 check(game.environment_hazards.obstruction(Vector2(0,100),Vector2(200,100)).is_empty(),"clear trajectory remains unobstructed")
 game.pilot.position=Vector2.ZERO
 var npc=game.traffic.spawn(131,128,0,Vector2(150,0));var health: float=npc.health
 game.arsenal.fire(128,Vector2.ZERO,PI/2);game.update_shots(.2)
 check(npc.health==health and game.shots.is_empty(),"asteroid shields a ship from laser projectile")
 for system in c.data.systems.values():
  if int(system.fields.Interference)>30: game.pilot.system_id=int(system.id);break
 game.load_system()
 check(game.environment_hazards.interference()>0,"system interference comes from source data")
 check(game.environment_hazards.sensor_visible({"position":game.pilot.position+Vector2(100,0)}),"nearby contacts remain visible")
 check(not game.environment_hazards.sensor_visible({"position":game.pilot.position+Vector2(1900,0)}),"interference limits distant radar")
 check(game.environment_hazards.sensor_visible({"position":game.pilot.position+Vector2(1900,0),"fleet_uid":1}),"own fleet remains tracked")
 game.pilot.secrets.satellite=true;game.docked_id=128;game.set_mode("shipyard")
 var screen=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
 check(screen.find_child("SatelliteSecret",true,false)!=null,"unlocked shipyard secret can be revisited")
 screen.show_satellite()
 check(screen.find_child("SatellitePicture",true,false).texture!=null,"original secret ship illustration loaded")
 check(screen.find_child("SatelliteStory",true,false).text.contains("Satellite of Love"),"original secret description displayed")
 var copy=game.Pilot.new();check(copy.restore(game.pilot.snapshot(),c) and copy.secrets.satellite,"secret unlock survives validated save")
 if "--visual" in OS.get_cmdline_user_args():
  await create_timer(.5).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev-satellite-shipyard.png")
 game.free();await process_frame
 print("ENVIRONMENT / ECONOMY / SECRETS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
