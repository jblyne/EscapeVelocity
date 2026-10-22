extends SceneTree
var game
var pad
var failures=0
func check(ok: bool,message: String):
 if not ok: failures+=1;push_error(message)
func axis(id: int,value: float):
 var event=InputEventJoypadMotion.new();event.device=0;event.axis=id;event.axis_value=value;pad._input(event)
func button(id: int,down: bool=true):
 var event=InputEventJoypadButton.new();event.device=0;event.button_index=id;event.pressed=down;pad._input(event)
 Input.flush_buffered_events()
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev217-controller.json";game.controls.path="/tmp/ev217-controller-preferences.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 pad=game.controls.controller;pad.set_process(false)
 game.set_mode("flight");pad._process(0)
 axis(JOY_AXIS_LEFT_X,.1);check(not game.controls.pressed("right") and is_zero_approx(game.controls.turn()),"Stick drift stays inside dead zone")
 axis(JOY_AXIS_LEFT_X,.61);check(game.controls.turn()>.4 and game.controls.turn()<.6,"Steering retains analog strength")
 var heading: float=game.pilot.heading
 game._physics_process(.1);check(absf(angle_difference(heading,game.pilot.heading))>0,"Controller steering reaches flight simulation")
 axis(JOY_AXIS_LEFT_X,0)
 axis(JOY_AXIS_LEFT_Y,-.8);check(game.controls.pressed("thrust"),"Left stick forward thrusts")
 axis(JOY_AXIS_LEFT_Y,.8);check(game.controls.pressed("retrograde") and not game.controls.pressed("thrust"),"Left stick down faces against drift")
 axis(JOY_AXIS_TRIGGER_RIGHT,.9);check(game.controls.pressed("fire"),"R2 holds selected weapon fire")
 axis(JOY_AXIS_TRIGGER_LEFT,.9);check(game.controls.pressed("secondary_fire"),"L2 holds secondary fire")
 button(JOY_BUTTON_LEFT_STICK);check(game.controls.pressed("afterburner"),"L3 supplies afterburner modifier")
 button(JOY_BUTTON_LEFT_STICK,false);check(not game.controls.pressed("afterburner"),"Release clears held button")
 pad.connection_changed(0,false)
 check(not game.controls.pressed("fire") and is_zero_approx(game.controls.turn()),"Disconnect releases all axes and buttons")
 axis(JOY_AXIS_TRIGGER_RIGHT,.9);pad._notification(pad.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not game.controls.pressed("fire"),"Focus loss cannot leave firing stuck")
 button(JOY_BUTTON_START);await process_frame
 check(game.mode=="pause","Options opens pause")
 pad._process(0);check(not game.controls.pressed("fire"),"Held flight inputs never fire in menus")
 button(JOY_BUTTON_DPAD_DOWN);check(is_instance_valid(pad.selected) and pad.selected.name=="ResumeFlight","D-pad selects visible pause buttons")
 button(JOY_BUTTON_A);await process_frame
 check(game.mode=="flight","Cross activates Resume Flight")
 if DisplayServer.get_name()!="headless":
  button(JOY_BUTTON_START);await create_timer(.25).timeout
  pad.selected=null;pad.cursor=game.hud.modal_root.find_child("ResumeFlight",true,false).get_global_rect().get_center()
  button(JOY_BUTTON_A);await process_frame;await process_frame
  check(game.mode=="flight","Controller pointer clicks existing menu buttons")
 button(JOY_BUTTON_DPAD_DOWN);check(game.landing_target==int(game.planets[0].id),"D-pad down selects landing world")
 game.pilot.system_id=129;game.load_system();game.select_landing_target(0)
 var first_world: int=game.landing_target
 button(JOY_BUTTON_A)
 check(pad.land_pending and game.mode=="flight","Holding Cross waits for tap or target-switch gesture")
 axis(JOY_AXIS_LEFT_X,.9)
 check(is_zero_approx(game.controls.turn()) and not game.controls.pressed("right"),"Landing modifier suppresses controller steering")
 axis(JOY_AXIS_LEFT_Y,-.9)
 check(not game.controls.pressed("thrust"),"Landing modifier suppresses controller thrust")
 axis(JOY_AXIS_LEFT_Y,0)
 var second_world: int=game.landing_target
 check(second_world==int(game.planets[1].id),"Hold Cross and right flick selects next landing target")
 axis(JOY_AXIS_LEFT_X,.95)
 check(game.landing_target==second_world,"Held stick cannot race through targets")
 axis(JOY_AXIS_LEFT_X,0);axis(JOY_AXIS_LEFT_X,-.9)
 check(game.landing_target==first_world,"Neutral then left flick selects previous landing target")
 button(JOY_BUTTON_A,false)
 check(game.mode=="flight" and not game.auto_landing and game.last_land_tap==-1000,"Release after cycling never requests or auto-starts landing")
 axis(JOY_AXIS_LEFT_X,0)
 game.pilot.position=Vector2(18000,18000);game.landing_clearance=-1
 button(JOY_BUTTON_A);button(JOY_BUTTON_A,false)
 check(game.last_land_tap>=0,"Ordinary Cross tap still requests landing")
 button(JOY_BUTTON_A);button(JOY_BUTTON_A,false)
 check(game.auto_landing,"Double-tap Cross still starts auto-landing")
 game.auto_landing=false;game.last_land_tap=-1000
 game.controls.bindings.map=[KEY_Z]
 button(JOY_BUTTON_DPAD_RIGHT);await process_frame
 check(game.mode=="map","Controller map command honors remapped keyboard bindings")
 var chart=pad.map_chart()
 game.pilot.visited=game.catalog.data.systems.keys().map(func(id):return int(id))
 game.map_route.clear();game.destination=-1;pad._process(0)
 var before_center: Vector2=game.map_center;var before_zoom: float=game.map_zoom
 axis(JOY_AXIS_RIGHT_X,.8);axis(JOY_AXIS_RIGHT_Y,-.7);pad._process(.2)
 check(game.map_center.x>before_center.x and game.map_center.y<before_center.y and game.map_zoom==before_zoom,"Right stick pans in both axes without scrolling zoom")
 axis(JOY_AXIS_RIGHT_X,0);axis(JOY_AXIS_RIGHT_Y,0)
 var target: int=141
 var fields: Dictionary=game.catalog.system(target).fields
 game.map_center=Vector2(fields.xPos,fields.yPos);chart.rebuild_locations()
 pad.cursor=chart.get_global_transform()*Vector2(chart.locations[target]);pad.selected=null
 button(JOY_BUTTON_A)
 check(game.map_selected==target and game.map_route.is_empty(),"Cross inspects map point without changing planned jumps")
 button(JOY_BUTTON_X)
 var planned: Array=game.autopilot.path(game.pilot.system_id,target)
 check(planned.size()>1 and game.map_route==planned and game.destination==int(planned.front()),"Square builds connected multi-jump route to selected system")
 if "--visual" in OS.get_cmdline_user_args():
  await create_timer(.25).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev218-controller-route.png")
 var extension: int=int(game.catalog.system(target).links[0]);game.map_selected=extension
 button(JOY_BUTTON_X)
 planned.append_array(game.autopilot.path(target,extension))
 check(game.map_route==planned,"Square appends from previous endpoint instead of replacing route")
 var preserved: Array=game.map_route.duplicate()
 game.map_center=Vector2(fields.xPos,fields.yPos);chart.rebuild_locations();pad.cursor=chart.get_global_transform()*Vector2(chart.locations[target])
 button(JOY_BUTTON_A)
 check(game.map_route==preserved,"Selecting another point preserves multi-jump plan")
 game.map_route.clear();game.pilot.cheat_chain_jump=true;game.map_selected=target
 button(JOY_BUTTON_X)
 check(game.map_route==game.autopilot.path(game.pilot.system_id,target) and game.destination==target,"Chain jumping uses the full route and final destination")
 game.pilot.cheat_chain_jump=false
 button(JOY_BUTTON_B);await process_frame
 check(game.mode=="flight","Circle returns from map")
 game.set_mode("controls");await process_frame
 check(game.hud.modal_root.find_child("ControllerHelp",true,false)!=null,"Controls screen includes PS5 layout")
 if "--visual" in OS.get_cmdline_user_args():
  await create_timer(.3).timeout
  var help=game.hud.modal_root.find_child("ControllerHelp",true,false)
  help.get_parent().get_parent().get_parent().ensure_control_visible(help)
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev217-controller-help.png")
 print("Connected controllers: ",Input.get_connected_joypads())
 game.free();await process_frame
 print("CONTROLLER: %d failures" % failures);quit(1 if failures else 0)
