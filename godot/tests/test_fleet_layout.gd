extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev175-fleet-layout.json";game.controls.path="/tmp/ev175-controls.json";game.traffic.enabled=false;game.muted=true
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.pilot.credits=23098300;game.pilot.fleet=[{"id":146}];game.load_system();game.docked_id=128;game.set_mode("dock");game.toggle_fleet_menu()
 for dimensions in [Vector2i(1440,900),Vector2i(900,650)]:
  root.size=dimensions
  for frame in 4: await process_frame
  var screen=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
  var scroll=screen.find_child("FleetRosterScroll",true,false)
  var ship=screen.find_child("FleetShip0",true,false)
  var take=ship.find_child("TakeCommand0",true,false)
  var release=ship.find_child("ReleaseShip0",true,false)
  var title=ship.find_child("FleetShipTitle",true,false)
  check(ship.size.y==94 and take.size.y==38 and release.size.y==38,"Ship actions retain compact height at %s" % dimensions)
  check(title.get_global_rect().end.x<take.get_global_rect().position.x and take.get_global_rect().end.x<release.get_global_rect().position.x,"Ship title and action buttons have separate columns")
  check(Rect2(Vector2.ZERO,ship.size).encloses(Rect2(release.position,release.size)),"Release button stays inside ship row")
  var repair=screen.find_child("RepairFleet",true,false);var leave=screen.find_child("FleetDone",true,false)
  check(repair.position.y>=scroll.position.y+scroll.size.y and leave.position.y>=scroll.position.y+scroll.size.y,"Footer controls stay outside scrolling list")
  var footer_rect: Rect2=leave.get_global_rect()
  check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(footer_rect),"Leave control fits small and normal window")
  var stored: Vector2=leave.position
  scroll.scroll_vertical=10000
  await process_frame
  check(leave.position==stored and repair.visible and not scroll.is_ancestor_of(leave),"Scrolling roster cannot hide or move footer controls")
  if "--visual" in OS.get_cmdline_user_args():
   scroll.scroll_vertical=0
   await create_timer(.25).timeout;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("/tmp/ev175-fleet-%d.png" % dimensions.x)
 game.fleet_service.takeover_candidate=game.escorts[0];game.hud.rebuild_modal()
 await process_frame
 var confirm=game.hud.modal_root.find_child("FleetTransferConfirmation",true,false)
 check(confirm!=null and confirm.find_child("ConfirmFlagshipTransfer",true,false).size.y==38,"Flagship confirmation has its own bounded block")
 game.fleet_service.takeover_candidate={};game.pilot.fleet=[]
 for i in 8: game.pilot.fleet.append({"id":146,"hired":i%2==1,"wage":1200,"command":"defend"})
 game.load_system();game.fleet_return_mode="dock";game.set_mode("fleet")
 for frame in 4: await process_frame
 var roster=game.hud.modal_root.find_child("FleetRoster",true,false)
 check(roster.get_children().filter(func(c):return str(c.name).begins_with("FleetShip")).size()==8,"Full fleet has eight independently sized ship rows")
 check(game.hud.modal_root.find_child("FleetRosterScroll",true,false).get_v_scroll_bar().max_value>302,"Large fleet scrolls instead of overflowing screen")
 game.free();await process_frame
 print("FLEET LAYOUT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
