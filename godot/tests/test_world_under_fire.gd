extends SceneTree
var game
var k
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func deploy(id: int) -> void:
	game.pilot.system_id=game.missions.system_of(id);game.load_system();game.set_mode("flight")
	for npc in game.npcs.duplicate(): game.traffic.retire(npc)
	game.environment_hazards.rocks=[]
	game.landing_target=id;game.pilot.position=k.target_position(id)+Vector2(k.target_radius(id)+150,0)
	game.world_activity.open_contact();k.threaten();k.deploy()
func shoot(weapon: int=128) -> void:
	game.target_index=-1
	game.arsenal.fire(weapon,game.pilot.position,-PI/2)
	if weapon==128:
		var shot=game.shots.back();shot.velocity=Vector2(-600,0);shot.speed=600;shot.life=2
		game.update_shots(.3)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-world-under-fire.json";game.controls.path="/tmp/ev-world-under-fire-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.pilot.cheat_world_killer=true;k=game.world_killer
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	deploy(128);shoot()
	check(k.bomb().get("under_fire_hits",0)==1 and game.shots.is_empty(),"player laser hits the threatened planet and is consumed")
	check(k.bomb().bribe_offer>0 and k.live_message.contains("We are sorry!") and k.live_message.contains("Please stop firing"),"first hit triggers frightened apologies and a bribe immediately")
	var surface: Vector2=k.target_position(128)+Vector2(k.target_radius(128),0)
	check(game.sparks.back().position.distance_to(surface)<.01,"impact sparks originate at the near surface")
	var offer: int=k.bomb().bribe_offer;shoot();shoot()
	var panel=game.hud.root.find_child("LiveWorldAppeal",true,false);panel._process(0)
	check(k.bomb().under_fire_hits==3 and panel.urgency==3,"sustained fire makes pleas fully desperate")
	check(k.bomb().bribe_offer==offer,"rapid hits cannot raise the bribe every frame")
	k.advance(6);shoot()
	check(k.bomb().bribe_offer>offer,"continued bombardment raises the offer after its cooldown")
	var hits: int=k.bomb().under_fire_hits;shoot(142)
	check(k.bomb().under_fire_hits==hits+1,"player beam weapons also strike the threatened planet")
	var blocker_pos: Vector2=surface+Vector2(65,0)
	game.environment_hazards.rocks=[{"position":blocker_pos,"radius":20}]
	hits=k.bomb().under_fire_hits;shoot();shoot(142)
	check(k.bomb().under_fire_hits==hits,"asteroids block projectile and beam hits before the planet")
	game.environment_hazards.rocks=[]
	var npc=game.traffic.spawn(131,128,0,blocker_pos)
	shoot()
	check(k.bomb().under_fire_hits==hits,"an intervening ship takes the projectile instead of the planet")
	game.traffic.retire(npc)
	npc=game.traffic.spawn(131,128,0,k.target_position(128))
	var health: float=npc.health;shoot(142)
	check(npc.health==health and k.bomb().under_fire_hits==hits+1,"planet surface blocks beams from reaching a ship behind it")
	var start: Vector2=game.pilot.position;var end: Vector2=k.target_position(128)
	check(k.shot_intersection(start,end,{"enemy":true}).is_empty() and k.shot_intersection(start,end,{"npc_shot":true}).is_empty(),"NPC fire does not trigger player intimidation")
	check(k.shot_intersection(start,end,{"weapon":149}).is_empty() and k.shot_intersection(start,end,{"kind":"flare"}).is_empty(),"tractor beams and flares do not trigger bombardment")
	game.save_game(false);game.load_game()
	check(k.bomb().under_fire_hits==hits+1 and k.live_message.contains("We are sorry!"),"fear and bombardment state survive disk reload")
	k.spare();deploy(129);k.advance(12);offer=k.bomb().bribe_offer;shoot()
	check(k.bomb().get("under_fire_hits",0)==1 and k.bomb().bribe_offer>offer,"targeted stations react to player fire with a higher existing offer")
	check(not k.destroyed(129) and not k.bomb().is_empty(),"ordinary weapons do not bypass the reckoning countdown")
	game.free();await process_frame
	print("WORLD UNDER FIRE: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
