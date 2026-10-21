extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev171-emp.json";game.controls.path="/tmp/ev171-controls.json";game.traffic.enabled=false;game.muted=true
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false);game.set_mode("flight")
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 check(903 not in game.arsenal.available_ids() and not game.arsenal.fire(903,Vector2.ZERO,0),"Other ships cannot select or fire EMP")
 game.pilot.cheat_all_weapons=true
 check(903 not in game.arsenal.available_ids(),"All-weapons cheat does not bypass F-14 exclusivity")
 game.pilot.cheat_all_weapons=false;game.pilot.ship_id=900;game.pilot.ship_fields=game.catalog.record("ships",900).fields.duplicate(true)
 check(903 in game.arsenal.available_ids(),"Existing F-14 gains built-in disruptor without outfitting")
 game.pilot.position=Vector2(12000,12000);game.pilot.heading=0;game.velocity=Vector2.ZERO;game.pilot.selected_weapon=903;game.cooldown=0
 var npc=game.traffic.spawn(130,130,1,game.pilot.position+Vector2(0,-400));npc.velocity=Vector2.ZERO
 game.Combat.sync(npc)
 game.target_index=game.npcs.find(npc)
 var health: float=npc.health;var shield: float=npc.shield;var armor: float=npc.armor;var cargo=npc.cargo.duplicate();var outfits=game.pilot.outfits.duplicate()
 check(game.fire_player(),"Selected EMP fires through normal player controls")
 check(is_equal_approx(game.cooldown,2) and not game.fire_player(),"EMP enforces two-second recharge")
 check(game.pilot.outfits==outfits,"EMP requires no consumable ammunition")
 for i in 120:
  game.update_shots(1.0/60)
  if npc.disabled: break
 check(npc.disabled and npc in game.npcs,"Real guided projectile disables target on impact")
 check(npc.health==health and npc.shield==shield and npc.armor==armor and npc.cargo==cargo,"EMP preserves shields, hull, and salvage cargo")
 game.damage_npc(npc,0,{},Vector2.ZERO,false,0,903)
 check(npc in game.npcs and npc.health==health,"Repeated EMP hits never destroy disabled target")
 game.pilot.position=npc.position;game.pilot.heading=npc.heading;game.velocity=npc.velocity
 check(game.interactions.board(),"EMP-disabled ship can be boarded at full hull strength")
 game.set_mode("flight")
 var immune=game.traffic.spawn(130,130,1,game.pilot.position+Vector2(800,0));immune.invulnerable=true
 game.damage_npc(immune,0,{},Vector2.ZERO,false,0,903)
 check(not immune.disabled,"Invulnerability remains respected")
 game.pilot.selected_weapon=903
 check(game.save_game(false) and game.Pilot.new().restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog),"EMP selection remains compatible with pilot saves")
 game.free();await process_frame
 print("EMP DISRUPTOR: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
