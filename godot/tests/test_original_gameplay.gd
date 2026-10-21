extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-original-gameplay.json";game.controls.path="/tmp/ev-original-gameplay-controls.json"
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 game.pilot.lasers=2;game.pilot.outfits={"130":1,"133":1,"134":3};game.pilot.selected_weapon=132
 check(not game.arsenal.is_secondary(128) and not game.arsenal.is_secondary(130) and game.arsenal.is_secondary(129) and game.arsenal.is_secondary(132),"Recovered flag classifies primary and secondary weapons")
 check(game.fire_primary(),"Primary trigger works while a missile is selected")
 check(game.shots.filter(func(s):return s.weapon==128).size()==2 and game.shots.filter(func(s):return s.weapon==130).size()==1,"Every installed primary mount fires together")
 check(game.pilot.outfit_count(134)==3,"Primary trigger does not spend secondary ammunition")
 check(not game.fire_primary(),"Primary weapons enforce their own reload timers")
 game.primary_cooldowns[128]=0
 var before=game.shots.size();game.fire_primary()
 check(game.shots.size()==before+2,"Reloaded lasers can fire while proton cannon is still cooling down")
 game.cooldown=0
 check(game.fire_player() and game.pilot.outfit_count(134)==2,"Secondary can fire during primary cooldown")
 game.controls.classic_fire=true;game.cycle_weapon(1)
 check(game.arsenal.is_secondary(game.pilot.selected_weapon),"Weapon cycling skips primary guns")
 var key=InputEventKey.new();key.physical_keycode=KEY_R;key.pressed=true
 game._unhandled_key_input(key)
 check(game.secondary_safe,"Safety toggles from the real input handler")
 game.cooldown=0;game.pilot.selected_weapon=132
 check(not game.fire_player() and game.pilot.outfit_count(134)==2,"Safety prevents secondary discharge without consuming ammo")
 game._unhandled_key_input(key)
 check(not game.secondary_safe,"Safety can be disengaged")
 check(game.fire_player(),"Disengaging safety restores the secondary trigger")
 game.controls.preset(true)
 check(game.controls.bindings.next_weapon==[KEY_W] and game.controls.bindings.weapon_safety==[KEY_S] and game.controls.bindings.secondary_fire==[KEY_SHIFT] and game.controls.bindings.afterburner==[KEY_2],"Classic preset separates Shift secondary fire from afterburner")
 game.controls.preset(false)
 check(game.controls.bindings.secondary_fire==[KEY_CTRL] and game.controls.bindings.afterburner==[KEY_SHIFT],"Default keeps the existing afterburner control")
 game.pilot.ship_id=900;game.pilot.ship_fields=game.catalog.record("ships",900).fields.duplicate(true);game.pilot.lasers=0
 game.pilot.outfits={"138":1,"139":2};game.pilot.selected_weapon=146;game.cooldown=0
 check(game.fire_player() and game.escorts.size()==1 and game.pilot.outfit_count(139)==1,"Launching takes one fighter out of the bay inventory")
 var fighter=game.escorts[0]
 var shield_before=fighter.shield
 game.arsenal.fire(128,fighter.position+Vector2(100,0),-PI/2,true)
 game.update_shots(.15)
 check(fighter.shield<shield_before,"A live enemy projectile damages a deployed fighter")
 var damaged_shield=fighter.shield
 game.load_system(0.0)
 fighter=game.escorts[0]
 check(fighter.shield==damaged_shield and fighter.bay_ammo==139,"Warp preserves fighter damage and inventory ownership")
 check(game.save_game(false),"Saving with a fighter deployed succeeds")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(game.save_path));var restored=game.Pilot.new()
 check(restored.restore(saved,game.catalog) and restored.outfit_count(139)==1 and restored.fighter_sorties.size()==1,"Save preserves surviving fighter sortie separately from docked inventory")
 check(game.pilot.outfit_count(139)==1,"Saving does not duplicate live fighter inventory")
 fighter.erase("arrival_delay");fighter.erase("arrival_visual");fighter.model.show();fighter.position=game.pilot.position;fighter.velocity=game.velocity
 game.arsenal.recall_fighters();game.arsenal.update_escorts(.01)
 check(game.escorts.is_empty() and game.pilot.outfit_count(139)==2,"Recall docks the fighter and refunds exactly one craft")
 game.cooldown=0;game.fire_player();fighter=game.escorts[0]
 check(fighter.shield==float(game.catalog.field("ships",148,"Shield")),"Recovered fighter relaunches repaired and serviced")
 game.arsenal.damage_fighter(fighter,100000,100000)
 check(game.escorts.is_empty() and game.pilot.outfit_count(139)==1,"Destroyed fighters are lost rather than refunded")
 for i in game.arsenal.MAX_ESCORTS: game.arsenal.launch_escort(148,game.pilot.position,0)
 game.cooldown=0
 check(not game.fire_player() and game.pilot.outfit_count(139)==1 and game.escorts.size()==12,"Full flight wing rejects launch without replacing a fighter or spending inventory")
 game.arsenal.recover_all_fighters()
 game.pilot.cargo=[3,0,0,0,0,2];game.pilot.mission={"destination":128,"object":128}
 var mission=game.missions.offer(164,161);mission.qty=4;mission.picked=true
 game.pilot.campaign.active.append(mission)
 game.jettison_cargo(true)
 check(game.pilot.cargo==[0,0,0,0,0,0] and not game.pilot.mission.is_empty() and mission in game.pilot.campaign.active,"Ordinary-only jettison retains mission cargo")
 game.jettison_cargo(false)
 check(game.pilot.mission.is_empty() and mission not in game.pilot.campaign.active,"All-cargo jettison fails affected deliveries and frees their holds")
 check(game.missions.flight_alert.contains("jettisoned"),"Lost mission cargo explains why the mission failed")
 check(not game.advance_self_destruct(9,true) and game.mode=="flight","Self-destruct does not fire before ten real seconds")
 game.advance_self_destruct(0,false)
 check(game.self_destruct_seconds==0 and game.mode=="flight","Releasing keys cancels self-destruct")
 game.advance_self_destruct(4,true);game.set_mode("pause");game.set_mode("flight")
 check(game.self_destruct_seconds==0,"Opening a menu cancels the hold timer")
 game.pilot.system_id=game.missions.system_of(128);game.load_system();game.world_activity.contact_id=128;game.set_mode("world_comms")
 var service=game.world_activity;service.contact_id=128;game.pilot.reputation["128"]=-1000;game.pilot.credits=100000
 var officer=service.landing_officer(128);officer.willing=false
 var credits=game.pilot.credits
 check(not service.pay_landing_bribe() and game.pilot.credits==credits and not service.landing_reason(128).is_empty(),"Unwilling official refuses without taking money or granting access")
 check(service.landing_officer(128)==officer and officer.refused,"Reopening the same day's channel cannot reroll the official")
 game.pilot.campaign.day+=1
 officer=service.landing_officer(128);officer.willing=true;officer.bargains=true
 var full_price=service.landing_bribe_price(128)
 check(service.negotiate_landing_bribe() and service.landing_bribe_price(128)==int(int(full_price*.75)/100)*100,"Willing official can negotiate a lower quoted fee")
 var price=service.landing_bribe_price(128)
 check(not service.negotiate_landing_bribe() and service.landing_bribe_price(128)==price,"Repeated bargaining cannot compound discounts")
 check(service.pay_landing_bribe() and game.pilot.credits==credits-price and service.landing_reason(128).is_empty(),"Accepted negotiated payment grants real landing access")
 game.set_mode("flight");game.pilot.cheat_invincibility=true
 game.advance_self_destruct(9.99,true)
 check(game.mode=="flight","Self-destruct still waits for the final instant")
 check(game.advance_self_destruct(.01,true) and game.mode=="dead","Ten-second voluntary self-destruct works even with invincibility enabled")
 game.free();await process_frame
 print("ORIGINAL GAMEPLAY: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
