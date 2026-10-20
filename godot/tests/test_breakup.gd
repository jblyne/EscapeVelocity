extends SceneTree
const Breakup=preload("res://scripts/breakup.gd")
var game
var count: int=0
var failures: int=0
var blasts: int=0
func check(ok: bool, message: String) -> void:
	count+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Breakup.line_bag.clear();Breakup.last_line=""
	var previous: String=""
	var rotation_ok: bool=true
	for cycle in 10:
		var heard: Array[String]=[]
		for draw in Breakup.HUMAN_LINES.size():
			var line: String=Breakup.next_human_line()
			rotation_ok=rotation_ok and line!=previous and line not in heard
			heard.append(line);previous=line
	check(rotation_ok,"all six phrases rotate before repeating, including shuffle boundaries")
	var recordings_ok: bool=true
	for line in Breakup.HUMAN_LINES:
		for take in [1,2]:
			var recording=load("res://audio/wreck_%s_%d.wav" % [line,take])
			recordings_ok=recordings_ok and recording is AudioStreamWAV and is_equal_approx(recording.get_length(),6)
	check(recordings_ok,"all twelve human crew mixes load and cover the full burn")
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-breakup-pilot.json"
	game.muted=true
	game.breakup_chance=1.0
	game.traffic.enabled=false
	root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.traffic.spawn(129,128,3,game.pilot.position+Vector2(250,0))
	var npc=game.npcs[0]
	npc.velocity=Vector2(70,30)
	game.damage_npc(npc,10000)
	var effect=game.explosions[0]
	effect.secondary_blast.connect(func(): blasts+=1)
	check(effect is Breakup and effect.halves.size()==2,"forced variant creates two halves")
	check(npc not in game.npcs,"split wreck no longer acts as a living ship")
	check(effect.drift==Vector3(45.5,0,19.5),"wreck inherits ship drift")
	var a=effect.halves[0];var b=effect.halves[1]
	check(a.voice!=b.voice and a.voice.playing and b.voice.playing,"each burning half owns an independent active voice")
	check(a.voice.name!=b.voice.name,"halves start with different final words")
	check(a.voice.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and a.voice.stream.get_length()==6.0,"crew mix covers the full burn and loops if needed")
	check(a.voice.volume_db==-80 and b.voice.volume_db==-80,"muted destruction begins silent")
	game.toggle_audio()
	check(a.voice.volume_db==-10 and b.voice.volume_db==-10,"unmute restores balanced crew mix")

	check(a.node.get_child_count()>0 and b.node.get_child_count()>0,"both halves contain cut hull geometry")
	check(absf(a.timer-b.timer)>=1.0 and minf(a.timer,b.timer)>=2.2,"independent timers leave visible burn time and staggered blasts")
	var start: float=a.node.position.distance_to(b.node.position)
	game.update_explosions(1.0)
	check(a.node.position.distance_to(b.node.position)>start,"halves separate as they drift")
	check(a.node.visible and b.node.visible and a.fire[0].visible,"both pieces remain visible and burn before detonation")
	await process_frame
	check(not is_instance_valid(npc.model) and is_instance_valid(a.node),"halves own their geometry after original ship is freed")
	game.set_mode("pause");game._physics_process(1.0)
	check(effect.age==1.0,"pause freezes burn timers")
	check(a.voice.stream_paused and b.voice.stream_paused,"pause freezes both crew recordings")
	game.set_mode("flight")
	check(not a.voice.stream_paused and not b.voice.stream_paused,"resume continues both crew recordings")
	var early: float=minf(a.timer,b.timer)
	game.update_explosions(early-effect.age+.05)
	check(blasts==1 and a.exploded!=b.exploded,"first half explodes alone")
	var survivor=b if a.exploded else a
	check(survivor.node.visible and survivor.fire[0].visible,"other half continues burning")
	var destroyed=a if a.exploded else b
	check(not destroyed.voice.playing and survivor.voice.playing,"only detonating half cuts off its crew audio")
	game.toggle_audio()
	check(survivor.voice.volume_db==-80,"mute silences surviving half immediately")
	game.toggle_audio()
	check(not destroyed.voice.playing and survivor.voice.playing,"unmute never revives an exploded half's voices")
	game.update_explosions(maxf(a.timer,b.timer)-effect.age+.05)
	check(blasts==2 and a.exploded and b.exploded,"second half detonates independently")
	check(not a.voice.playing and not b.voice.playing,"both crew recordings stop after both detonations")
	check(not a.node.visible and not b.node.visible and a.blast.people.is_empty(),"exploded hulls hide and wreck blasts do not eject extra crew")
	game.update_explosions(8)
	await process_frame
	check(game.explosions.is_empty() and not is_instance_valid(effect),"entire delayed effect cleans up")
	var positions: Array[Vector3]=[]
	for fps in [30,60,120]:
		var timed=game.Breakup.new();game.world.add_child(timed)
		timed.setup(game.player_model,Vector2(70,30),42)
		for frame in fps*4: timed.advance(1.0/fps)
		positions.append(timed.halves[0].node.position+timed.position)
		timed.free()
	check(positions[0].distance_to(positions[2])<.001,"half movement and detonation position are frame-rate independent")
	var large=game.ShipModels.create(game.catalog,134,128)
	var variants: Dictionary={}
	var triple_seed: int=-1
	for seed_value in 12:
		var wreck=Breakup.new();game.world.add_child(wreck)
		wreck.setup(large,Vector2.ZERO,seed_value)
		variants[wreck.halves.size()]=true
		check(wreck.halves.all(func(piece):return piece.node.get_child_count()>0),"large hull pieces own clipped geometry")
		if wreck.halves.size()==3: triple_seed=seed_value
		wreck.free()
	check(variants.has(2) and variants.has(3),"cruiser can randomly break into two or three pieces")
	var wreck=Breakup.new();game.world.add_child(wreck)
	wreck.setup(large,Vector2.ZERO,triple_seed)
	wreck.start_crew_audio(false,true,true)
	check(wreck.halves.all(func(piece):return is_instance_valid(piece.voice) and piece.voice.playing),"three pieces have independent crew players")
	var variety_ok: bool=true
	for boundary in 12:
		for piece in wreck.halves: piece.voice.free()
		wreck.start_crew_audio(false,true,true)
		var phrase_names: Array=[]
		for piece in wreck.halves:
			var phrase: String=str(piece.voice.name).get_slice("_",1)
			variety_ok=variety_ok and phrase not in phrase_names
			phrase_names.append(phrase)
	check(variety_ok,"three-piece wrecks always use three different phrases across shuffle boundaries")
	var ordered: Array=wreck.halves.duplicate()
	ordered.sort_custom(func(left,right):return left.timer<right.timer)
	var impact: float=ordered[0].timer
	wreck.advance(impact-.01)
	var survivor_piece: Dictionary=ordered[1]
	var expected: Vector3=survivor_piece.offset+survivor_piece.velocity*impact
	var initial_velocity: Vector3=survivor_piece.velocity
	wreck.advance(.01)
	check(survivor_piece.node.position.distance_to(expected)<.001,"blast impulse preserves position at detonation")
	var away: Vector3=(survivor_piece.node.position-ordered[0].node.position).normalized()
	check((survivor_piece.velocity-initial_velocity).dot(away)>50,"first explosion kicks surviving wreck away")
	wreck.advance(.1)
	check(survivor_piece.node.position.distance_to(expected+survivor_piece.velocity*.1)<.001,"survivor continues along new trajectory")
	var last_velocity: Vector3=ordered[2].velocity
	wreck.advance(ordered[1].timer-wreck.age+.01)
	check(ordered[2].velocity.distance_to(last_velocity)>50,"second explosion also pushes the third surviving piece")
	wreck.free()
	positions.clear()
	for fps in [30,60,120]:
		var timed=Breakup.new();game.world.add_child(timed)
		timed.setup(large,Vector2(70,30),triple_seed)
		for frame in fps*7: timed.advance(1.0/fps)
		positions.append(timed.halves[1].node.position+timed.position)
		timed.free()
	check(positions[0].distance_to(positions[2])<.001,"three-piece impulses and detonation positions are frame-rate independent")
	large.free()
	var reversal=Breakup.new();game.world.add_child(reversal)
	reversal.setup(game.player_model,Vector2.ZERO,42)
	var first_piece: Dictionary=reversal.halves[0] if reversal.halves[0].timer<reversal.halves[1].timer else reversal.halves[1]
	var remaining: Dictionary=reversal.halves[1] if first_piece==reversal.halves[0] else reversal.halves[0]
	first_piece.offset=Vector3.ZERO;first_piece.velocity=Vector3.ZERO
	remaining.velocity=Vector3(-200,0,0)
	remaining.offset=Vector3(100,0,0)-remaining.velocity*first_piece.timer
	reversal.advance(first_piece.timer)
	check(remaining.velocity.x>0,"explosion reverses wreckage moving toward the blast")
	reversal.free()
	var alien=game.Breakup.new();game.world.add_child(alien)
	alien.setup(game.player_model,Vector2.ZERO,42)
	alien.start_crew_audio(true,true,true)
	check(str(alien.halves[0].voice.name).begins_with("wreck_alien") and str(alien.halves[1].voice.name).begins_with("wreck_alien"),"alien halves retain alien crew screams")
	alien.free()
	game.ship_explosion(game.player_model,game.pilot.position,Vector2.ZERO)
	game.load_system()
	await process_frame
	check(game.explosions.is_empty(),"system change removes burning halves")
	game.pilot.shield=0;game.pilot.armor=1;game.damage_player(10000)
	check(game.mode=="dead" and game.explosions[0] is Breakup,"player can also break apart")
	check(game.explosions[0].halves[0].voice.playing and not game.explosions[0].halves[0].voice.stream_paused,"player wreck voices continue on death screen")
	game._physics_process(5.0)
	check(game.explosions[0].halves[0].exploded and game.explosions[0].halves[1].exploded,"both delayed blasts run behind death screen")
	game._physics_process(8.0)
	check(game.explosions.is_empty(),"player split effect expires")
	game.free();await process_frame
	print("BREAKUP RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
