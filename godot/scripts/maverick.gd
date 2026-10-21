extends RefCounted
const SHIP=900
const GUN=900
const MISSILE=901
const DISRUPTOR=903
const AFTERBURNER_SPEED=2.5
const AFTERBURNER_ACCEL=2.75
const VICTORY_TRACKS=["res://audio/maverick_music.mp3","res://audio/maverick_great_balls.mp3"]
const Models=preload("res://scripts/models.gd")
const Details=preload("res://scripts/ship_detail.gd")
const LINES=["Talk to me, Goose.","I feel the need—the need for speed!","SS-Maverick checking in. Someone put a planet where my runway should be.","Wings swept. Coffee secured. Let's make this a good flight.","Tower, requesting a flyby. I'll take that silence as a maybe.","Goose, remind me which switch turns the vacuum off?"]
var timer: float=180
var last_line: int=-1
var victory: AudioStreamPlayer
var victory_cooldown: float=0
var warp_active: bool=false
var warp_fade: float=0.0
const WARP_VOLUME=3.02
const WARP_FADE_SECONDS=3.0
func quote(rng: RandomNumberGenerator) -> String:
	var index=rng.randi_range(0,LINES.size()-2)
	if index>=last_line and last_line>=0: index+=1
	last_line=index
	return LINES[index]
func advance(game,dt: float) -> void:
	victory_cooldown=maxf(0,victory_cooldown-dt)
	timer-=dt
	if timer>0: return
	timer=game.traffic.rng.randf_range(180,420)
	if game.hyperdrive.active() or game.npcs.any(func(n):return n.id==SHIP): return
	spawn(game)
func spawn(game) -> Dictionary:
	var npc: Dictionary=game.traffic.spawn(SHIP,136,3,game.pilot.position+Vector2.from_angle(game.traffic.rng.randf()*TAU)*1100)
	if npc.is_empty(): return npc
	npc.name="SS-Maverick";npc.maverick=true;npc.ambient=true;npc.maverick_radio=4.0
	return npc
func update(game,npc: Dictionary,dt: float) -> void:
	if npc.disabled or npc.has("departure"): return
	if npc.age>100 and not npc.provoked: game.traffic.request_departure(npc);return
	npc.maverick_radio-=dt
	if npc.maverick_radio<=0:
		npc.maverick_radio=game.traffic.rng.randf_range(24,38)
		if npc.position.distance_to(game.pilot.position)<2200: game.notify("SS-Maverick: “"+quote(game.traffic.rng)+"”")
func celebrate(game) -> void:
	if game.muted or victory_cooldown>0 or (is_instance_valid(victory) and victory.playing): return
	victory_cooldown=8
	if not is_instance_valid(victory):
		victory=AudioStreamPlayer.new();victory.name="MaverickVictory";victory.volume_db=-0.98;game.add_child(victory)
	var supplied="user://maverick_victory.ogg"
	var choices: Array=VICTORY_TRACKS.duplicate()
	if FileAccess.file_exists(supplied): choices[0]=supplied
	var choice: String=choices[game.traffic.rng.randi_range(0,choices.size()-1)]
	victory.stream=AudioStreamOggVorbis.load_from_file(choice) if choice==supplied else load(choice)
	victory.volume_db=-0.98
	victory.play()

static func victory_gain(track: String,position: float,duration: float) -> float:
	if track!="res://audio/maverick_great_balls.mp3": return 1.0
	return clampf((duration-position)/2.0,0.0,1.0)

func advance_victory_fade() -> void:
	if not is_instance_valid(victory) or not victory.playing or victory.stream_paused: return
	var gain: float=victory_gain(victory.stream.resource_path,victory.get_playback_position(),victory.stream.get_length())
	victory.volume_db=-0.98+linear_to_db(maxf(.0001,gain))

func begin_warp(game) -> void:
	if game.pilot.ship_id!=SHIP: return
	warp_active=true;warp_fade=0
	var music: AudioStreamPlayer=game.audio.maverick_warp
	music.volume_db=WARP_VOLUME
	if not game.muted and not music.playing: music.play()

