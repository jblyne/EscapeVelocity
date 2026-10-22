extends SceneTree
var game
var failures=0
func check(ok: bool,message: String):
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev220-navigation.json";game.controls.path="/tmp/ev220-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 var pad=game.controls.controller;pad.set_process(false);pad.set_process_input(false)
 game.set_mode("pause");pad.last_mode=game.mode;pad.using_pad=true
 for child in game.hud.modal_root.get_children(): child.hide()
 var scroll=ScrollContainer.new();scroll.position=Vector2(100,100);scroll.size=Vector2(340,210);game.hud.modal_root.add_child(scroll)
 var grid=GridContainer.new();grid.columns=3;scroll.add_child(grid)
 var cells: Array=[]
 for i in 30:
  var cell=Button.new();cell.text=str(i);cell.custom_minimum_size=Vector2(104,80);grid.add_child(cell);cells.append(cell)
 await process_frame;await process_frame
 pad.selected=cells[0]
 pad.navigate_menu(JOY_BUTTON_DPAD_RIGHT);check(pad.selected==cells[1],"Right stays on the same grid row")
 pad.navigate_menu(JOY_BUTTON_DPAD_DOWN);check(pad.selected==cells[4],"Down selects the next row in the same column")
 pad.navigate_menu(JOY_BUTTON_DPAD_LEFT);check(pad.selected==cells[3],"Left stays on the same row")
 pad.navigate_menu(JOY_BUTTON_DPAD_UP);check(pad.selected==cells[0],"Up selects the previous row in the same column")
 pad.navigate_menu(JOY_BUTTON_DPAD_LEFT);check(pad.selected==cells[0],"Left at edge never wraps to another row")
 pad.buttons[JOY_BUTTON_DPAD_DOWN]=true;pad.repeat_button=JOY_BUTTON_DPAD_DOWN;pad.repeat_remaining=pad.DPAD_DELAY
 pad.advance_repeat(.2);pad.advance_repeat(.14)
 check(pad.selected==cells[0],"Held D-pad waits before repeating")
 pad.advance_repeat(.02)
 check(pad.selected==cells[3],"Held D-pad repeats after initial delay")
 pad.advance_repeat(.1)
 check(pad.selected==cells[6],"Held D-pad repeats steadily in the same column")
 pad.buttons[JOY_BUTTON_DPAD_DOWN]=false;pad.advance_repeat(.2)
 check(pad.selected==cells[6] and pad.repeat_button==-1,"Releasing D-pad stops repeat immediately")
 pad.selected=cells[0]
 for row in 9:
  pad.navigate_menu(JOY_BUTTON_DPAD_DOWN);await process_frame
 check(pad.selected==cells[27] and scroll.scroll_vertical>0,"D-pad scrolls down to the final grid row")
 var shown: Rect2=pad.visible_rect(pad.selected)
 check(shown.has_area() and shown.size.y>=pad.selected.get_global_rect().size.y-2,"Selected card is fully visible inside scroll viewport")
 for row in 9:
  pad.navigate_menu(JOY_BUTTON_DPAD_UP);await process_frame
 check(pad.selected==cells[0] and scroll.scroll_vertical==0,"Up scrolls back to the first row")
 pad.cursor=Vector2(900,800);pad.selected=cells[0];pad.scroll_menu(1,.2)
 check(scroll.scroll_vertical>0,"Right-stick scrolling follows selected list even when pointer is elsewhere")
 check(not pad.visible_rect(cells[29]).has_area(),"Offscreen focus outlines are clipped to scroll viewport")
 var list=ItemList.new();list.position=Vector2(500,100);list.size=Vector2(200,120);game.hud.modal_root.add_child(list)
 for i in 40: list.add_item("Mission %d" % i)
 list.select(0);pad.selected=list
 await process_frame
 for i in 30: pad.navigate_menu(JOY_BUTTON_DPAD_DOWN)
 await process_frame;await process_frame
 check(list.get_selected_items()[0]==30 and list.get_v_scroll_bar().value>0,"Mission/ship-style lists advance and scroll their internal selection")
 var text=RichTextLabel.new();text.position=Vector2(500,300);text.size=Vector2(200,120);text.text="Mission details\n".repeat(80);game.hud.modal_root.add_child(text)
 await process_frame;await process_frame
 pad.selected=text;pad.navigate_menu(JOY_BUTTON_DPAD_DOWN)
 check(text.get_v_scroll_bar().value>0,"D-pad scrolls long text panels")
 list.queue_free();text.queue_free()
 scroll.queue_free();await process_frame
 # Exercise actual scrolling menus through the same shared controller path.
 for screen in ["outfitter","shipyard","achievements"]:
  game.docked_id=128;game.set_mode(screen);pad.last_mode=game.mode;pad.selected=null
  await process_frame;await process_frame
  var choices: Array=[];pad.collect_buttons(pad.menu_scope(),choices)
  var first
  for candidate in choices:
   if pad.scroll_parent(candidate)!=null or candidate is ItemList: first=candidate;break
  check(is_instance_valid(first),screen+" exposes scrollable choices")
  if not is_instance_valid(first): continue
  pad.selected=first
  if screen=="outfitter":
   var card=game.hud.modal_root.find_child("SelectOutfit141",true,false)
   check(is_instance_valid(card),"Outfitter has a noninitial equipment card")
   pad.selected=card
   pad.menu_button(JOY_BUTTON_A)
   check(pad.selected==card,"Activating equipment immediately keeps focus on its green selection")
   pad.navigate_menu(JOY_BUTTON_DPAD_RIGHT)
   check(is_instance_valid(pad.selected) and pad.selected.name=="SelectOutfit142","Next D-pad direction continues from selected equipment, without waiting a frame")
   pad.selected=first
  for step in 20:
   pad.navigate_menu(JOY_BUTTON_DPAD_DOWN);await process_frame
   check(pad.visible_rect(pad.selected).has_area(),screen+" keeps D-pad selection within visible clipped area")
  if screen=="outfitter" and "--visual" in OS.get_cmdline_user_args():
   await create_timer(.25).timeout;pad.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("/tmp/ev220-outfitter-navigation.png")
 game.set_mode("pause");pad.last_mode=game.mode;pad.using_pad=true
 pad.selected=game.hud.modal_root.find_child("KeyboardControls",true,false)
 pad.menu_button(JOY_BUTTON_A);await process_frame;pad._process(0)
 check(game.mode=="controls","D-pad focused button opens controls")
 game.set_mode("pause");pad._process(0);await process_frame
 check(is_instance_valid(pad.selected) and pad.selected.name=="KeyboardControls","Closing child screen restores rebuilt launcher button")
 game.open_achievements();pad._process(0);await process_frame;await process_frame
 var badge=game.hud.modal_root.find_child("Badge_story_hunters",true,false)
 pad.selected=badge;pad.reveal(badge)
 pad.menu_button(JOY_BUTTON_A);await process_frame;pad._process(0)
 check(not badge.is_visible_in_tree(),"Badge opens same-mode detail view")
 pad.selected=game.hud.modal_root.find_child("BadgeDetailsBack",true,false)
 pad.menu_button(JOY_BUTTON_A);await process_frame;pad._process(0)
 check(pad.selected==badge and pad.visible_rect(badge).has_area(),"Closing same-screen details restores launcher and its scroll visibility")
 game.free();await process_frame
 print("CONTROLLER NAVIGATION: %d failures" % failures);quit(1 if failures else 0)
