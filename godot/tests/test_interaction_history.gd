extends SceneTree
const History=preload("res://scripts/interaction_history.gd")
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-history-tests.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.pilot.interaction_history=History.fresh()
 var pilot=game.pilot
 var a={"id":128};var b={"id":128}
 var first=History.pilot_key(pilot,a)
 check(first==History.pilot_key(pilot,a),"same pilot retains identity")
 check(first!=History.pilot_key(pilot,b),"identical hulls do not share memories")
 check(History.pilot_key(pilot,{"person_id":128})==History.pilot_key(pilot,{"person_id":128}),"named pilot identity survives encounter respawn")
 for action in History.ACTIONS:
  History.record(pilot,"world:193",action)
  History.record(pilot,"world:193",action)
  check(History.count(pilot,"world:193",action)==2,"action counts independently: "+action)
 check(History.count(pilot,"world:129","boarded")==0,"separate targets have independent history")
 check(History.recollection(pilot,"world:193").contains("2"),"repeat dialogue includes action count")
 var copy=game.Pilot.new()
 check(copy.restore(JSON.parse_string(JSON.stringify(pilot.snapshot())),game.catalog),"history survives JSON save reload")
 check(copy.interaction_history==pilot.interaction_history,"all counters preserved by reload")
 var legacy=pilot.snapshot();legacy.erase("interaction_history")
 check(copy.restore(legacy,game.catalog) and copy.interaction_history==History.fresh(),"legacy saves start with empty history")
 var bad=pilot.snapshot();bad.interaction_history.contacts["world:193"].counts.boarded=-1
 check(not copy.restore(bad,game.catalog),"invalid negative count rejected")
 bad=pilot.snapshot();bad.interaction_history.contacts["world:193"].counts.boarded=1.5
 check(not copy.restore(bad,game.catalog),"fractional counters rejected")
 # Exercise actual world hails and threats rather than only the storage API.
 pilot.interaction_history=History.fresh();pilot.system_id=163;game.load_system();game.set_mode("flight");game.landing_target=193
 game.world_activity.open_contact()
 check(History.count(pilot,"world:193","hail")==1,"world hail records action")
 game.set_mode("flight");game.world_activity.open_contact()
 check(game.world_activity.response.contains("again"),"repeat world hail changes response")
 game.world_killer.threaten()
 check(History.count(pilot,"world:193","threatened")==1,"successful threat records once")
 game.save_game(false);game.load_game()
 check(History.count(game.pilot,"world:193","threatened")==1,"action persists through actual save/load")
 game.set_mode("flight")
 var npc=game.traffic.spawn(131,128,0,game.pilot.position+Vector2(0,80))
 game.target_index=game.npcs.find(npc);game.interactions.open_hail()
 var key: String=History.pilot_key(game.pilot,npc)
 game.interactions.request_assistance();game.interactions.request_assistance()
 check(History.count(game.pilot,key,"assistance_requested")==2,"actual assistance requests increment independently")
 game.interactions.offer_bribe()
 check(History.count(game.pilot,key,"bribe_offered")==1 and History.count(game.pilot,key,"bribe_paid")==0,"offering a refused bribe does not count as paying")
 game.set_mode("flight");game.interactions.open_hail()
 check(game.interactions.response.contains("assistance 2 times"),"repeat pilot greeting recalls request count")
 check(History.count(game.pilot,key,"hail")==2,"same live captain keeps its hail counter")
 game.free();await process_frame
 print("INTERACTION HISTORY: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