func advance_warp(game,dt: float) -> void:
	if not warp_active: return
	var music: AudioStreamPlayer=game.audio.maverick_warp
	if game.pilot.ship_id!=SHIP or game.mode in ["title","dead","ejecting","rescue"]:
		music.stop();warp_active=false;warp_fade=0;return
	if game.mode!="flight": return
	if game.hyperdrive.active() or not game.chain_route.is_empty():
		warp_fade=0;music.volume_db=WARP_VOLUME
		if not game.muted and not music.playing: music.play()
		return
	warp_fade=minf(WARP_FADE_SECONDS,warp_fade+maxf(0,dt))
	var gain: float=1.0-warp_fade/WARP_FADE_SECONDS
	music.volume_db=WARP_VOLUME+linear_to_db(maxf(.0001,gain))
	if warp_fade>=WARP_FADE_SECONDS: music.stop();warp_active=false

static func install(catalog) -> void:
	var data: Dictionary=catalog.data
	var ship: Dictionary=data.ships["148"].duplicate(true);ship.id=SHIP;ship.name="F-14 Tomcat"
	ship.fields.merge({"custom_flight":true,"Holds":72,"Shield":780,"Armor":70,"Fuel":800,"FreeMass":56,"Cost":650000,"TechLevel":3,"WeapType":[GUN,MISSILE,0,0],"WeapCount":[1,1,0,0],"AmmoLoad":[0,8,0,0],"MaxGun":2,"Mass":30,"Crew":2},true)
	data.ships[str(SHIP)]=ship;data.ship_graphics[str(SHIP)]=data.ship_graphics["148"].duplicate(true)
	for entry in [[GUN,128,"M61 Machine Gun"],[MISSILE,132,"AIM-9 Sidewinder"]]:
		var weapon: Dictionary=data.weapons[str(entry[1])].duplicate(true);weapon.id=entry[0];weapon.name=entry[2];data.weapons[str(entry[0])]=weapon
	data.weapons[str(GUN)].fields.merge({"Reload":4,"Count":40,"MassDmg":5,"EnergyDmg":3,"Speed":1300,"Inaccuracy":2,"Sound":-1},true)
	data.weapons[str(MISSILE)].fields.merge({"AmmoType":902,"Speed":900,"Sound":4,"Count":int(data.weapons["132"].fields.Count)*3},true)
	var disruptor: Dictionary=data.weapons["132"].duplicate(true)
	disruptor.id=DISRUPTOR;disruptor.name="EMP Disruptor"
	disruptor.fields.merge({"AmmoType":0,"Reload":120,"Count":150,"Speed":1000,"MassDmg":0,"EnergyDmg":0,"BlastRadius":0,"ProxRadius":0,"Inaccuracy":0,"Sound":4,"MiscFlags":2},true)
	data.weapons[str(DISRUPTOR)]=disruptor
	for entry in [[900,128,"M61 Machine Gun",1,GUN,6,18000],[901,133,"Sidewinder Rail",1,MISSILE,4,22000],[902,134,"AIM-9 Sidewinder",3,MISSILE,1,1800]]:
		var outfit: Dictionary=data.outfits[str(entry[1])].duplicate(true);outfit.id=entry[0];outfit.name=entry[2]
		outfit.fields.merge({"ModType":entry[3],"ModVal":entry[4],"Mass":entry[5],"Cost":entry[6],"TechLevel":3},true)
		data.outfits[str(entry[0])]=outfit
	data.descriptions[str(SHIP)]="A space-rated F-14 Tomcat: swept wings, twin engines and tandem cockpit. Includes a built-in nonlethal EMP Disruptor, an M61 machine gun, Sidewinder rail, eight missiles, Tritanium Armor, an IFF Decoder and a high-output afterburner."
