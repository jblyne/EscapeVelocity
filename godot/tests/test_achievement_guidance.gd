extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev173-guidance.json";game.controls.path="/tmp/ev173-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false);game.pilot=game.Pilot.new()
 var before: Dictionary=game.pilot.snapshot().duplicate(true)
 for badge in game.achievements.badges():
  var text: String=game.achievements.next_steps(badge.id)
  check(text.length()>60 and text!=badge.description,"Concrete next steps for "+str(badge.id))
  if "--dump" in OS.get_cmdline_user_args(): print(badge.id+": "+text)
 check(game.pilot.snapshot()==before,"Reading badge guidance never modifies pilot progress or triggers offers")
 check(game.achievements.next_steps("story_hunters").contains("8000"),"Locked story explains its exact combat requirement")
 game.pilot.campaign.bits=[44]
 check(game.achievements.next_steps("experimental").contains("Transport Rebel Parcels")==false and game.achievements.next_steps("experimental").contains("Next milestone"),"Technology badge follows prerequisites toward actual equipment grant")
 game.pilot.campaign.bits=[]
 var lead: String=game.achievements.next_steps("story_environment")
 check(lead.contains("Bar") and lead.contains("system") and lead.contains("Investigate"),"Story starter names actual contact channel, system and mission")
 game.pilot.campaign.completed=[236];game.pilot.campaign.bits=[108]
 lead=game.achievements.next_steps("story_hunters")
 check(lead.contains("Retrieve Data") and not lead.contains("Next milestone: Ferry"),"Partially completed bounty chain points to next actual milestone")
 var mission: Dictionary=game.missions.offer(237,144);game.pilot.campaign.active=[mission]
 lead=game.achievements.next_steps("story_hunters")
 check(lead.contains(game.missions.next_objective(mission)),"Accepted story uses live next objective")
 game.pilot.campaign.bits=[44,108];game.pilot.campaign.active=[]
 lead=game.achievements.next_steps("war_hero")
 check(not lead.contains("CONFEDERATION\n") and lead.contains("Next milestone"),"Military guidance respects chosen Rebel path")
 game.pilot.campaign.rating=400
 check(game.achievements.next_steps("combat_1500").contains("1100 more"),"Combat guidance reports exact remaining rating")
 game.pilot.achievements.earned["combat_1500"]=0
 check(game.achievements.next_steps("combat_1500").contains("Badge complete"),"Earned badge never gives obsolete work")
 game.set_mode("pause");game.open_achievements()
 var card=game.hud.modal_root.find_child("Badge_story_hunters",true,false)
 check(card is Button and not card.disabled,"Incomplete badge is an interactive button")
 var scroll=game.hud.modal_root.find_child("BadgeCollection",true,false)
 await process_frame
 scroll.scroll_vertical=160
 var previous: int=scroll.scroll_vertical
 card.pressed.emit()
 var details=game.hud.modal_root.find_child("BadgeNextSteps",true,false)
 check(details is RichTextLabel and details.text.contains("Retrieve Data") and not scroll.visible,"Clicking badge shows its specific next steps in scrollable detail view")
 if "--visual" in OS.get_cmdline_user_args():
  await create_timer(.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev173-badge-details.png")
 game.hud.modal_root.find_child("BadgeDetailsBack",true,false).pressed.emit()
 check(scroll.visible and scroll.scroll_vertical==previous,"Back preserves collection scroll position")
 var guidance: Dictionary=game.achievements.guidance("story_hunters")
 var sirius: int=game.missions.system_of(144)
 check(guidance.destinations==[sirius],"Bounty guidance carries the actual Sirius contact system")
 card.pressed.emit()
 var jump=game.hud.modal_root.find_child("BadgeJump_"+str(sirius),true,false)
 check(jump is Button and jump.text.contains("Sirius"),"Guidance has a destination jump button")
 game.pilot.position=Vector2(100000,100000);game.pilot.fuel=1000
 game.pilot.cheat_chain_jump=true
 jump.pressed.emit()
 check(game.mode=="flight" and game.hyperdrive.active(),"Button exits achievements and begins normal hyperspace")
 check(game.destination==sirius and not game.chain_route.is_empty(),"Button selects Sirius and queues the route")
 game.cancel_jump(false)
 game.pilot.cheat_chain_jump=false;game.pilot.fuel=0
 var adjacent: int=int(game.catalog.system(game.pilot.system_id).links[0])
 game.achievements.jump_to_guidance(adjacent)
 check(game.mode=="flight" and not game.hyperdrive.active() and game.destination==adjacent,"Insufficient fuel preserves selected target without bypassing normal restrictions")
 game.achievements.jump_to_guidance(game.pilot.system_id)
 check(not game.hyperdrive.active(),"Local guidance never starts a jump to itself")
 game.free();await process_frame
 print("ACHIEVEMENT GUIDANCE: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
