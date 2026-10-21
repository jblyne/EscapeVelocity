extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func clear():
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 for shot in game.shots: shot.node.queue_free()
 game.shots.clear()
func spawn(id: int,faction: int,ai: int,at: Vector2) -> Dictionary:
 var npc=game.traffic.spawn(id,faction,ai,at);npc.truce=true;npc.hostile=false;npc.goal=at+Vector2(0,-1000);return npc
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-phase3.json";game.controls.path="/tmp/ev-phase3-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight");clear();game.pilot.position=Vector2(10000,10000);game.velocity=Vector2.ZERO
 var traffic=game.traffic;traffic.rng.seed=164
 var merchant=spawn(130,128,1,game.pilot.position+Vector2(300,0));merchant.ambient=true
 var pirate=spawn(148,130,2,merchant.position+Vector2(100,0))
 check(traffic.opponent(merchant)==pirate,"Civilian detects nearby pirate as threat")
 traffic.update(.1)
 check(merchant.behavior=="Evading" and merchant.ambient_retreat,"Wimpy merchant evades pirate immediately")
 check(game.shots.filter(func(s):return s.source==merchant).is_empty(),"Wimpy civilian does not fire while fleeing")
 pirate.disabled=true
 check(traffic.opponent(merchant).is_empty(),"Disabled pirate is no longer an active threat")
 pirate.disabled=false;pirate.faction=128;pirate.nemesis=merchant.model
 check(traffic.opponent(merchant)==pirate,"Civilian detects actual attacker even of same government")
 merchant.ai=2;merchant.ambient_retreat=false;pirate.nemesis=null;pirate.faction=130
 check(not traffic.ordinary_retreat(merchant,pirate),"Healthy armed trader can defend itself")
 check(traffic.can_hit({"npc_shot":true,"source":merchant},pirate),"Defending merchant rounds can actually hit pirate aggressor")
 pirate.ai=3;pirate.ambient=true;pirate.health=pirate.max_health*.2
 check(traffic.ordinary_retreat(pirate,merchant),"Ordinary wounded pirate breaks off instead of fighting to death")
 pirate.health=pirate.max_health
 merchant.health=merchant.max_health-merchant.shield_capacity*.8
 check(traffic.ordinary_retreat(merchant,pirate) and not game.Combat.is_disabled(merchant),"Armed trader breaks off while low-shield hull is still operational")
 merchant.mission_id=1
 check(not traffic.ordinary_retreat(merchant,pirate),"Generic retreat cannot override scripted mission actors")
 merchant.erase("mission_id");merchant.bounty_port=128
 check(not traffic.ordinary_retreat(merchant,pirate) and not traffic.request_departure(merchant),"Tribute hunter contract cannot silently depart")
 merchant.erase("bounty_port")
 var f: Dictionary=game.catalog.record("ships",130).fields
 check(is_equal_approx(traffic.cruise_speed(merchant,f),float(f.Speed)*1.25),"Ordinary NPC uses recovered source 1.25 speed modifier")
 merchant.fleet_uid=1
 check(is_equal_approx(traffic.cruise_speed(merchant,f),float(f.Speed)),"Player escort retains source base speed")
 merchant.erase("fleet_uid")
 for id in game.catalog.data.ships:
  if int(id)>=900: continue
  var fields: Dictionary=game.catalog.record("ships",int(id)).fields
  check(is_equal_approx(traffic.cruise_speed(merchant,fields),float(fields.Speed)*1.25),"Source speed for hull "+str(id))
 clear()
 var patrol=spawn(148,128,3,game.pilot.position+Vector2(700,0));patrol.ambient=true
 var cargo=game.missions.offer(132,128);cargo.picked=true;game.pilot.campaign.active=[cargo]
 check(traffic.inspection_target(patrol),"Eligible patrol approaches illegal cargo carrier")
 traffic.update(.1)
 check(patrol.behavior=="Inspecting cargo","Patrol enters inspection approach instead of random cruising")
 var fields: Dictionary=game.catalog.record("missions",132).fields
 var acquired: bool=false
 for frame in 1800:
  traffic.update(1.0/60.0)
  if game.missions.can_scan(patrol,fields): acquired=true;break
 check(acquired,"Patrol physically closes and matches motion to complete inspection")
 check(patrol.get("scanned_mission_132",false),"Approach completion invokes inspection without waiting for global five-second poll")
 patrol.erase("scanned_mission_132")
 patrol.position=game.pilot.position+Vector2(300,300);patrol.velocity=Vector2(34.99,-34.99)
 check(game.missions.can_scan(patrol,fields),"Recovered scan range and relative motion boundaries apply")
 patrol.velocity.x=35
 check(not game.missions.can_scan(patrol,fields),"Fast fly-by cannot complete inspection")
 patrol.velocity=Vector2.ZERO;patrol.position.x+=.01
 check(not game.missions.can_scan(patrol,fields),"Inspection cannot reach past 300 world-unit square")
 patrol.position=game.pilot.position;game.cloak.active=true
 check(not traffic.inspection_target(patrol),"Cloaking stops patrol acquisition")
 game.cloak.active=false;patrol["scanned_mission_132"]=true
 check(not traffic.inspection_target(patrol),"Completed inspection does not chase same cargo forever")
 game.pilot.campaign.active=[];clear()
 game.velocity=Vector2(80,40)
 for id in [128,131,132,133,139,140,143,144,150,191,901]:
  if id in [133,143]:
   spawn(148,130,4,game.pilot.position+Vector2(0,500));game.target_index=0
  game.arsenal.fire(id,game.pilot.position,0,false,{},{} )
  if game.shots.is_empty(): check(false,"Weapon emitted "+str(id));continue
  var shot=game.shots.back();var guidance: int=int(game.catalog.field("weapons",id,"Guidance"))
  var expected: Vector2=Vector2(0,float(shot.speed)*(1.0 if id in [133,143] else -1.0))
  if id<900 and guidance not in [4,7,8]:
   expected+=game.velocity
   if guidance==5: expected*=.5
  check(shot.velocity.is_equal_approx(expected),"Recovered player launch drift and exceptions for "+str(id))
  clear()
 var gunner=spawn(148,130,4,game.pilot.position+Vector2(500,0));gunner.velocity=Vector2(80,40)
 game.arsenal.fire(128,gunner.position,0,true,gunner,{})
 check(game.shots.back().velocity.is_equal_approx(Vector2(0,-float(game.catalog.field("weapons",128,"Speed")))),"NPC rounds do not inherit player-only launch drift")
 clear();game.pilot.campaign.active=[];game.velocity=Vector2.ZERO
 # Normal arrivals retain encounter-table identity and have an inward motion vector.
 traffic.enabled=true;traffic.timer=0;traffic.rng.seed=164;traffic.update(.01)
 var arrivals=game.npcs.filter(func(n):return n.ambient)
 check(not arrivals.is_empty(),"Weighted encounter scheduler produces ambient arrival")
 if not arrivals.is_empty(): check(arrivals[0].velocity.dot(game.pilot.position-arrivals[0].position)>0,"New arrival travels inward rather than spawning stationary")
 game.set_mode("pause");var count: int=game.npcs.size();traffic.timer=0;traffic.update(20)
 check(game.npcs.size()==count and traffic.timer==0,"Paused menus cannot dispatch or move encounters")
 game.free();await process_frame
 print("PHASE 3 NPC: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
