extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-offer-assistance.json";game.controls.path="/tmp/ev-offer-assistance-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 var npc=game.traffic.spawn(129,129,1,game.pilot.position+Vector2(500,0))
 game.Combat.sync(npc);npc.shield=0;npc.armor=(npc.max_health-npc.shield_capacity)*.3;npc.health=npc.armor
 game.interactions.disable(npc,false)
 game.target_index=game.npcs.find(npc);game.interactions.open_hail()
 var button=game.hud.modal_root.find_child("OfferAssistance",true,false)
 check(button is Button,"Communications exposes Offer Assistance")
 button.pressed.emit()
 check(game.mode=="flight" and npc.has("rescue_order"),"Offer starts repair rendezvous and resumes flight")
 game.interactions.update_special(npc,4)
 check(npc.disabled,"Remote offer does not instantly repair distant ship")
 game.pilot.position=npc.position;game.velocity=Vector2(100,0);game.interactions.update_special(npc,4)
 check(npc.disabled,"Must match motion before repairing")
 game.velocity=npc.velocity;game.interactions.update_special(npc,2)
 check(npc.disabled,"Repair requires three seconds alongside")
 game.interactions.update_special(npc,1.1)
 check(not npc.disabled and not game.Combat.is_disabled(npc),"Repair restores armor above disable threshold")
 check(not npc.has("rescue_order"),"Completed assistance clears order")
 game.interactions.open_hail();game.interactions.offer_assistance()
 check(game.mode=="comms" and not npc.has("rescue_order"),"Operational ship politely declines redundant rescue")
 if "--visual" in OS.get_cmdline_user_args():
  await create_timer(.5).timeout
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev163-assistance.png")
 game.free();await process_frame
 print("OFFER ASSISTANCE: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
