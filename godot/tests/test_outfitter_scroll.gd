extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func settle():
 await process_frame;await process_frame;await process_frame
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-outfitter-scroll.json";game.controls.path="/tmp/ev-outfitter-scroll-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 game.pilot.credits=2000000;game.docked_id=128
 game.set_mode("shipyard");game.shipyard.buy(900)
 game.set_mode("outfitter");game.hud.selected_outfit=902;game.hud.rebuild_modal()
 await settle()
 var scroll=game.hud.modal_root.find_child("OutfitterScroll",true,false)
 scroll.scroll_vertical=10000
 var before=scroll.scroll_vertical
 check(before>0,"Equipment grid is scrolled to its lower items")
 check(game.outfitter.trade(902,true),"Buy a Sidewinder at the bottom of the grid")
 await settle()
 scroll=game.hud.modal_root.find_child("OutfitterScroll",true,false)
 check(scroll.scroll_vertical==before,"Buying preserves the scroll position after layout")
 check(game.hud.selected_outfit==902,"Buying keeps the same item selected")
 check(game.outfitter.trade(902,true),"Buy another of the same item")
 await settle()
 scroll=game.hud.modal_root.find_child("OutfitterScroll",true,false)
 check(scroll.scroll_vertical==before,"Repeated purchases keep the grid in place")
 check(game.outfitter.trade(902,false),"Sell a Sidewinder")
 await settle()
 scroll=game.hud.modal_root.find_child("OutfitterScroll",true,false)
 check(scroll.scroll_vertical==before,"Selling also preserves the scroll position")
 game.free();await process_frame
 print("OUTFITTER SCROLL: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
