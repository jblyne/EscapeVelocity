extends SceneTree
const Fireworks=preload("res://scripts/plea_fireworks.gd")
var game
var k
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func deploy(id):
 game.pilot.system_id=game.missions.system_of(id);game.load_system();game.set_mode("flight")
 game.landing_target=id;game.pilot.position=k.target_position(id)+Vector2(0,600)
 game.world_activity.open_contact();k.threaten();k.deploy()
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-live-appeals.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);k=game.world_killer
 game.set_process(false);game.set_physics_process(false)
 deploy(128)
 check(k.station.counter.text.begins_with("The Reckoning of Earth\n"),"countdown uses the threatened planet's name")
 check(game.hud.root.find_child("WorldKillerStatus",true,false)==null,"top red banner is removed")
 check(not k.live_message.is_empty(),"haughty live broadcast starts on deployment")
 check(k.APPEAL_VOICES.size()==4 and k.APPEAL_VOICES.all(func(voice):return voice.size()==4),"four personalities each have four escalating stages")
 var voice: int=k.personality
 var copy=game.Pilot.new()
 check(copy.restore(game.pilot.snapshot(),game.catalog) and copy.world_killer.active.voice==voice,"personality survives save validation")
 k.advance(12)
 check(game.mode=="flight" and k.bomb().bribe_offer>0,"first offer never opens modal")
 var remaining: float=k.bomb().remaining;k.advance(1)
 check(k.bomb().remaining<remaining,"countdown runs during live offer")
 var panel=game.hud.root.find_child("LiveWorldAppeal",true,false);panel._process(0)
 check(panel.visible and panel.accept.visible and panel.deny.visible,"live response controls visible")
 check(panel.accept.get_theme_stylebox("normal").bg_color==Color("777777") and panel.deny.get_theme_stylebox("normal").bg_color==Color("777777"),"response buttons share classic gray menu styling")
 check(panel.message.text.contains(k.clock(float(k.bomb().remaining))),"bottom message shows the current countdown")
 var first_color: Color=panel.message.get_theme_color("font_color")
 panel._process(.25)
 check(panel.message.get_theme_color("font_color")!=first_color,"new request highlight animates smoothly")
 var money: int=game.pilot.credits
 var original_offer: Dictionary=k.bomb().duplicate(true)
 var outcomes: Dictionary={}
 var bargaining_ok: bool=true
 var refusal_seed: int=0
 for seed_value in 12:
  game.pilot.world_killer.active=original_offer.duplicate(true)
  k.negotiation_rng.seed=seed_value
  var old_offer: int=k.bomb().bribe_offer
  bargaining_ok=bargaining_ok and k.demand_more() and not k.demand_more()
  var result: int=k.bomb().demand_result;outcomes[result]=true
  if result==0: refusal_seed=seed_value
  var rate: float=k.bomb().get("countdown_rate",1)
  bargaining_ok=bargaining_ok and (k.bomb().bribe_offer>old_offer if result==1 else rate==1.5 and k.bomb().bribe_offer==old_offer)
  var old_time: float=k.bomb().remaining;k.advance(2)
  bargaining_ok=bargaining_ok and is_equal_approx(old_time-k.bomb().remaining,2*rate)
  var saved=game.Pilot.new()
  bargaining_ok=bargaining_ok and saved.restore(game.pilot.snapshot(),game.catalog) and saved.world_killer.active.get("countdown_rate",1)==rate
 check(outcomes.has(0) and outcomes.has(1) and bargaining_ok,"asking more varies between raised bribes and faster refusal timers, persists rates and blocks repeat clicks")
 game.pilot.world_killer.active=original_offer.duplicate(true);k.bomb().countdown_rate=3.0
 k.negotiation_rng.seed=refusal_seed;k.demand_more()
 check(k.bomb().demand_result==0 and k.bomb().countdown_rate==3,"repeated refusals cannot exceed triple countdown speed")
 var paused_time: float=k.bomb().remaining;game.set_mode("pause");k.advance(5)
 check(k.bomb().remaining==paused_time,"accelerated countdown still respects intentional pause")
 game.set_mode("flight")
 var invalid_save=game.pilot.snapshot();invalid_save.world_killer.active.countdown_rate=4
 check(not game.Pilot.new().restore(invalid_save,game.catalog),"save validation rejects out-of-range countdown acceleration")
 game.pilot.world_killer.active=original_offer;k.pose();k.broadcast_slot=-1;k.broadcast()
 panel.deny.pressed.emit()
 check(k.bomb().denied and game.mode=="flight" and game.pilot.credits==money,"live denial continues play without payout")
 check(not k.deny() and not k.accept_bribe(),"stale controls cannot deny twice or accept rejected offer")
 k.advance(19)
 check(k.plea_pending and not k.bomb().denied,"larger offer returns without interruption")
 k.advance(float(k.bomb().remaining)-40)
 var refugees=game.npcs.filter(func(n):return n.has("evacuees"))
 check(not refugees.is_empty() and refugees[0].evacuees>0,"low timer launches transport full of civilians")
 check(refugees[0].has("departure") and refugees[0].weapons.is_empty() and not refugees[0].hostile,"evacuation transports flee without combat")
 var count: int=game.npcs.size();k.evacuate()
 check(game.npcs.size()==count,"evacuation launches only once per scheduled wave")
 var oldpos: Vector2=refugees[0].position
 for i in 120: game.traffic.update(1.0/60.0)
 check(refugees[0].position.distance_to(oldpos)>0,"evacuation ship actually flies outward")
 k.launch_fireworks("WE'RE SORRY")
 check(k.effects.any(func(e):return e is Fireworks),"firework plea creates world effect")
 k.advance(3)
 var show=k.effects.filter(func(e):return e is Fireworks).back()
 check(show.letters.visible and show.destinations.size()>100 and show.words.text=="WE'RE SORRY","firework spells readable apology after launch")
 if "--visual" in OS.get_cmdline_user_args():
  game.camera.position=game.v3(k.target_position(128)+Vector2(0,180),1200);game.camera.size=850
  await create_timer(.5).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev-live-appeals.png")
 k.advance(float(k.bomb().remaining)-8)
 check(game.mode=="flight" and k.live_message.contains("00:08"),"final mercy request keeps flight active")
 panel._process(0)
 check(panel.urgency==3 and panel.attention>0,"final pleas trigger the strongest urgency highlight")
 panel._process(0);var offer: int=k.bomb().bribe_offer;panel.accept.pressed.emit()
 check(k.bomb().is_empty() and game.mode=="flight" and game.pilot.credits==money+offer,"live accept pays and recalls without opening menu")
 check(not k.accept_bribe(),"double accept cannot pay twice")
 deploy(129);k.advance(80)
 check(k.station.counter.text.begins_with("The Reckoning of "+k.world_name(129)+"\n"),"station countdown uses its own target name")
 check(game.npcs.any(func(n):return n.get("evacuation_origin",-1)==129),"station also launches evacuation transports")
 game.set_mode("pause");remaining=k.bomb().remaining;k.advance(10)
 check(k.bomb().remaining==remaining,"intentional pause still freezes sequence")
 game.free();await process_frame
 print("LIVE APPEALS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
