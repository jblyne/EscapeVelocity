extends SceneTree
const Flight=preload("res://scripts/flight.gd")
const Combat=preload("res://scripts/combat.gd")
var checks=0
var failures=0
var game
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func discard_shots() -> int:
 var count=game.shots.size()
 for shot in game.shots: shot.node.free()
 game.shots.clear()
 return count
func count_volleys(fps: int,classic: bool) -> int:
 game.controls.classic_fire=classic;game.pilot.selected_weapon=128;game.cooldown=0;game.primary_cooldowns.clear()
 var count=0
 for frame in fps*2:
  game.cooldown=Flight.reload_remaining(game.cooldown,1.0/fps,true)
  for weapon in game.primary_cooldowns: game.primary_cooldowns[weapon]=Flight.reload_remaining(float(game.primary_cooldowns[weapon]),1.0/fps,true)
  for burst in 8:
   if not game.fire_trigger(): break
  count+=discard_shots()
 return count
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-phase2-timing.json";game.controls.path="/tmp/ev-phase2-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 game.pilot.position=Vector2(10000,10000);game.pilot.outfits.clear();game.pilot.lasers=1;game.pilot.ship_id=128
 var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://../research/decoded/reference-timing.json")))
 check(source.constants.acceleration_divisor==10000 and source.constants.speed_divisor==100,"Fixture comes from verified original loader divisors")
 check(is_equal_approx(Flight.REFERENCE_HZ,source.normal_tick_hz),"Reference simulation follows original TickCount-bound loop")
 check(is_equal_approx(Flight.ACCEL_SCALE,1.2),"Acceleration conversion includes original 2x engine factor and consistent world scale")
 check(is_equal_approx(Flight.TURN_SCALE,PI/3),"Maneuver is degrees per reference update, converted to radians/second")
 var shuttle: Dictionary=game.catalog.record("ships",128).fields
 var player: Dictionary=game.pilot.flight_fields(shuttle)
 check(is_equal_approx(player.Speed,481.25),"Player shuttle receives recovered 1.75 cruise multiplier")
 check(is_equal_approx(Flight.acceleration(player),522),"Shuttle main-engine acceleration is 522 world units/second squared")
 for ship in game.catalog.data.ships.values():
  if int(ship.id)>=192: continue
  var f: Dictionary=ship.fields;var p: Dictionary=game.pilot.flight_fields(f)
  check(is_equal_approx(float(p.Speed),float(f.Speed)*1.75),"Player speed conversion for "+ship.name)
  check(is_equal_approx(Flight.acceleration(p),float(f.Accel)*1.2),"Engine conversion for "+ship.name)
  check(is_equal_approx(Flight.turn_rate(p),float(f.Maneuver)*PI/3),"Turn conversion for "+ship.name)
  var t: float=float(p.Speed)/Flight.acceleration(p)
  var old_velocity=Vector2.ZERO
  for fps in [30,60,120,144]:
   var result={"position":Vector2.ZERO,"velocity":Vector2.ZERO,"heading":0.0}
   for frame in int(ceil(t*fps))+1: result=Flight.step(result.position,result.velocity,result.heading,0,true,false,p,1.0/fps)
   check(absf(result.velocity.length()-float(p.Speed))<.001,"Cruise attained at reference acceleration for %s at %d Hz" % [ship.name,fps])
   if fps>30: check(result.velocity.distance_to(old_velocity)<.001,"Cruise speed independent of update rate for "+ship.name)
   old_velocity=result.velocity
 game.pilot.outfits={"150":1,"151":1,"152":1}
 var upgraded: Dictionary=game.pilot.flight_fields(shuttle)
 check(upgraded.Accel==585 and upgraded.Speed==743.75 and upgraded.Maneuver==5,"Original engine upgrades add their ModVal before player multipliers")
 game.load_system(0.0)
 check(absf(game.velocity.length()-743.75)<.01,"Arrival uses upgraded player cruise speed rather than raw catalog speed")
 game.pilot.outfits.clear();game.pilot.position=Vector2(10000,10000);game.velocity=Vector2.ZERO
 var custom: Dictionary=game.pilot.flight_fields(game.catalog.record("ships",900).fields)
 check(custom.Speed==game.catalog.field("ships",900,"Speed"),"Maverick retains requested cruise speed")
 check(is_equal_approx(Flight.acceleration(custom),float(custom.Accel)*.7) and is_equal_approx(Flight.turn_rate(custom),float(custom.Maneuver)*.65),"Maverick retains requested thrust and wing-sweep handling")
 var rotation=Flight.step(Vector2.ZERO,Vector2(100,0),0,1,false,false,player,.375)
 check(absf(rotation.heading-PI/2)<.00001 and rotation.velocity==Vector2(100,0),"Quarter-turn takes .375 seconds while lateral momentum coasts")
 var whole=Flight.step(Vector2.ZERO,Vector2.ZERO,0,0,true,false,player,.5)
 check(whole.velocity.is_equal_approx(Vector2(0,-261)) and whole.position.is_equal_approx(Vector2(0,-65.25)),"Half-second straight burn matches reference acceleration and distance")
 check(Combat.recovery_pulses(Vector2i(1,36),36)==0 and Combat.recovery_pulses(Vector2i(36,37),36)==1,"Recovery waits for original global interval boundary")
 check(Combat.recovery_pulses(Vector2i(1024,1026),36)==1,"Recovery counter wraps at 1025 like original")
 check(Combat.recover(0,90,180,100,1)==Vector2(0,92),"Negative signed integrity truncates toward zero, repairing two armor")
 check(Combat.recover(10,100,180,100,1)==Vector2(11,100),"Positive signed integrity adds one truncated shield point")
 check(Combat.recover(179,100,180,100,5)==Vector2(180,100),"Recovery clamps full shields")
 for fps in [30,60,120,144]:
  var layers=Vector2(50,100);var clock=0.0
  for frame in fps*6:
   var start=int(floor(clock+.000001));clock+=60.0/fps
   layers=Combat.recover(layers.x,layers.y,180,100,Combat.recovery_pulses(Vector2i(start,int(floor(clock+.000001))),36))
  check(layers==Vector2(60,100),"Recovery pulses are independent of update rate at %d Hz" % fps)
  check(count_volleys(fps,false)==6,"Selected laser cadence carries fractional timing at %d Hz" % fps)
  check(count_volleys(fps,true)==6,"Classic primary cadence carries fractional timing at %d Hz" % fps)
 game.controls.classic_fire=false
 for record in game.catalog.data.weapons.values():
  if int(record.id)>=900: continue
  check(is_equal_approx(game.arsenal.projectile_lifetime(int(record.id)),float(record.fields.Count)/60),"Recovered lifetime for "+record.name)
 for fps in [30,60,120,144]:
  game.arsenal.fire(128,game.pilot.position,0)
  var shot: Dictionary=game.shots.back();var origin: Vector2=shot.position
  for frame in fps:
   if game.shots.is_empty(): break
   game.update_shots(1.0/fps)
  check(game.shots.is_empty(),"Laser expires at its lifetime at %d Hz" % fps)
  check(absf(shot.position.distance_to(origin)-437.5)<.04,"Expired laser never travels past its recovered range at %d Hz" % fps)
 game.arsenal.fire(128,game.pilot.position,0);var clipped: Dictionary=game.shots.back();clipped.life=.005;var origin: Vector2=clipped.position
 game.update_shots(.1)
 check(absf(clipped.position.distance_to(origin)-4.375)<.001,"Last projectile update clips movement to remaining life")
 var clock_before: float=game.recovery_clock;game.set_mode("pause");game._physics_process(5)
 check(game.recovery_clock==clock_before,"Menus freeze shared recovery clock")
 game.free();await process_frame
 print("PHASE 2 TIMING: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
