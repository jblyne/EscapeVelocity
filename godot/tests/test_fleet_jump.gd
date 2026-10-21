extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev176-fleet-jump.json";game.controls.path="/tmp/ev176-controls.json";game.traffic.enabled=false;game.muted=true
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 for hz in [30,60,120]:
  game.pilot.fleet=[{"id":130,"hired":true,"command":"hold"},{"id":146,"command":"attack"}]
  game.pilot.credits=10000000;game.pilot.fuel=game.pilot.fuel_capacity();game.pilot.cheat_infinite_fuel=true;game.pilot.cheat_chain_jump=false
  game.pilot.system_id=128;game.pilot.position=Vector2(18000,18000);game.load_system();game.set_mode("flight")
  var ships: Array=game.escorts.duplicate();var offsets: Array=[];var bases: Array=[]
  for ship in ships: offsets.append(ship.position-game.pilot.position);bases.append(ship.model.scale)
  game.velocity=Vector2(170,90);game.pilot.heading=1.4;game.destination=int(game.catalog.system(128).links[0]);game.start_jump()
  check(game.hyperdrive.active(),"J starts fleet jump at %d Hz" % hz)
  var phases: Dictionary={};var matched: bool=true;var last_speed: float=0;var burned: bool=false;var captured: bool=false
  for i in hz*120:
   var phase: String=game.hyperdrive.phase
   game._physics_process(1.0/hz)
   if game.pilot.system_id!=128: break
   phases[phase]=true
   for index in ships.size():
    var ship: Dictionary=ships[index]
    if not ship.velocity.is_equal_approx(game.velocity) or (ship.position-game.pilot.position).distance_to(offsets[index])>.05 or absf(angle_difference(ship.heading,game.pilot.heading))>.0001: matched=false
   if "--visual" in OS.get_cmdline_user_args() and hz==60 and phase=="accelerating" and game.hyperdrive.remaining<game.hyperdrive.burn_seconds*.5 and not captured:
    captured=true;game.camera.position=game.v3(game.pilot.position+game.velocity*.05,1200)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("/tmp/ev176-fleet-warp.png")
   if phase=="spooling": check(game.escorts[0].velocity.length()<.001,"Fleet stops with flagship before spool")
   if phase=="accelerating": burned=burned or game.velocity.length()>last_speed;last_speed=game.velocity.length()
  check(phases.has("stopping") and phases.has("aligning") and phases.has("spooling") and phases.has("accelerating") and burned,"All departure phases include the fleet")
  check(matched,"Different hulls and Hold/Attack orders share speed, heading and formation throughout jump")
  check(game.pilot.system_id!=128 and game.escorts.size()==2,"Whole fleet arrives in destination")
  check(game.escorts.all(func(s):return s.velocity.is_equal_approx(game.velocity) and absf(angle_difference(s.heading,game.pilot.heading))<.001 and s.position.distance_to(game.pilot.position)<400),"Fleet arrives alongside flagship with matched velocity")
  for i in hz/2: game._physics_process(1.0/hz)
  check(game.escorts.all(func(s):return s.velocity.is_equal_approx(game.velocity)),"Arrival formation retains speed through visual transition")
  game.destination=int(game.catalog.system(game.pilot.system_id).links[0]);game.pilot.position=Vector2(18000,18000);game.start_jump()
  game.hyperdrive.phase="accelerating";game.hyperdrive.remaining=1
  game._physics_process(1.0/hz)
  var before: Vector2=game.escorts[0].velocity
  game.cancel_jump(false)
  check(not game.escorts[0].has("fleet_warp_scale") and game.escorts[0].model.scale.is_equal_approx(bases[0]) and game.escorts[0].velocity==before,"Cancel restores normal hull shape without dropping convoy momentum")
 game.pilot.cheat_chain_jump=true;game.pilot.system_id=128;game.pilot.position=Vector2(18000,18000);game.load_system();game.set_mode("flight")
 game.destination=game.route_to(141).back();game.map_route=game.route_to(game.destination);game.start_jump()
 for frame in 12000:
  game._physics_process(1.0/60)
  if not game.hyperdrive.active() and game.chain_route.is_empty(): break
 check(game.pilot.system_id==game.destination or game.destination==-1,"Chain route finishes")
 check(game.escorts.size()==2 and game.escorts.all(func(s):return s.velocity.is_equal_approx(game.velocity)),"Chain hops retain fleet and final arrival speed")
 game.free();await process_frame
 print("FLEET JUMP: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
