extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-map-domination.json";game.controls.path="/tmp/ev-map-domination-controls.json"
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.set_mode("map");await process_frame
 var screen=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1);var chart=screen.chart
 var sol=129
 game.pilot.visited.append(sol);game.map_selected=sol
 game.pilot.reputation["128"]=-10000
 var normal=chart.system_color(sol)
 check(normal==Color("ff3030"),"Hostile undominated system retains original red")
 game.pilot.world_state.dominated=[128] # Earth
 check(chart.system_color(sol)==Color("00ff00"),"Tribute-paying Earth makes Sol green even with hostile Confederation standing")
 check(chart.dominated_worlds(sol)==["Earth"],"Map identifies actual dominated world")
 check(screen.details().legal=="Dominated" and screen.details().dominated==["Earth"],"Selected system details explain the green domination color")
 screen.refresh_details();chart.queue_redraw()
 check(game.save_game(false),"Domination can be saved")
 game.pilot.world_state.dominated=[];game.load_game()
 game.set_mode("map");await process_frame
 screen=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1);chart=screen.chart;game.map_selected=sol
 check(chart.system_color(sol)==Color("00ff00"),"Domination color survives pilot reload")
 game.pilot.visited.erase(sol);game.pilot.surveyed.erase(sol)
 check(sol in chart.known_systems() and screen.details().explored,"Known conquests remain visible even in older saves lacking exploration flags")
 game.pilot.world_state.dominated=[128,130] # Earth and Mars
 game.pilot.world_killer.destroyed.append(128)
 check(chart.system_color(sol)==Color("00ff00") and chart.dominated_worlds(sol)==["Mars"],"Other surviving tribute-paying world keeps system dominated")
 game.pilot.world_state.dominated=[128]
 check(chart.system_color(sol)!=Color("00ff00"),"Destroyed world's obsolete tribute state cannot mark a system dominated")
 game.pilot.world_killer.destroyed.clear();game.pilot.visited.append(sol);game.pilot.world_state.dominated=[]
 check(chart.system_color(sol)==normal,"Releasing last world restores normal legal color")
 game.pilot.world_state.dominated=[128];screen.refresh_details();chart.queue_redraw()
 if "--visual" in OS.get_cmdline_user_args():
  game.map_center=Vector2(game.catalog.system(sol).fields.xPos,game.catalog.system(sol).fields.yPos)
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev160-dominated-map.png")
 game.free();await process_frame
 print("MAP DOMINATION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
