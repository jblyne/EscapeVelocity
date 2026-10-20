extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-scan-test.json";game.controls.path="/tmp/ev-scan-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 var missions=game.missions
 var fields: Dictionary=game.catalog.record("missions",132).fields
 var scanner={"ai":3,"faction":128,"health":100,"disabled":false,"position":game.pilot.position+Vector2(180,180)}
 check(missions.can_scan(scanner,fields),"original per-axis range includes diagonal boundary")
 scanner.position=game.pilot.position+Vector2(180.1,0)
 check(not missions.can_scan(scanner,fields),"scanner outside original 180-unit axis range cannot detect cargo")
 scanner.position=game.pilot.position
 scanner.faction=129;check(not missions.can_scan(scanner,fields),"enemy government cannot enforce another government's illegal cargo")
 scanner.faction=145;check(not missions.can_scan(scanner,fields),"related government is not substituted for mission's exact scanner government")
 scanner.faction=128
 for ai in [0,1,2,5,6]:
  scanner.ai=ai;check(not missions.can_scan(scanner,fields),"non-patrol AI cannot scan: "+str(ai))
 scanner.ai=4;check(missions.can_scan(scanner,fields),"second original patrol AI may scan")
 scanner.disabled=true;check(not missions.can_scan(scanner,fields),"disabled patrol cannot scan");scanner.disabled=false
 for flag in ["fleet_uid","player_ally","mission_escort","departure"]:
  scanner[flag]=1 if flag=="fleet_uid" else true
  check(not missions.can_scan(scanner,fields),"owned/protected/departing contact cannot scan: "+flag);scanner.erase(flag)
 var old: int=int(game.catalog.data.governments["128"].fields.SmugPenalty)
 game.catalog.data.governments["128"].fields.SmugPenalty=0
 check(not missions.can_scan(scanner,fields),"government with no smuggling enforcement does not scan")
 game.catalog.data.governments["128"].fields.SmugPenalty=old
 var cargo: Dictionary=missions.offer(132,128);game.pilot.campaign.active=[cargo];game.npcs.clear();game.npcs.append(scanner)
 game.pilot.reputation["128"]=0;game.cloak.active=true;missions.scan_missions()
 check(game.pilot.reputation["128"]==0,"cloaking prevents cargo detection")
 game.cloak.active=false;game.set_mode("pause");missions.scan_missions()
 check(game.pilot.reputation["128"]==0,"paused play cannot trigger a scan")
 game.set_mode("flight");cargo.picked=false;missions.scan_missions()
 check(game.pilot.reputation["128"]==0,"cargo not picked up cannot be detected")
 cargo.picked=true;cargo.delivered=true;missions.scan_missions()
 check(game.pilot.reputation["128"]==0,"delivered cargo cannot be detected")
 cargo.delivered=false;missions.scan_missions()
 check(game.pilot.reputation["128"]==-3 and cargo in game.pilot.campaign.active,"actual source SmugPenalty applies without failing nonfatal mission")
 missions.scan_missions();check(game.pilot.reputation["128"]==-3,"same patrol cannot repeatedly penalize the same mission")
 var extra: Dictionary=missions.offer(131,128);extra.picked=true;game.pilot.campaign.active=[cargo,extra]
 scanner.erase("scanned_mission_132");game.pilot.reputation["128"]=0;missions.scan_missions()
 check(game.pilot.reputation["128"]==-3 and not scanner.has("scanned_mission_131"),"one patrol handles only one illegal cargo per scan opportunity")
 missions.scan_missions();check(game.pilot.reputation["128"]==-6,"other illegal cargo can be detected on a subsequent opportunity")
 var fatal: Dictionary=missions.offer(134,128);fatal.picked=true;game.pilot.campaign.active=[fatal] # Cargo has been recovered from the mission ship.
 # A real contact also covers mission-failure save/sync callbacks.
 game.npcs.clear();var patrol: Dictionary=game.traffic.spawn(134,128,3,game.pilot.position)
 game.pilot.reputation["128"]=0;missions.scan_missions()
 check(fatal not in game.pilot.campaign.active and game.pilot.reputation["128"]==-3,"scan-abort mission fails through normal mission flow exactly once")
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(game.save_path));var restored=game.Pilot.new()
 check(restored.restore(parsed,game.catalog) and restored.campaign.active.is_empty(),"scan failure and legal penalty survive disk reload")
 game.npcs.erase(patrol);game.pilot.campaign.active=[];missions.scan_clock=4.9;missions.advance(.3)
 check(is_equal_approx(missions.scan_clock,.2),"scan scheduler retains fractional time across frame boundaries")
 game.load_system();check(missions.scan_clock==0,"new system resets previous encounter's scan phase")
 missions.scan_clock=4.9;game.traffic.refresh_after_landing()
 check(missions.scan_clock==0,"fresh launch traffic resets scan phase instead of inheriting a near-finished scan")
 game.free();await process_frame
 print("CARGO SCANS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
