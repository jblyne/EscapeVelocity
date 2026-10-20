extends SceneTree
var game
var count=0
var failures=0
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	count+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func stop_cries():
	for key in game.Arsenal.PANIC_KEYS: game.audio[key].stop()
func playing() -> bool:
	for key in game.Arsenal.PANIC_KEYS:
		if game.audio[key].playing: return true
	return false
func run():
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-panic-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.set_mode("flight");game.muted=false
	for npc in game.npcs: npc.model.queue_free()
	game.npcs.clear()
	game.pilot.position=Vector2.ZERO;game.pilot.heading=0
	game.pilot.cheat_all_weapons=true;game.select_weapon(191);game.cooldown=0
	check(game.fire_player(),"real forklift projectile fires")
	var shot=game.shots.back()
	var npc=game.traffic.spawn(134,128,4,Vector2(0,-200))
	npc.velocity=Vector2.ZERO;npc.health=shot.damage;npc.radius=20
	var original_position: Vector2=npc.position
	npc.position=shot.position+shot.velocity.normalized()*(shot.speed*2.5+npc.radius)
	check(game.arsenal.lethal_impact_target(shot)==npc,"lethal forklift triggers 2.5 seconds before impact, beyond the old window")
	npc.position=shot.position+shot.velocity.normalized()*(shot.speed*3.5+npc.radius)
	check(game.arsenal.lethal_impact_target(shot).is_empty(),"distant future threat remains outside warning window")
	npc.position=original_position
	check(game.arsenal.lethal_impact_target(shot)==npc,"incoming forklift predicts lethal contact before collision")
	npc.health=shot.damage+1
	check(game.arsenal.lethal_impact_target(shot).is_empty(),"nonlethal damage stays silent")
	npc.health=shot.damage
	npc.position.x=200
	check(game.arsenal.lethal_impact_target(shot).is_empty(),"near miss stays silent")
	npc.position=Vector2(0,-200);npc.velocity=Vector2(2000,0)
	check(game.arsenal.lethal_impact_target(shot).is_empty(),"prediction includes evasive target drift")
	npc.velocity=Vector2.ZERO
	var life=shot.life;shot.life=.001
	check(game.arsenal.lethal_impact_target(shot).is_empty(),"expiring projectile cannot trigger premature cry")
	shot.life=life
	npc.hector=true
	check(game.arsenal.lethal_impact_target(shot).is_empty(),"invulnerable ship stays silent")
	npc.hector=false
	var blocker=game.traffic.spawn(134,128,4,Vector2(0,-100))
	blocker.velocity=Vector2.ZERO;blocker.radius=20;blocker.health=shot.damage+1
	check(game.arsenal.lethal_impact_target(shot).is_empty(),"nonlethal first contact blocks prediction behind it")
	game.npcs.erase(blocker);blocker.model.queue_free()
	game.muted=true;game.arsenal.warn_lethal_impact(shot)
	check(not playing() and not npc.get("panic_called",false),"mute suppresses panic playback")
	game.muted=false
	game.update_shots(.001)
	check(playing() and npc.get("panic_called",false) and npc in game.npcs,"actual projectile update plays cry before ship dies")
	game.set_mode("pause")
	var paused=true
	for key in game.Arsenal.PANIC_KEYS:
		if game.audio[key].playing: paused=paused and game.audio[key].stream_paused
	check(paused,"pause freezes active panic playback")
	game.set_mode("flight");stop_cries();game.arsenal.warn_lethal_impact(shot)
	check(not playing(),"same threatened ship does not repeat its cry")
	npc.panic_called=false;game.sound("panic_cmd_civilian_1");game.arsenal.warn_lethal_impact(shot)
	check(not npc.panic_called,"another active cry suppresses overlap")
	stop_cries();game.arsenal.warn_lethal_impact(shot)
	var owned_key: String=game.arsenal.panic_key
	check(owned_key in game.Arsenal.PANIC_POOLS.confed,"Confederation victim uses military voice pool")
	var bystander=game.traffic.spawn(134,136,4,Vector2(500,500))
	game.damage_npc(bystander,bystander.health+1)
	check(game.audio[owned_key].playing,"unrelated ship explosion does not cut off speaker")
	game.damage_npc(npc,1)
	check(game.audio[owned_key].playing,"nonlethal damage does not cut off speaker")
	game.damage_npc(npc,npc.health+1)
	check(not game.audio[owned_key].playing and game.arsenal.panic_owner==null,"speaker explosion cuts transmission off immediately")
	for key in game.Arsenal.DEATH_KEYS: game.audio[key].stop()
	npc.id=128
	check(game.arsenal.death_cry(npc),"every destruction plays a scream")
	var death_key: String=game.arsenal.last_death_key
	check(game.arsenal.death_cry(npc),"simultaneous destruction is not suppressed")
	game.set_mode("pause")
	check(game.audio[death_key].stream_paused,"pause freezes explosion scream and baked fade")
	game.set_mode("flight")
	game.muted=true
	check(not game.arsenal.death_cry(npc),"mute suppresses explosion screams")
	game.muted=false
	npc.faction=140
	check(game.arsenal.death_cry(npc) and game.arsenal.last_death_key in game.Arsenal.DEATH_POOLS.alien_single,"small alien uses separate fading cry")
	npc.id=149
	check(game.arsenal.death_cry(npc) and game.arsenal.last_death_key in game.Arsenal.DEATH_POOLS.alien_crew,"alien crew uses multiple alien screams")
	npc.id=150
	check(game.arsenal.death_cry(npc) and game.arsenal.last_death_key in game.Arsenal.DEATH_POOLS.alien_crowd,"alien cruiser uses a larger crowd")
	npc.faction=136;npc.id=129
	check(game.arsenal.death_cry(npc) and game.arsenal.last_death_key in game.Arsenal.DEATH_POOLS.human_crew,"light freighter has overlapping crew screams")
	npc.id=134
	check(game.arsenal.death_cry(npc) and game.arsenal.last_death_key in game.Arsenal.DEATH_POOLS.human_crowd,"cruiser has a larger crew chorus")
	npc.health=1
	check(not game.arsenal.death_cry(npc),"surviving ships do not scream as if destroyed")
	npc.health=0;npc.position=Vector2(10000,0)
	check(game.arsenal.death_cry(npc),"distance does not randomly suppress ship destruction audio")
	game.pilot.cheat_invincibility=false;game.pilot.shield=0;game.pilot.armor=1
	game.damage_player(100)
	check(game.mode=="dead" and game.audio[game.arsenal.last_death_key].playing and not game.audio[game.arsenal.last_death_key].stream_paused,"player explosion scream remains audible on death screen")
	game.set_mode("flight")
	game.sound("death_cry_1")
	game.sound("panic_cmd_civilian_1")
	game.load_system(0.0)
	check(not game.audio.death_cry_1.playing,"arrival clears fading death audio")
	for key in game.Arsenal.DEATH_KEYS:
		check(is_equal_approx(game.audio[key].stream.get_length(),.85),"death cry ends within 0.85 seconds: "+key)
	check(not playing(),"hyperspace arrival clears old system cries")
	for key in game.Arsenal.PANIC_KEYS:
		check(game.audio[key].stream.get_length()>.5 and game.audio[key].stream.get_length()<7,"panic recording is short and loaded: "+key)

	game.arsenal.death_bags.clear()
	for group in game.Arsenal.DEATH_POOLS:
		var pool: Array=game.Arsenal.DEATH_POOLS[group]
		var previous=""
		var full_cycles=true
		var no_repeats=true
		for cycle in 20:
			var heard: Array=[]
			for i in pool.size():
				var key: String=game.arsenal.next_death(group)
				no_repeats=no_repeats and key!=previous
				if key in pool and key not in heard: heard.append(key)
				previous=key
			full_cycles=full_cycles and heard.size()==pool.size()
		check(no_repeats,"death screams avoid consecutive repeats: "+group)
		check(full_cycles,"death screams exhaust each shuffled pool: "+group)

	game.arsenal.panic_bags.clear()
	for faction in [128,129,130,140,136]:
		var group: String=game.arsenal.panic_group(faction)
		var pool: Array=game.Arsenal.PANIC_POOLS[group]
		var previous=""
		var no_repeats=true
		var full_cycles=true
		for cycle in 20:
			var heard: Array=[]
			for i in pool.size():
				var key=game.arsenal.next_panic(faction)
				no_repeats=no_repeats and key!=previous
				if key in pool and key not in heard: heard.append(key)
				previous=key
			full_cycles=full_cycles and heard.size()==pool.size()
		check(no_repeats,"no repeated takes across cycle boundaries: "+group)
		check(full_cycles,"every faction take plays before repeating: "+group)
	for faction in [143,145,149]: check(game.arsenal.panic_group(faction)=="confed","Confederation variant maps to military pool")
	for faction in [144,146,153]: check(game.arsenal.panic_group(faction)=="rebel","Rebel variant maps to Rebel pool")
	check(game.arsenal.panic_group(150)=="alien","alien variant maps to alien pool")
	check(game.arsenal.panic_group(999)=="civilian","unknown factions use civilian fallback")
	game.free();await process_frame
	print("PANIC AUDIO RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