static func build() -> Node3D:
	var root=Node3D.new();root.name="SSMaverick"
	var steel=Models.material(Color("9ba6ad"),.5);var dark=Models.material(Color("273039"),.5);var glass=Models.material(Color("5eb6ca"),.6);var red=Models.material(Color("a73a32"),.3)
	Details.hull(root,PackedVector2Array([Vector2(0,-1.5),Vector2(.17,-.65),Vector2(.28,.45),Vector2(.16,1.1),Vector2(-.16,1.1),Vector2(-.28,.45),Vector2(-.17,-.65)]),.16,steel)
	Details.panel(root,Vector3(0,.2,-.65),Vector3(.19,.13,.6),glass)
	for side in [-1,1]:
		# Fixed wing gloves meet distinct, moderately swept outer panels.
		# A clipped tip and nearly parallel edges avoid the previous delta-wing outline.
		var glove=PackedVector2Array([Vector2(side*.16,-.64),Vector2(side*.37,-.46),Vector2(side*.52,-.02),Vector2(side*.44,.45),Vector2(side*.18,.55)])
		Details.hull(root,glove,.11,steel)
		var wing=PackedVector2Array([Vector2(side*.43,-.21),Vector2(side*1.31,.25),Vector2(side*1.28,.49),Vector2(side*.98,.44),Vector2(side*.43,.25)])
		var pivot=Node3D.new();pivot.name="WingLeft" if side<0 else "WingRight";pivot.position=Vector3(side*.43,0,-.12);pivot.set_meta("sweep_side",side);root.add_child(pivot)
		for i in wing.size(): wing[i]-=Vector2(side*.43,-.12)
		Details.hull(pivot,wing,.065,steel)
		var pylon=Marker3D.new();pylon.name="SidewinderPylon";pylon.position=Vector3(side*.44,-.04,.2);pivot.add_child(pylon)
		Details.panel(pivot,pylon.position,Vector3(.035,.05,.24),dark)
		# Sweep pivot cover and a narrow flap seam on the trailing edge.
		Details.panel(root,Vector3(side*.45,.105,.02),Vector3(.07,.015,.28),dark)
		var seam=Details.panel(pivot,Vector3(side*.42,.07,.445),Vector3(.52,.008,.012),dark)
		seam.rotation.y=-side*.33
		Details.panel(root,Vector3(side*.25,.04,.45),Vector3(.26,.22,1.4),steel)
		Details.panel(root,Vector3(side*.25,.03,-.2),Vector3(.22,.16,.2),dark)
		Details.hull(root,PackedVector2Array([Vector2(side*.24,.68),Vector2(side*.73,.9),Vector2(side*.73,1.09),Vector2(side*.27,.99)]),.08,steel)
		Details.panel(root,Vector3(side*.29,.27,.78),Vector3(.04,.45,.38),dark)
		Details.panel(root,Vector3(side*.29,.5,.77),Vector3(.05,.025,.23),red)
		Models.add_exhaust(root,Vector3(side*.25,.05,1.22),side)
	Details.batch_static_parts(root)
	return root

# Per-instance state keeps previews and other Tomcats independent.
static func advance_wings(model: Node3D,folded: bool,dt: float) -> void:
	if not is_instance_valid(model) or int(model.get_meta("ship_id",-1))!=SHIP: return
	var amount: float=float(model.get_meta("wing_sweep",0.0))
	amount=move_toward(amount,1.0 if folded else 0.0,maxf(0,dt)/2.0)
	model.set_meta("wing_sweep",amount)
	var eased: float=smoothstep(0,1,amount)
	for name in ["WingLeft","WingRight"]:
		var pivot=model.get_node_or_null(name)
		if pivot!=null: pivot.rotation.y=-float(pivot.get_meta("sweep_side"))*deg_to_rad(43)*eased

static func missile_origin(model: Node3D,position: Vector2,heading: float) -> Vector2:
	if not is_instance_valid(model): return position
	var side: int=int(model.get_meta("next_sidewinder_side",-1))
	model.set_meta("next_sidewinder_side",-side)
	var pivot=model.get_node_or_null("WingLeft" if side<0 else "WingRight")
	var local: Vector3
	if pivot!=null and pivot.has_node("SidewinderPylon"):
		local=model.scale*(pivot.transform*pivot.get_node("SidewinderPylon").position)
	else:
		local=Vector3(side*float(model.get_meta("radius",35))*.65,0,-8)
	# Use the firing ship's physics position/heading, not interpolated render position.
	var offset: Vector3=Basis(Vector3.UP,-heading)*local
	return position+Vector2(offset.x,offset.z)
