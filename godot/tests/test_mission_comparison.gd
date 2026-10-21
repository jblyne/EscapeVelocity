extends SceneTree
const Comparison=preload("res://scripts/mission_comparison.gd")
class Graph:
	extends RefCounted
	var systems={1:{"links":[2,4]},2:{"links":[3]},3:{"links":[]},4:{"links":[3]},5:{"links":[]}}
	func system(id: int) -> Dictionary: return systems.get(id,{})
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var graph=Graph.new()
	check(Comparison.jumps(graph,1,1)==0,"Same system is zero jumps")
	check(Comparison.jumps(graph,1,2)==1,"Adjacent system is one jump")
	check(Comparison.jumps(graph,1,3)==2,"Distance follows shortest connected route")
	check(Comparison.jumps(graph,1,5)==-1,"Disconnected destination never becomes a cheat shortcut")
	check(Comparison.jumps(graph,1,-1)==-1,"Unknown objectives have unknown distance")
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-mission-comparison-pilot.json";game.controls.path="/tmp/ev-mission-comparison-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.pilot.system_id=129;game.load_system();game.docked_id=128;game.set_mode("dock");game.missions.channel=0;game.missions.last_report="";game.missions.open()
	var ui=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	check(not ui.entries.is_empty() and ui.mission_list.get_item_text(0).contains(" · "),"Mission rows include comparison indicators")
	check(ui.comparisons.any(func(info):return info.jumps==ui.nearest),"Closest badge derives from actual available offers")
	ui.select_entry(ui.entries.size()-1);var selected: Dictionary=ui.entries.back()
	ui.sort_nearest()
	var previous: int=-1;var ordered: bool=true
	for entry in ui.entries:
		var count: int=Comparison.info(game,entry).jumps
		if count<0: count=2147483647
		if count<previous: ordered=false
		previous=count
	check(ordered,"Nearest sort orders by actual jump count")
	check(ui.entries[ui.selected_index]==selected,"Sorting preserves selected mission identity")
	check(ui.detail.find_child("MissionDistance",true,false)!=null and ui.detail.find_child("MissionTerms",true,false)!=null,"Selected mission shows distance and terms")
	ui.sort_nearest();check(ui.entries==ui.original_entries,"Original mission ordering can be restored")
	game.pilot.mission={"system":129,"object":128,"reward":1200}
	check(game.missions.landing_markers().has(128),"Courier marks the exact current-system landing port")
	game.pilot.mission={}
	check(game.missions.landing_markers().is_empty(),"Completed courier removes its landing marker")
	var sample: Dictionary={}
	for record in game.catalog.data.missions.values():
		if int(record.fields.ShipCount)<=0 or int(record.fields.ShipGoal)<0:
			sample=game.missions.offer(int(record.id),128);break
	sample.dest=128;sample.back=-1;sample.travel_done=false
	game.pilot.campaign.active=[sample]
	check(game.missions.landing_markers().has(128),"Active original mission marks its destination planet or station")
	sample.travel_done=true;sample.back=129
	check(not game.missions.landing_markers().has(128),"Finished travel stop switches away from the delivered destination")
	game.pilot.campaign.active=[]
	check(game.missions.landing_markers().is_empty(),"Finished original missions leave no markers")
	game.free();await process_frame
	print("MISSION COMPARISON: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
