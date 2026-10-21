extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-selected-fire.json";game.controls.path="/tmp/ev-selected-fire-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 game.pilot.ship_id=900;game.pilot.ship_fields=game.catalog.record("ships",900).fields.duplicate(true)
 game.pilot.outfits=game.Shipyard.stock_outfits(game.catalog,900);game.pilot.lasers=0;game.controls.preset(false)
 game.pilot.selected_weapon=901;game.cooldown=0
 var ammo=game.pilot.outfit_count(902)
 check(game.fire_trigger() and game.shots.back().weapon==901,"Default primary trigger fires selected Maverick Sidewinders")
 check(game.pilot.outfit_count(902)==ammo-1,"Firing selected Sidewinder consumes its ammunition")
 check(not game.shots.any(func(s):return int(s.weapon)==900),"Selecting Sidewinders does not secretly fire machine guns")
 game.pilot.selected_weapon=900;game.cooldown=0
 check(game.fire_trigger() and game.shots.back().weapon==900,"Selecting M61 switches the same trigger back to machine guns")
 game.cycle_weapon(1)
 check(game.pilot.selected_weapon==901,"Default weapon cycling switches between M61 and Sidewinder")
 game.pilot.selected_weapon=900
 var caption_screen=load("res://scripts/classic_flight_panel.gd").new();caption_screen.game=game
 check(caption_screen.weapon_caption().contains("M61"),"HUD names the selected M61 rather than pretending a secondary is selected")
 game.pilot.selected_weapon=901
 check(caption_screen.weapon_caption().contains("Sidewinder") and caption_screen.weapon_caption().contains(str(ammo-1)),"HUD shows the selected Sidewinder and current ammunition")
 caption_screen.free()
 var Controls=load("res://scripts/control_settings.gd");var restored=Controls.new();restored.path=game.controls.path;restored.load_settings()
 check(not restored.classic_fire,"Default selected-weapon behavior persists across preference reload")
 game.controls.preset(true);game.pilot.selected_weapon=901;game.primary_cooldowns.clear();game.cooldown=0
 ammo=game.pilot.outfit_count(902);var before=game.shots.size()
 check(game.fire_trigger() and game.shots.size()>before and game.shots.back().weapon==900,"Explicit Classic preset retains all-primary gun firing")
 check(game.pilot.outfit_count(902)==ammo,"Classic primary fire leaves selected secondary ammo untouched")
 restored.load_settings();check(restored.classic_fire,"Explicit Classic firing preference persists")
 game.controls.preset(false);game.cooldown=0
 check(game.fire_trigger() and game.shots.back().weapon==901,"Restoring remake defaults immediately restores selected Sidewinder firing")
 game.open_controls()
 var toggle=game.hud.modal_root.find_child("ClassicFiringToggle",true,false)
 toggle.button_pressed=true;restored.load_settings()
 check(game.controls.classic_fire and restored.classic_fire,"Actual Settings toggle enables and saves Classic firing")
 toggle.button_pressed=false;restored.load_settings()
 check(not game.controls.classic_fire and not restored.classic_fire,"Settings toggle restores and saves selected-weapon firing")
 game.free();await process_frame
 print("SELECTED FIRE: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
