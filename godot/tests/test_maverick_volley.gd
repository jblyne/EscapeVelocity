extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,text: String):
 checks+=1
 if not ok: failures+=1;push_error(text)
func _initialize(): call_deferred("run")
func clear_shots():
 for shot in game.shots: shot.node.queue_free()
 game.shots.clear();game.cooldown=0
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-volley.json";game.controls.path="/tmp/ev-volley-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 game.pilot.ship_id=900;game.pilot.ship_fields=game.catalog.record("ships",900).fields.duplicate(true);game.pilot.outfits=game.Shipyard.stock_outfits(game.catalog,900);game.pilot.lasers=0;game.controls.preset(false);game.pilot.selected_weapon=901;game.secondary_safe=false
 var v=game.maverick_volley
 var enemies: Array=[]
 for i in 4:
  var npc=game.traffic.spawn(148,130,3,game.pilot.position+Vector2(100+i*80,0));npc.hostile=true;enemies.append(npc)
 var friendly=game.traffic.spawn(148,128,3,game.pilot.position+Vector2(0,100));friendly.hostile=false
 var remote=game.traffic.spawn(148,130,3,game.pilot.position+Vector2(game.arsenal.weapon_reach(901)+100,0));remote.hostile=true
 game.pilot.outfits["902"]=3
 check(v.update(true,.2) and game.shots.is_empty(),"Initial press waits to distinguish hold from tap")
 v.update(true,.25)
 check(v.ready and v.targets.size()==3 and game.shots.is_empty(),"Hold locks all possible enemies at once, up to available ammo")
 check(friendly not in v.targets and remote not in v.targets,"Friendly and out-of-range ships cannot be locked")
 v.update(false,.01);check(game.shots.is_empty() and v.ready,"Release arms the next press without firing")
 v.update(true,.01)
 check(game.shots.size()==3 and game.outfitter.count(902)==0,"Next press launches entire volley and spends one round per target")
 var actual: Array=[]
 for shot in game.shots: actual.append(shot.target)
 check(actual.size()==3 and actual[0]!=actual[1] and actual[1]!=actual[2] and actual[0]!=actual[2],"Every missile receives its own distinct locked target")
 check(not v.ready and v.targets.is_empty(),"Fired volley clears locks")
 v.update(true,1);check(game.shots.size()==3,"Continuing to hold after volley cannot auto-fire or reacquire")
 v.update(false,.01);clear_shots();game.pilot.outfits["902"]=5
 v.update(true,.1);v.update(false,.01)
 check(game.shots.size()==1 and game.outfitter.count(902)==4,"Quick tap retains single-missile firing")
 clear_shots();v.update(true,.5);v.update(false,.01)
 var doomed=v.targets[0];game.traffic.retire(doomed);v.update(true,.01)
 check(game.shots.size()==3 and game.outfitter.count(902)==1,"Lost target is skipped without wasting its round")
 v.reset();clear_shots();game.pilot.outfits["902"]=5;v.update(true,.5);v.update(false,.01)
 game.set_mode("pause");check(not v.ready and v.targets.is_empty(),"Menus cancel armed volley")
 game.set_mode("flight");game.pilot.selected_weapon=900
 check(not v.update(true,1),"M61 keeps ordinary primary fire behavior")
 game.pilot.selected_weapon=901;game.controls.preset(true)
 check(not v.update(true,1),"Optional classic firing is unchanged")
 game.controls.preset(false);game.pilot.ship_id=129
 check(not v.update(true,1),"Other ships do not gain Maverick volley")
 game.pilot.ship_id=900;game.pilot.cheat_all_weapons=true;game.pilot.outfits.erase("902");v.update(true,.5);v.update(false,.01)
 check(v.ready and v.targets.size()==3,"Unlimited-ammo cheat locks all remaining eligible enemies")
 # Every targeting weapon uses its own range, target override and reload.
 for id in [131,132,133,134,143,144,148,149,191,903]:
  v.reset();clear_shots();game.pilot.selected_weapon=id;game.pilot.heading=-PI/2
  check(v.update(true,.5) and v.ready,"Targeted weapon acquires a multi-lock: %d" % id)
  var locked: Array=v.targets.duplicate()
  v.update(false,.01);v.update(true,.01)
  check(game.shots.size()==locked.size() and game.shots.size()>1,"Targeted weapon fires entire volley together: %d" % id)
  if id!=149:
   for i in game.shots.size(): check(game.shots[i].target==locked[i].model,"Volley respects distinct target override: %d" % id)
  check(game.cooldown>0,"Targeted volley starts weapon reload: %d" % id)
 v.reset();clear_shots();game.pilot.selected_weapon=132;v.update(true,.5);v.update(false,.01)
 game.pilot.selected_weapon=903;v.update(false,.01)
 check(not v.ready and v.targets.is_empty(),"Switching targeted weapons cancels old locks")
 for id in [128,139,140,141,142,147,150,152]: check(not v.supports(id),"Forward-only weapons, bombs, flares and beams keep normal firing: %d" % id)
 game.pilot.cheat_all_weapons=false;game.pilot.selected_weapon=131
 for outfit in game.catalog.data.outfits.values():
  if int(outfit.fields.ModType)==1 and int(outfit.fields.ModVal)==131: game.pilot.outfits[str(outfit.id)]=1
 var torpedo_ammo: int=game.outfitter.ammo_id(131);game.pilot.outfits[str(torpedo_ammo)]=2
 v.reset();clear_shots();v.update(true,.5);v.update(false,.01)
 check(v.targets.size()==2,"Torpedo locks are limited by their own ammunition")
 v.update(true,.01)
 check(game.shots.size()==2 and game.outfitter.count(torpedo_ammo)==0,"Torpedo volley spends one round per target")
 v.reset();game.world_activity.hunter_celebration={"generation":1,"sponsor":"Pirate's Cove (NGC-4812 system)","income":8000,"gave_up":false}
 var banner=game.hud.hunter_announcement;banner._process(0);banner._process(1)
 check(banner.visible and banner.reward.text.contains("5,000") and banner.detail.text.contains("8,000"),"Hunter celebration prominently shows reward and employer")
 var settled: float=banner.position.y
 banner.age=0;banner._process(.05)
 check(banner.position.y<settled and banner.modulate.a<1,"Hunter celebration slides and fades in")
 banner.age=8.5;banner._process(0);check(banner.modulate.a<1,"Celebration fades out smoothly")
 banner.age=10;banner._process(0);check(not banner.visible,"Celebration exits without obscuring flight forever")
 if "--visual" in OS.get_cmdline_user_args():
  game.world_activity.hunter_celebration.generation=2
  v.acquire()
  for frame in 90: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev165-celebration.png")
 game.free();await process_frame
 print("MAVERICK VOLLEY: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
