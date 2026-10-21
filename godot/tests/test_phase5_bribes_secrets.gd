extends SceneTree
const Bribes=preload("res://scripts/bribery.gd")
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 for credits in [0,500,10000,100000,1000000,10000000,1000000000]:
  for flags in [0,0x8000]:
   var rng=RandomNumberGenerator.new();rng.seed=72
   for i in 10:
    for price in [Bribes.ship_quote(credits,flags,rng),Bribes.landing_quote(credits,flags,rng)]:
     check(price>=1000 and price<=900000 and price%1000==0,"Quote respects source bounds/rounding")
     check(price<=maxi(1000,int(credits*.333)),"Quote respects one-third wallet ceiling")
 check(Bribes.discount(3000)==2200 and Bribes.discount(1000)==700,"Discount truncates to hundreds after multiplying .75")
 check(not Bribes.landing_willing(30,0x4000,128) and Bribes.landing_willing(31,0x4000,128),"Source landing willingness boundary is roll > 30")
 check(not Bribes.landing_willing(99,0,136) and Bribes.landing_willing(99,0,-1),"Landing willingness respects government flag and independent exception")
 var quote_rng=RandomNumberGenerator.new();quote_rng.seed=1
 check(Bribes.landing_quote(1000000,0,quote_rng)==3000 and Bribes.landing_quote(1000000,0x8000,quote_rng)==4000,"Source base and government surcharge are applied before quote rounding")
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev174-phase5.json";game.controls.path="/tmp/ev174-controls.json";game.traffic.enabled=false;game.muted=true
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false);game.set_mode("flight")
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 game.pilot.credits=100000
 var npc=game.traffic.spawn(131,130,3,game.pilot.position+Vector2(500,0));npc.hostile=true;game.target_index=game.npcs.find(npc)
 game.interactions.open_hail();game.interactions.offer_bribe()
 check(game.interactions.page=="bribe" and game.hud.modal_root.find_child("NegotiateBribe",true,false)!=null,"Real ship hail offers negotiation")
 var terms: Dictionary=game.interactions.bribe_terms(npc);var initial: int=game.interactions.bribe_price(npc)
 game.pilot.credits+=100000
 check(game.interactions.bribe_price(npc)==initial,"Ship quote stays stable when wallet changes")
 terms.bargains=true
 game.hud.modal_root.find_child("NegotiateBribe",true,false).pressed.emit()
 check(game.interactions.bribe_price(npc)==Bribes.discount(initial),"Actual UI negotiates source discount")
 var price: int=game.interactions.bribe_price(npc)
 check(not game.interactions.negotiate_bribe() and game.interactions.bribe_price(npc)==price,"Negotiation cannot compound")
 game.pilot.credits=price-1
 check(not game.interactions.pay_bribe() and not npc.truce,"Unaffordable bribe cannot grant ceasefire")
 game.pilot.credits=100000
 var reputation=game.pilot.reputation.duplicate()
 check(game.interactions.pay_bribe() and game.pilot.credits==100000-price and npc.truce and game.pilot.reputation==reputation,"Payment pacifies only this captain without changing government record")
 check(not game.interactions.pay_bribe(),"Paid quote cannot charge twice")
 game.set_mode("flight");npc.hector=true;npc.hostile=true;npc.truce=false;game.interactions.open_hail();game.interactions.offer_bribe()
 check(game.interactions.page!="bribe","Hector cannot be bribed")
 var service=game.world_activity;service.contact_id=128;game.pilot.reputation["128"]=-1000;game.set_mode("world_comms")
 var officer: Dictionary=service.landing_officer(128);var original: int=service.landing_bribe_price(128)
 game.pilot.credits+=999999
 check(service.landing_bribe_price(128)==original,"Landing quote stays fixed for the day's officer")
 officer.willing=true;officer.bargains=false
 check(not service.negotiate_landing_bribe() and officer.refused and not service.pay_landing_bribe(),"Failed landing negotiation ends this officer's willingness")
 game.pilot.campaign.day+=1
 var next_officer: Dictionary=service.landing_officer(128)
 check(not next_officer.negotiated and not next_officer.refused,"A different day offers a fresh official")
 var old_pilot=game.pilot;game.pilot=game.Pilot.new()
 check(not service.landing_officer(128).negotiated and service.landing_officer_owner==game.pilot,"Officials and prices cannot leak across pilots")
 game.pilot=old_pilot
 game.set_mode("title")
 var menu=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
 menu.about_with_modifiers(true,false)
 check(menu.parody_credits and menu.credits_label.text.contains("not-too-distant"),"Option-About loads original parody credits")
 menu.close_extras();await process_frame
 menu.about_with_modifiers(false,true)
 var extras=JSON.parse_string(FileAccess.get_file_as_string("res://data/original_extras.json"))
 check(menu.credits_label.text=="\n".join(extras["20003"].strings),"Command-About loads original additional credits")
 menu.close_extras();await process_frame
 menu.new_pilot()
 var event=InputEventKey.new();event.keycode=KEY_X;event.pressed=true
 menu._input(event)
 check(not is_instance_valid(menu.extras_panel),"Title secret cannot hijack new-pilot dialog")
 menu.pilot_info();menu.about_with_modifiers(false,false);menu.original_credits()
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;menu._input(escape)
 check(not is_instance_valid(menu.extras_panel),"Escape closes credits opened from the ordinary About dialog")
 menu.pilot_info();menu._input(event)
 check(is_instance_valid(menu.extras_panel),"X opens haikus on unobstructed title")
 menu.close_extras();await process_frame
 game.pilot.secrets.satellite=true;game.docked_id=128;game.set_mode("shipyard")
 var yard=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
 var old_ship: int=game.pilot.ship_id;var balance: int=game.pilot.credits
 yard.show_satellite()
 check(yard.find_child("SatellitePicture",true,false)!=null and game.pilot.ship_id==old_ship and game.pilot.credits==balance,"Satellite keeps recovered presentation without silently buying an invented hull")
 if "--visual" in OS.get_cmdline_user_args():
  game.set_mode("flight");npc.hector=false;npc.hostile=true;npc.truce=false;game.interactions.open_hail();game.interactions.offer_bribe()
  await create_timer(.5).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev174-bribe.png")
 game.free();await process_frame
 print("PHASE 5 BRIBES / SECRETS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
