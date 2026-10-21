extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,text: String):
 checks+=1
 if not ok: failures+=1;push_error(text)
func _initialize(): call_deferred("run")
func clear():
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 for escort in game.escorts.duplicate():
  if is_instance_valid(escort.model): escort.model.queue_free()
 game.escorts.clear()
 for shot in game.shots: shot.node.queue_free()
 game.shots.clear()
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-phase4.json";game.controls.path="/tmp/ev-phase4-controls.json";game.muted=true;game.traffic.enabled=false
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight");clear();game.pilot.position=Vector2(10000,10000);game.velocity=Vector2.ZERO
 game.pilot.ship_id=900;game.pilot.ship_fields=game.catalog.record("ships",900).fields.duplicate(true);game.pilot.outfits=game.Shipyard.stock_outfits(game.catalog,900);game.pilot.outfits["138"]=1;game.pilot.outfits["139"]=2;game.pilot.selected_weapon=146;game.secondary_safe=false;game.cooldown=0
 check(game.fire_player() and game.outfitter.count(139)==1,"Launching a real bay spends exactly one docked fighter")
 var f=game.escorts[0]
 check(f.weapons.size()==2 and f.weapons[0].count==4 and f.weapons[1].ammo==2,"Hawk carries all source guns, mounts and missile ammunition")
 var enemy=game.traffic.spawn(148,130,3,f.position+Vector2(0,-200));enemy.hostile=true;enemy.truce=false
 for w in f.weapons: w.cooldown=0
 game.traffic.advance_weapons(f,enemy,0)
 check(game.shots.size()==5 and f.weapons[1].ammo==1,"Fighter fires four gun mounts and one finite missile")
 check(game.shots.all(func(s):return s.get("source",{})==f and s.get("npc_shot",false)),"Fighter rounds retain allied ownership and distinct target")
 game.arsenal.damage_fighter(f,40,40);f.sortie_seconds=75;f.command="formation"
 var health: float=f.shield;var ammo: int=f.weapons[1].ammo
 check(game.save_game(false),"Save with deployed fighter succeeds")
 var file=FileAccess.open(game.save_path,FileAccess.READ);var saved=JSON.parse_string(file.get_as_text());file.close()
 check(saved.fighter_sorties.size()==1 and saved.outfits["139"]==1,"Save separates active sortie from docked inventory without duplication")
 check(game.Pilot.new().restore(saved,game.catalog),"Actual JSON save passes fighter validation")
 game.load_game();game.traffic.enabled=false;f=game.escorts.filter(func(n):return not n.get("captured",false))[0]
 check(is_equal_approx(f.shield,health) and f.weapons[1].ammo==ammo and f.sortie_seconds==75 and f.command=="formation","Reload preserves damage, spent missile, elapsed endurance and formation order")
 game.load_system(0.0);f=game.escorts.filter(func(n):return not n.get("captured",false))[0]
 check(f.has("arrival_delay") and not f.model.visible and f.sortie_seconds==75 and f.weapons[1].ammo==ammo,"Warp followers retain sortie state and arrive after flagship")
 f.erase("arrival_delay");f.model.show();f.position=game.pilot.position;f.velocity=Vector2(100,0);f.recalling=true
 game.arsenal.update_escorts(.01)
 check(f in game.escorts,"High-speed fly-by does not instantly dock fighter")
 f.position=game.pilot.position;f.velocity=game.velocity;game.arsenal.update_escorts(.01)
 check(f not in game.escorts and game.outfitter.count(139)==2,"Matching position and speed docks and returns exactly one fighter")
 game.arsenal.recover_fighter(f);check(game.outfitter.count(139)==2,"Repeated recovery cannot duplicate a craft")
 game.cooldown=0;game.fire_player();f=game.escorts.back()
 check(f.shield==game.fighter_wing.shield_capacity(game.catalog,148) and f.weapons[1].ammo==2 and f.sortie_seconds==0,"Relaunch after docking is repaired, refueled and rearmed")
 f.position=game.pilot.position+Vector2(1000,0);f.sortie_seconds=179.99;game.arsenal.update_escorts(.02)
 check(f.recalling,"Exhausted endurance automatically orders docking")
 game.arsenal.damage_fighter(f,100000,100000);game.save_game(false);game.load_game();game.traffic.enabled=false
 check(game.escorts.filter(func(n):return not n.get("captured",false)).is_empty() and game.outfitter.count(139)==1,"Destroyed fighter stays lost through save and reload")
 var old=saved.duplicate(true);old.erase("fighter_sorties");check(game.Pilot.new().restore(old,game.catalog),"Legacy saves without sortie field remain compatible")
 for mutation in ["shield","ammo","carrier_ship","bay_weapon","sortie_seconds"]:
  var bad=saved.duplicate(true)
  if mutation=="ammo": bad.fighter_sorties[0].ammo=[9999]
  else: bad.fighter_sorties[0][mutation]=-999
  check(not game.Pilot.new().restore(bad,game.catalog),"Invalid fighter %s is rejected atomically" % mutation)
 clear();game.pilot.fleet=[];game.velocity=Vector2.ZERO
 for rate in [30,60,120]:
  game.arsenal.launch_escort(148,game.pilot.position+Vector2(700,0),0)
  var returning=game.escorts.back();returning.recalling=true;returning.velocity=Vector2(-50,0)
  for frame in rate*30:
   game.arsenal.update_escorts(1.0/rate)
   if returning not in game.escorts: break
  check(returning not in game.escorts,"Physical recall docks successfully at %d updates per second" % rate)
 game.arsenal.launch_escort(135,game.pilot.position+Vector2(0,-200),0)
 var vulnerable=game.escorts.back();var before_shield: float=vulnerable.shield
 var shooter=game.traffic.spawn(150,140,4,game.pilot.position+Vector2(0,-400))
 game.arsenal.fire_beam(147,shooter.position,Vector2.DOWN,{},shooter,true)
 check(vulnerable not in game.escorts or vulnerable.shield<before_shield,"Enemy beams can hit deployed fighters before the flagship")
 clear()
 var carrier=game.traffic.spawn(134,128,3,game.pilot.position+Vector2(600,0));var bay={}
 for w in carrier.weapons:
  if game.arsenal.kind(w.id)=="bay": bay=w;break
 check(not bay.is_empty(),"Source carrier has stock bay weapon")
 if not bay.is_empty():
  var before: int=bay.ammo
  check(game.traffic.launch_fighter(carrier,135,int(bay.id)),"NPC carrier deploys its source fighter")
  bay.ammo-=1;var child=game.npcs.back();child.position=carrier.position;child.velocity=carrier.velocity;child.recalling=true
  check(game.fighter_wing.update_carrier_fighter(child,.01) and child not in game.npcs and bay.ammo==before and bay.cooldown>=3,"Carrier recovers survivor once and applies a service delay")
  game.fighter_wing.update_carrier_fighter(child,.01)
  check(bay.ammo==before,"Stale carrier recovery cannot mint another fighter")
  game.pilot.fleet=[{"id":134}];game.fleet_service.prepare();carrier.fleet_uid=game.pilot.fleet[0].uid;carrier.captured=true;carrier.truce=true;carrier.hostile=false;game.escorts.append(carrier)
  game.traffic.launch_fighter(carrier,135,int(bay.id));bay.ammo-=1;child=game.npcs.back();child.shield=70;child.armor=0;child.health=70;child.sortie_seconds=44;child.weapons[1].ammo=1
  check(game.save_game(false),"Captured carrier and deployed wing can save")
  game.load_game();game.traffic.enabled=false
  var children=game.npcs.filter(func(n):return n.get("fighter",false))
  check(children.size()==1 and children[0].shield==70 and children[0].weapons[1].ammo==1 and children[0].sortie_seconds==44,"Carrier wing survives reload with damage and finite ammo")
  game.load_system(0.0)
  children=game.npcs.filter(func(n):return n.get("fighter",false))
  check(children.size()==1 and children[0].player_ally,"Captured carrier wing follows travel without duplicate deployment")
 var wing=game.npcs.filter(func(n):return n.get("fighter",false))
 var parent=game.escorts.filter(func(n):return n.has("fleet_uid"))[0]
 game.pilot.fleet[0].command="hold"
 check(game.fleet_service.target(wing[0]).is_empty() and game.fleet_service.record(wing[0]).is_empty(),"Carrier fighter inherits hold command without being mistaken for its parent fleet record")
 game.fighter_wing.update_carrier_fighter(wing[0],.01)
 check(wing[0].behavior=="Holding with carrier","Owned carrier wing honors fleet hold")
 game.pilot.fleet[0].command="recall";game.fighter_wing.update_carrier_fighter(wing[0],.01)
 check(wing[0].get("recalling",false),"Fleet recall also brings its carrier fighters home")
 game.fighter_wing.dock_owned_carriers()
 game.fleet_service.sync()
 check(game.npcs.filter(func(n):return n.get("fighter",false)).is_empty() and game.pilot.fleet[0].wings.is_empty(),"Port docking services and clears owned carrier sorties before encounter refresh")
 if "--visual" in OS.get_cmdline_user_args():
  game.cooldown=0;game.pilot.selected_weapon=146;game.fire_player();game.fleet_return_mode="flight";game.set_mode("fleet")
  await create_timer(.5).timeout
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev166-fleet.png")
 game.free();await process_frame
 print("PHASE 4 FIGHTERS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
