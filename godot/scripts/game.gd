extends Node3D

const Catalog = preload("res://scripts/catalog.gd")
const Pilot = preload("res://scripts/pilot.gd")
const Models = preload("res://scripts/models.gd")
const StellarModels = preload("res://scripts/stellar_models.gd")
const ShipModels = preload("res://scripts/ship_models.gd")
const Factions = preload("res://scripts/factions.gd")
const Combat=preload("res://scripts/combat.gd")
var fleet_service=preload("res://scripts/fleet.gd").new()
const Traffic = preload("res://scripts/traffic.gd")
const Flight = preload("res://scripts/flight.gd")
const Travel = preload("res://scripts/travel_rules.gd")
const Hyperspace = preload("res://scripts/hyperspace.gd")
const JumpVisuals = preload("res://scripts/jump_visuals.gd")
const HUD = preload("res://scripts/hud.gd")
const Arsenal = preload("res://scripts/arsenal.gd")
const Hector = preload("res://scripts/hector.gd")
const Shipyard = preload("res://scripts/shipyard.gd")
const Missions = preload("res://scripts/missions.gd")
const Cloak = preload("res://scripts/cloak.gd")
const Outfitter = preload("res://scripts/outfitter.gd")
const ShieldHit = preload("res://scripts/shield_hit.gd")
const Persons=preload("res://scripts/persons.gd")
var persons=Persons.new()
var ejection=preload("res://scripts/ejection.gd").new()
var world_killer=preload("res://scripts/world_killer.gd").new()
var world_activity=preload("res://scripts/world_activity.gd").new()
const Explosion = preload("res://scripts/explosion.gd")
const Breakup = preload("res://scripts/breakup.gd")
var breakup_chance: float = 0.28
const ShipInteractions = preload("res://scripts/ship_interactions.gd")
var save_path: String = "user://pilot-v1.json"
var pilot_file_error: String=""
var remember_pilot_selection: bool=false
var pilot_selection_path: String="user://active-pilot.json"
var catalog: EVCatalog
var pilot: EVPilot
var velocity = Vector2.ZERO
var mode: String = "flight"
var map_return_mode: String = "flight"
var map_selected: int=-1
var map_center=Vector2(INF,INF)
var map_zoom: float=4.6
var map_preview_system: int=-1
var map_route: Array=[]
var camera: Camera3D
var world: Node3D
var player_model: Node3D
var planets: Array = []
var npcs: Array = []
var escorts: Array = []
var autopilot=preload("res://scripts/autopilot.gd").new()
var maverick_volley=preload("res://scripts/maverick_volley.gd").new()
var fighter_wing=preload("res://scripts/fighter_wing.gd").new()
var arsenal = Arsenal.new()
var shipyard = Shipyard.new()
var missions = Missions.new()
var achievements=preload("res://scripts/achievements.gd").new()
var achievements_return_mode: String="pause"
var achievement_clock: float=0
var cloak = Cloak.new()
var outfitter = Outfitter.new()
var traffic = Traffic.new()
var hector = Hector.new()
var interactions = ShipInteractions.new()
var cheat_return_mode: String = "flight"
var fleet_return_mode: String = "flight"
var shots: Array = []
var sparks: Array = []
var engine_smoke: Node3D
var missile_smoke: Node3D
var explosions: Array = []
var shield_hits: Array = []
const MAX_EXPLOSIONS = 8
var hud: CanvasLayer
var space_material: ShaderMaterial
var time: float = 0
var primary_cooldowns: Dictionary={}
var secondary_safe: bool=false
var self_destruct_seconds: float=0
var cooldown: float = 0
var target_index: int = -1
var destination: int = -1
var chain_route: Array = []
var chain_timer: float = 0.0
const CHAIN_STRETCH_SECONDS: float = 0.25
const CHAIN_BLAST_RADIUS: float = 300.0
var hyperdrive = Hyperspace.new()
var jump_visuals = JumpVisuals.new()
var player_base_scale = Vector3.ONE
var previous_player_position = Vector2.ZERO
var previous_player_velocity = Vector2.ZERO
var previous_player_heading: float = 0
var physics_step_dt: float = 0
var rendered_player_position = Vector3.ZERO
var rendered_player_velocity = Vector2.ZERO
var rendered_clock: float = 0
var auto_boarding: Dictionary={}
var last_board_tap: int=-1000
var auto_landing: bool=false
var last_land_tap: int=-1000
var landing_target: int = -1
var landing_clearance: int = -1
var docked_id: int = -1
var messages: Array = []
var muted: bool = false
var audio: Dictionary = {}
var title_music_position: float=0.0
var engine_audio: AudioStreamPlayer
var afterburner_audio_gain: float=0.0
var zoom: float = 900
var autosave_clock: float = 0
var recovery_clock: float=0.0
var recovery_window: Vector2i=Vector2i.ZERO
var damage_clock: float = 0
var death_reveal_time: float = 0
var screenshot_timer: float = -1
var screenshot_path: String = ""
var pilot_ready: bool = true

var environment_hazards=preload("res://scripts/environment_hazards.gd").new()
var controls=preload("res://scripts/control_settings.gd").new()
var controls_return_mode: String="pause"
var fast_time: bool=false

func open_achievements() -> void:
	achievements_return_mode=mode
	if achievements.update(false): save_game(false)
	set_mode("achievements")

func open_controls() -> void:
	controls_return_mode=mode;set_mode("controls")

func _ready() -> void:
	controls.load_settings()
	controls.apply_audio()
	get_window().title = "Escape Velocity HD — First Flight · v" + str(ProjectSettings.get_setting("application/config/version"))
	var launch_args = OS.get_cmdline_user_args()
	for i in launch_args.size():
		if launch_args[i] == "--save-path" and i+1 < launch_args.size():
			save_path = launch_args[i+1]
	remember_pilot_selection=save_path=="user://pilot-v1.json" and "--save-path" not in launch_args
	if remember_pilot_selection and FileAccess.file_exists(pilot_selection_path):
		var selection=JSON.parse_string(FileAccess.get_file_as_string(pilot_selection_path))
		if selection is Dictionary and selection.get("path",null) is String and FileAccess.file_exists(selection.path): save_path=selection.path
	catalog = Catalog.new()
	environment_hazards.game=self
	arsenal.game = self
	fighter_wing.game=self
	maverick_volley.game=self
	autopilot.game=self
	outfitter.game = self
	cloak.game = self
	missions.game = self
	achievements.game=self
	shipyard.game = self
	traffic.game = self
	fleet_service.game = self
	hector.game = self
	persons.game = self
	ejection.game = self
	world_killer.game = self
	world_activity.game = self
	interactions.game = self
	pilot = Pilot.new()
	setup_environment()
	setup_audio()
	if FileAccess.file_exists(save_path):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		opening_story_seen=pilot.restore(saved, catalog)
	load_system()
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	var controller_layer=CanvasLayer.new();controller_layer.name="ControllerOverlay";controller_layer.layer=100;add_child(controller_layer)
	controls.controller=preload("res://scripts/controller.gd").new();controls.controller.game=self;controller_layer.add_child(controls.controller)
	achievements.update(false)
	notify("W / Up thrust · Left / Right turn · S / Down face against drift, then thrust to slow.")
	notify("L requests landing clearance. Approach slowly, then L again to land.")
	get_tree().auto_accept_quit = false
	var args = OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--screenshot" and i + 1 < args.size():
			screenshot_path = args[i + 1]
			screenshot_timer = 2.0
		if args[i] == "--fresh":
			pilot = Pilot.new()
			load_system()

	if "--show-map" in args:
		set_mode("map")
	if "--show-port" in args:
		pilot.position = planets[0].position
		land()
		land()
	if "--debug-refuel" in args:
		debug_refuel()
	if "--enable-debug-cheats" in args:
		set_weapon_cheat(true)
		set_fuel_cheat(true)
	if "--show-cheats" in args: toggle_cheat_menu()
	if "--show-menu" in args or (not "--script" in OS.get_cmdline_args() and not "-s" in OS.get_cmdline_args() and not "--show-map" in args and not "--show-port" in args and not "--show-cheats" in args):
		pilot_ready = FileAccess.file_exists(save_path) and pilot.restore(JSON.parse_string(FileAccess.get_file_as_string(save_path)),catalog)
		set_mode("title")
	if DisplayServer.get_name() != "headless": warm_explosions()

func warm_explosions() -> void:
	# Compile every explosion/debris shader in a tiny off-screen viewport during
	# startup, with the same directional + point-light configuration as combat.
	# No explosion, sound, or pilot change is exposed in the playable world.
	var warmup = SubViewport.new()
	warmup.name = "ExplosionWarmup"
	warmup.size = Vector2i(32,32)
	warmup.own_world_3d = true
	warmup.msaa_3d = get_viewport().msaa_3d
	warmup.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(warmup)
	var warm_environment = WorldEnvironment.new()
	warm_environment.environment = get_world_3d().environment
	warmup.add_child(warm_environment)
	var warm_camera = Camera3D.new()
	warm_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	warm_camera.size = 400
	warm_camera.position = Vector3(0,1200,0)
	warm_camera.rotation_degrees.x = -90
	warmup.add_child(warm_camera)
	warmup.add_child(DirectionalLight3D.new())
	# The flash also lights intact ships and planets. Their point-light shader
	# variants must be warmed, not just the transparent debris/fire materials.
	var lit_ship = player_model.duplicate()
	lit_ship.position = Vector3(60,0,0)
	warmup.add_child(lit_ship)
	var cloaked_ship=player_model.duplicate()
	cloaked_ship.position=Vector3(-60,0,0)
	cloak.warm_model(cloaked_ship)
	warmup.add_child(cloaked_ship)
	var warm_world = Node3D.new()
	warmup.add_child(warm_world)
	var warm_planet=Models.planet(warm_world,Vector3(-90,-95,-40),60,128)
	var planet_effect=preload("res://scripts/planet_rupture.gd").new()
	warmup.add_child(planet_effect);planet_effect.setup(warm_planet,60,128);planet_effect.advance(.3)
	var warm_station=preload("res://scripts/death_star.gd").new()
	warmup.add_child(warm_station);warm_station.setup();warm_station.update_sequence(2,Vector3(-120,-60,-100))
	var effect = Explosion.new()
	warmup.add_child(effect)
	effect.setup(player_model,Vector2.ZERO,42)
	effect.advance(0.01)
	await RenderingServer.frame_post_draw
	effect.advance(0.35)
	await RenderingServer.frame_post_draw
	warmup.queue_free()

func setup_environment() -> void:
	var layer = CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_material = ShaderMaterial.new()
	space_material.shader = load("res://shaders/space.gdshader")
	bg.material = space_material
	layer.add_child(bg)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CANVAS
	env.environment.background_canvas_max_layer = -1
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("9cafcb")
	env.environment.ambient_light_energy = 0.42
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, -15)
	sun.light_color = Color("d5eaff")
	sun.light_energy = 2.2
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	# Wider windows reveal more space horizontally without stretching ships.
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = zoom
	camera.near = 1
	camera.far = 5000
	camera.current = true
	camera.position = Vector3(0,1200,330)
	camera.rotation_degrees = Vector3(-90,0,0)
	add_child(camera)

func setup_audio() -> void:
	for key in ["maverick_afterburner", "afterburner", "maverick_warp", "sidewinder_launch", "maverick_target", "maverick_missile", "maverick_gun", "laser", "impact", "explosion", "heavy_explosion", "jump", "land", "arrival", "forklift", "cloak_on", "cloak_off", "menu_click", "menu_hum", "menu_slam", "menu_music", "ui_target", "ui_open", "ui_select", "ui_error", "ui_confirm", "modal_alert", "airlock", "jump_start", "death_star_warp", "death_star_charge", "death_star_fire"] + Arsenal.PANIC_KEYS + Arsenal.DEATH_KEYS + Arsenal.WEAPON_SOUND_KEYS:
		if key=="menu_music":
			var boot_music=get_tree().root.get_node_or_null("BootTitleMusic")
			if boot_music!=null:
				boot_music.reparent(self);audio[key]=boot_music
				continue
		var player = AudioStreamPlayer.new()
		player.stream = load("res://audio/" + key + (".mp3" if key in ["maverick_afterburner","maverick_gun","maverick_warp","sidewinder_launch","maverick_target","maverick_missile"] else ".wav"))
		# Stretch the rising jump sound across the complete departure burn.
		if key == "jump": player.pitch_scale = player.stream.get_length() / Hyperspace.ACCELERATION_SECONDS
		player.volume_db = -4 if (key.begins_with("panic_") or key.begins_with("death_cry")) else (-13 if key == "laser" else -9)
		player.max_polyphony = 1 if key.begins_with("panic_") else 8
		# Original explosion PCM is near full-scale; give other effects room
		# and prevent long explosion tails from building up in busy battles.
		if key in ["explosion", "heavy_explosion"]:
			player.volume_db = -24 if key == "explosion" else -26
			player.max_polyphony = 3
		if key == "arrival":
			player.volume_db = -6
			player.max_polyphony = 1
		if key.begins_with("death_star_"):
			player.volume_db=-16 if key=="death_star_charge" else -12
			player.max_polyphony=1
		if key.begins_with("menu_"):
			player.volume_db={"menu_click":-12,"menu_hum":-17,"menu_slam":-18,"menu_music":-20}[key]
			player.max_polyphony=1
		if key.begins_with("ui_") or key=="modal_alert":
			player.volume_db=-14;player.max_polyphony=1
		if key in ["sidewinder_launch","maverick_target","maverick_missile"]: player.volume_db=-12;player.max_polyphony=1
		if key=="afterburner":
			player.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;player.stream.loop_begin=0;player.stream.loop_end=44100
			player.volume_db=-20;player.max_polyphony=1
		if key=="maverick_afterburner": player.stream.loop=true;player.volume_db=-11;player.max_polyphony=1
		if key=="maverick_gun": player.stream.loop=true;player.max_polyphony=1
		if key=="maverick_warp":
			player.stream.loop=true;player.volume_db=3.02;player.max_polyphony=1
		if key=="airlock": player.volume_db=-18;player.max_polyphony=1
		if key=="jump_start": player.volume_db=-15;player.max_polyphony=1
		add_child(player)
		audio[key] = player
	engine_audio = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://audio/engine.wav").duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 22050
	engine_audio.stream = stream
	engine_audio.volume_db = -20
	add_child(engine_audio)

func afterburner_engaged() -> bool:
	return mode=="flight" and controls.pressed("thrust") and controls.pressed("afterburner") and pilot.outfit_count(157)>0 and pilot.fuel>0 and not hyperdrive.active() and chain_route.is_empty()

func update_afterburner_audio(dt: float) -> void:
	var player: AudioStreamPlayer=audio.maverick_afterburner if pilot.ship_id==900 else audio.afterburner
	var other: AudioStreamPlayer=audio.afterburner if pilot.ship_id==900 else audio.maverick_afterburner
	if other.playing: other.stop()
	if muted or mode!="flight":
		afterburner_audio_gain=0;player.stop();return
	var burning: bool=afterburner_engaged()
	afterburner_audio_gain=move_toward(afterburner_audio_gain,1.0 if burning else 0.0,maxf(0,dt)/(.12 if burning else .22))
	if afterburner_audio_gain<=0: player.stop();return
	player.volume_db=(-11 if pilot.ship_id==900 else -20)+linear_to_db(maxf(.0001,afterburner_audio_gain))
	if not player.playing: player.play()

func title_audio_active() -> bool:
	return mode=="title" or (mode=="controls" and controls_return_mode=="title")

func sync_title_music() -> void:
	if not title_audio_active(): return
	if muted or not controls.intro_music:
		if audio.menu_music.playing: title_music_position=audio.menu_music.get_playback_position()
		audio.menu_music.stop()
	elif not audio.menu_music.playing:
		audio.menu_music.volume_db=-20
		audio.menu_music.play(title_music_position)

func start_title_audio() -> void:
	if mode!="title": return
	title_music_position=audio.menu_music.get_playback_position() if audio.menu_music.playing else 0.0
	if not muted:
		if controls.intro_music and not audio.menu_music.playing:
			audio.menu_music.volume_db=-20;audio.menu_music.play()
		elif not controls.intro_music: audio.menu_music.stop()
		audio.menu_hum.play()

func finish_title_motion() -> void:
	if mode!="title": return
	audio.menu_hum.stop()
	sound("menu_slam")

func stop_title_audio() -> void:
	for key in ["menu_music","menu_hum","menu_slam"]: audio[key].stop()
	title_music_position=0.0

func sound(key: String) -> void:
	if not muted:
		audio[key].play()

func notify(message: String) -> void:
	messages.push_front(message)
	if messages.size() > 4:
		messages.pop_back()

func v3(pos: Vector2, height: float = 0) -> Vector3:
	return Vector3(pos.x, height, pos.y)

func load_system(arrival_heading: Variant = null, preserve_chain: bool = false) -> void:
	fleet_service.end_jump()
	maverick_volley.reset()
	primary_cooldowns.clear();cooldown=0;self_destruct_seconds=0
	missions.approach={};missions.approach_port=-1
	auto_boarding={};last_board_tap=-1000;auto_landing=false;last_land_tap=-1000
	var traveling_fighters: Array=fighter_wing.saved() if fighter_wing.pilot_owner==pilot else pilot.fighter_sorties.duplicate(true)
	traveling_fighters=traveling_fighters.filter(func(f):return int(f.carrier_ship)==pilot.ship_id)
	fighter_wing.pilot_owner=pilot
	world_killer.reset_visuals()
	ejection.reset()
	missions.arrival_delays.clear()
	missions.auxiliary_delays.clear()
	missions.scan_clock=0
	world_activity.abort()
	if arrival_heading==null:
		cloak.set_active(false)
	else:
		# A jump replaces the model, not the running cloaking device.
		cloak.restore_materials()
	if not preserve_chain: chain_route.clear()
	if arrival_heading==null: map_route.clear()
	arsenal.ship_weapons.clear()
	if pilot.selected_weapon >= 10000: pilot.selected_weapon = 128
	hector.banner_time = 0
	interactions.reset()
	if mode in ["comms", "boarding"]: set_mode("flight")
	arsenal.reset_panic()
	hyperdrive.reset()
	jump_visuals.reset()
	if is_instance_valid(engine_audio): engine_audio.stop()
	if audio.has("jump"): audio.jump.stop()
	if audio.has("jump_start"): audio.jump_start.stop()
	if audio.has("arrival"): audio.arrival.stop()
	for key in ["sidewinder_launch","maverick_target","maverick_missile","maverick_gun","forklift","cloak_on","cloak_off"] + Arsenal.PANIC_KEYS + Arsenal.DEATH_KEYS + Arsenal.WEAPON_SOUND_KEYS:
		if key in ["cloak_on","cloak_off"] and arrival_heading!=null: continue
		if audio.has(key): audio[key].stop()
	world_activity.landing_bribes.clear()
	landing_target = -1
	landing_clearance = -1
	docked_id = -1
	if is_instance_valid(world):
		world.queue_free()
	world = Node3D.new()
	add_child(world)
	missile_smoke=preload("res://scripts/sidewinder_smoke.gd").new();world.add_child(missile_smoke)
	engine_smoke=preload("res://scripts/engine_smoke.gd").new();world.add_child(engine_smoke)
	planets.clear()
	npcs.clear()
	escorts.clear()
	shots.clear()
	sparks.clear()
	explosions.clear()
	shield_hits.clear()
	target_index = -1
	var system = catalog.system(pilot.system_id)
	destination = int(system.links[0]) if arrival_heading == null and not system.links.is_empty() else -1
	for id in system.objects:
		if world_killer.destroyed(int(id)): continue
		var obj = catalog.record("objects", int(id))
		var pos = Vector2(obj.fields.xPos, obj.fields.yPos)
		var info = catalog.stellar_type(int(obj.fields.Type))
		var radius: float = StellarModels.radius(info)
		var reconstruction: Dictionary=world_killer.reconstruction(int(id))
		var node: Node3D
		if reconstruction.is_empty(): node=StellarModels.create(world,pos,info,int(id))
		else: node=world_killer.Rebuilt.create(world,v3(pos,-35 if info.kind=="station" else -radius-35),radius,int(id),info.kind=="station",float(reconstruction.progress))
		planets.append({"id": int(id), "name": obj.name, "position": pos, "radius": radius, "node": node,"kind":info.kind})
	environment_hazards.build()
	world_killer.restore_visuals()
	velocity = Vector2.ZERO
	if arrival_heading != null:
		var entry = Hyperspace.arrival(float(arrival_heading), pilot.flight_fields(catalog.record("ships",pilot.ship_id).fields), planets)
		pilot.position = entry.position
		pilot.heading = entry.heading
		velocity = entry.velocity
	# New pilots start beside the first world, including offset primaries.
	elif pilot.position == Vector2(0,330) and not planets.is_empty():
		pilot.position += planets[0].position
	player_model = ShipModels.create(catalog,pilot.ship_id,-1)
	player_base_scale = player_model.scale
	world.add_child(player_model)
	if arrival_heading!=null: preload("res://scripts/maverick.gd").advance_wings(player_model,true,2.0)
	player_model.position = v3(pilot.position)
	player_model.rotation.y = -pilot.heading
	previous_player_position = pilot.position
	previous_player_velocity = velocity
	previous_player_heading = pilot.heading
	physics_step_dt = 0
	rendered_player_position = v3(pilot.position)
	rendered_player_velocity = velocity
	rendered_clock = time
	Models.set_thrust(player_model, 0, time)
	cloak.rebind_model()
	arsenal.restore_captured_fleet()
	for i in traveling_fighters.size():
		arsenal.launch_escort(int(traveling_fighters[i].id),pilot.position,pilot.heading)
		var fighter: Dictionary=escorts.back()
		fighter_wing.apply(fighter,traveling_fighters[i])
		if arrival_heading!=null:
			fighter.arrival_delay=.35+i*.12;fighter.model.hide()
			if fighter.command=="hold": fighter.command="formation"
	if arrival_heading!=null: fleet_service.arrive()
	pilot.fighter_sorties=traveling_fighters.duplicate(true)
	if arrival_heading != null: jump_visuals.arrive()
	update_jump_visuals(0)
	camera.position = v3(pilot.position + velocity * 0.2, 1200)
	traffic.populate()
	missions.enter_system()
	notify("Entered %s · %s" % [system.name, catalog.government(pilot.system_id)])

func spawn_npc(hostile: bool, pos: Vector2, index: int = 0) -> void:
	var id: int = 138 if hostile else (129 if index % 2 == 0 else 131)
	var npc = traffic.spawn(id,130 if hostile else -1,3 if hostile else 1,pos)
	if not npc.is_empty() and hostile: npc.name="Pirate Defender"

func debug_spawn_ship(ship_id: int, faction_id: int) -> bool:
	if mode != "cheats" or pilot.armor <= 0: return false
	var ship = catalog.record("ships",ship_id)
	if ship.is_empty(): return false
	if faction_id == -2: faction_id = int(ship.fields.InherentGovt)
	if faction_id != -1 and catalog.record("governments",faction_id).is_empty(): return false
	var offset = Vector2(0,-420).rotated(pilot.heading+float(npcs.size())*.85)
	var npc = traffic.spawn(ship_id,faction_id,int(ship.fields.InherentAI),pilot.position+offset)
	if npc.is_empty():
		notify("Ship limit reached. Leave the system or clear some contacts first.")
		return false
	target_index = npcs.find(npc)
	notify("Spawned %s · %s" % [npc.name,Factions.name_of(catalog,faction_id)])
	return true

func combat_drill() -> void:
	if mode != "flight":
		return
	for npc in npcs:
		if npc.hostile:
			notify("A hostile contact is already in the area. Tab selects a contact.")
			return
	spawn_npc(true, pilot.position + Vector2(480,-500))
	target_index = npcs.size()-1
	notify("Combat drill: hostile Defender inbound. Tab targets; Space fires your weapon.")

func open_mission_map(entry: Dictionary,preview: bool) -> void:
	var target: int=missions.target_system(entry)
	set_mode("map")
	map_preview_system=target if preview else -1
	map_selected=target
	if target>=0:
		var f: Dictionary=catalog.system(target).fields
		map_center=Vector2(f.xPos,f.yPos)
	hud.rebuild_modal()

func plan_map_stop(id: int) -> void:
	if hyperdrive.active() or not chain_route.is_empty(): return
	var previous: int=pilot.system_id if map_route.is_empty() else int(map_route.back())
	if id not in catalog.system(previous).links: return
	map_route.append(id);destination=int(map_route.front())

func finish_map_hop() -> void:
	if not map_route.is_empty() and int(map_route.front())==pilot.system_id: map_route.pop_front()
	if not map_route.is_empty() and int(map_route.front()) in catalog.system(pilot.system_id).links: destination=int(map_route.front())
	else: map_route.clear()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if mode=="flight" and (event.meta_pressed or event.ctrl_pressed) and event.physical_keycode==KEY_K:
		jettison_cargo(event.alt_pressed);return
	if mode=="flight" and (event.meta_pressed or event.ctrl_pressed) and event.physical_keycode==KEY_D: return
	if event.physical_keycode==KEY_A and mode not in ["title","intro"]:
		autopilot.toggle();return
	if mode=="controls":
		if event.physical_keycode==KEY_ESCAPE: set_mode(controls_return_mode)
		return
	if mode in ["title","intro"]:
		return
	if event.physical_keycode==KEY_CAPSLOCK:
		fast_time=not fast_time;notify("Time acceleration: 2×" if fast_time else "Time acceleration off");return
	if mode=="dock" and hud.port_page=="bar": missions.bar_activity()
	event=controls.remapped(event)
	if autopilot.active() and event.physical_keycode in [KEY_J,KEY_L,KEY_N,KEY_1,KEY_2,KEY_3,KEY_4,KEY_F1,KEY_F2,KEY_F3,KEY_F4]: autopilot.cancel("Manual navigation command.")
	if mode in ["ejecting","rescue"] and event.physical_keycode not in [KEY_F9,KEY_V,KEY_F11]: return
	match event.physical_keycode:
		KEY_ESCAPE:
			if mode == "flight": set_mode("pause")
			elif mode in ["comms", "boarding"]: interactions.close()
			elif mode == "cheats": toggle_cheat_menu()
			elif mode == "fleet": toggle_fleet_menu()
			elif mode in ["pause","info","eject_confirm"]: set_mode("flight")
			elif mode == "map": set_mode(map_return_mode)
			elif mode == "missions": set_mode(missions.return_mode)
			elif mode == "autopilot": set_mode(autopilot.return_mode)
			elif mode == "achievements": set_mode(achievements_return_mode)
			elif mode == "mission_offer": missions.resolve_approach(false)
			elif mode == "mission_report": missions.dismiss_landing_report()
			elif mode=="news": set_mode(world_activity.return_mode)
			elif mode=="world_comms": set_mode("flight")
			elif mode in ["outfitter","shipyard"]: set_mode("dock")
			elif mode == "dock":
				if hud.port_page!="landing": hud.port_page="landing";hud.rebuild_modal()
				else: launch()
		KEY_X:
			if event.shift_pressed: ejection.request()
		KEY_P:
			if mode == "flight": set_mode("info")
			elif mode == "info": set_mode("flight")
		KEY_I:
			if mode in ["flight","dock"]: missions.channel=2
			missions.open()
		KEY_K:
			cloak.toggle()
		KEY_M:
			if mode in ["flight","dock"]: set_mode("map")
			elif mode == "map": set_mode(map_return_mode)
			elif mode=="missions" and not missions.selected.is_empty(): open_mission_map(missions.selected,missions.channel!=2)
		KEY_L:
			if mode == "flight": land_pressed()
			elif mode == "dock": launch()
		KEY_F1, KEY_F2, KEY_F3, KEY_F4:
			if mode=="flight": select_landing_target(event.physical_keycode-KEY_F1)
		KEY_1, KEY_2, KEY_3, KEY_4:
			if mode == "flight": select_landing_target(event.physical_keycode - KEY_1)
		KEY_N:
			if mode=="flight": cycle_destination()
		KEY_J:
			if mode == "flight": start_jump()
		KEY_TAB:
			if mode == "flight":
				var previous=target_index
				target_index = target_index+1 if target_index >= -1 and target_index < npcs.size()-1 else -1
				if previous!=target_index: sound("maverick_target" if pilot.ship_id==900 else "ui_target")
		KEY_Y: interactions.open_hail()
		KEY_B:
			if event.shift_pressed: combat_drill()
			else: board_pressed()
		KEY_C:
			if mode!="map": toggle_cheat_menu()
		KEY_F: toggle_fleet_menu()
		KEY_R:
			if mode=="flight":
				secondary_safe=not secondary_safe;notify("Secondary weapons SAFE" if secondary_safe else "Secondary weapons ARMED")
		KEY_BACKSPACE:
			if mode=="flight": arsenal.recall_fighters()
		KEY_Q:
			if mode == "flight": cycle_weapon(-1)
		KEY_E:
			if mode == "flight": cycle_weapon(-1 if event.alt_pressed else 1)
		KEY_H:
			if mode=="flight": world_activity.open_contact()
		KEY_G: debug_refuel()
		KEY_F5: save_game()
		KEY_F9: load_game()
		KEY_V: toggle_audio()
		KEY_F11:
			var full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and mode == "flight":
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(580, zoom-70)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(1700, zoom+70)

func toggle_audio() -> void:
	muted = not muted
	world_killer.audio_phase=""
	if muted:
		if audio.menu_music.playing: title_music_position=audio.menu_music.get_playback_position()
		engine_audio.stop()
		for a in audio.values(): a.stop()
	elif title_audio_active() and controls.intro_music: audio.menu_music.play(title_music_position)
	for effect in explosions:
		if effect is Breakup: effect.set_audio_state(muted,mode in ["flight","dead"])
	world_killer.set_audio_state(muted,mode=="flight")
	traffic.set_audio_state(muted,mode=="flight")
	notify("Sound off" if muted else "Sound on")

func set_mode(value: String) -> void:
	if value!="flight": maverick_volley.reset()
	if value in ["dead","title","ejecting","rescue"]: autopilot.cancel("Flight ended.",false)
	if value!="flight": auto_boarding={};last_board_tap=-1000;auto_landing=false;last_land_tap=-1000;self_destruct_seconds=0
	if value=="flight" and pilot.strict_dead: value="dead"
	if value=="outfitter" and mode!="outfitter": outfitter.begin_visit()
	if value!="title" and not (value=="controls" and controls_return_mode=="title"): stop_title_audio()
	if value=="map" and mode!="map":
		map_return_mode=mode if mode in ["missions","dock"] else "flight"
		map_preview_system=-1;map_selected=pilot.system_id;map_center=Vector2(INF,INF)
	if value in ["dock","dead"]: cloak.set_active(false)
	mode = value
	if value=="flight": hud.port_page="landing"
	engine_audio.stop()
	death_reveal_time = 0.9 if value == "dead" else 0.0
	if value == "dead": cancel_jump(false)
	for key in ["death_star_warp","death_star_charge","death_star_fire"]: audio[key].stream_paused=value!="flight"
	if audio.has("jump"): audio.jump.stream_paused = value != "flight"
	if audio.has("jump_start"): audio.jump_start.stream_paused=value!="flight"
	if audio.has("arrival"): audio.arrival.stream_paused = value != "flight"
	for key in ["maverick_warp","sidewinder_launch","maverick_target","maverick_missile","maverick_gun","forklift","cloak_on","cloak_off"] + Arsenal.PANIC_KEYS + Arsenal.DEATH_KEYS + Arsenal.WEAPON_SOUND_KEYS: audio[key].stream_paused=value!="flight"
	if value=="dead":
		for key in Arsenal.DEATH_KEYS: audio[key].stream_paused=false
	for effect in explosions:
		if effect is Breakup: effect.set_audio_state(muted,value in ["flight","dead"])
	world_killer.set_audio_state(muted,value=="flight")
	traffic.set_audio_state(muted,value=="flight")
	if is_instance_valid(hud): hud.rebuild_modal()

func _physics_process(dt: float) -> void:
	if advance_self_destruct(dt, (Input.is_physical_key_pressed(KEY_META) or Input.is_physical_key_pressed(KEY_CTRL)) and Input.is_physical_key_pressed(KEY_D)): return
	dt*=controls.speed*(2.0 if fast_time else 1.0)
	ejection.advance(dt)
	if mode=="flight" and autopilot.active() and (controls.pressed("left") or controls.pressed("right") or controls.pressed("thrust") or controls.pressed("retrograde")):
		autopilot.cancel("Manual flight controls.")
	autopilot.tick(dt)
	if mode in ["flight", "dead", "ejecting"]:
		update_shields(dt)
		update_explosions(dt)
		update_sparks(dt)
		missile_smoke.advance(dt)
		engine_smoke.advance(dt)
	if mode == "dead" and death_reveal_time > 0:
		death_reveal_time = maxf(0,death_reveal_time-dt)
		if death_reveal_time == 0: hud.rebuild_modal()
	if mode != "flight": return
	environment_hazards.advance(dt)
	world_killer.advance(dt)
	if mode!="flight": return
	var recovery_before: int=int(floor(recovery_clock+.000001))
	recovery_clock+=dt*Flight.REFERENCE_HZ
	recovery_window=Vector2i(recovery_before,int(floor(recovery_clock+.000001)))
	cloak.advance(dt)
	missions.advance(dt)
	world_activity.advance(dt)
	if not chain_route.is_empty() and not hyperdrive.active():
		previous_player_position = pilot.position
		previous_player_velocity = velocity
		previous_player_heading = pilot.heading
		physics_step_dt = dt
		time += dt
		var travel_dt: float = minf(dt,chain_timer)
		var blast_start: Vector2 = pilot.position
		pilot.position += velocity*travel_dt
		player_model.position = v3(pilot.position)
		chain_timer -= dt
		apply_hyperspace_wake(blast_start,pilot.position)
		Models.set_thrust(player_model,1.6*cloak.visibility_factor(),time,true)
		if chain_timer <= 0:
			chain_hop()
		else:
			update_npcs(dt)
			arsenal.update_escorts(dt)
			update_shots(dt)
		return
	previous_player_position = pilot.position
	previous_player_velocity = velocity
	previous_player_heading = pilot.heading
	physics_step_dt = dt
	time += dt
	cooldown = Flight.reload_remaining(cooldown,dt,controls.pressed("fire") or controls.pressed("secondary_fire"))
	for weapon in primary_cooldowns: primary_cooldowns[weapon]=Flight.reload_remaining(float(primary_cooldowns[weapon]),dt,controls.pressed("fire"))
	damage_clock += dt
	var turn: float = controls.turn()
	var thrust: bool = controls.pressed("thrust")
	var retrograde: bool = controls.pressed("retrograde")
	var fields: Dictionary = pilot.flight_fields(catalog.record("ships",pilot.ship_id).fields)
	var afterburning: bool = afterburner_engaged()
	if afterburning:
		fields.Speed *= traffic.maverick.AFTERBURNER_SPEED if pilot.ship_id==900 else 1.8
		fields.Accel *= traffic.maverick.AFTERBURNER_ACCEL if pilot.ship_id==900 else 2.0
		if not pilot.cheat_infinite_fuel: pilot.fuel = maxf(0,pilot.fuel-10*dt)
	if pilot.outfit_count(168) > 0: pilot.fuel = minf(pilot.fuel_capacity(),pilot.fuel+dt)
	if auto_landing and (not is_zero_approx(turn) or thrust or retrograde):
		auto_landing=false;notify("Auto landing canceled: manual controls.")
	if not auto_boarding.is_empty() and (not is_zero_approx(turn) or thrust or retrograde):
		auto_boarding={};notify("Auto boarding canceled: manual controls.")
	var previous_phase: String = hyperdrive.phase
	var step: Dictionary
	var engine_throttle: float = (1.6 if afterburning else 1.0) if thrust else 0.0
	if hyperdrive.active():
		step = hyperdrive.step(pilot.position, velocity, pilot.heading, fields, dt)
		engine_throttle = step.thrust
	elif not auto_boarding.is_empty():
		step=auto_boarding_step(fields,dt)
		engine_throttle=1.0 if (step.velocity-velocity).length()>0.01 else 0.0
	elif auto_landing:
		step=auto_landing_step(fields,dt)
		engine_throttle=1.0 if (step.velocity-velocity).length()>0.01 else 0.0
	elif autopilot.active() and autopilot.steering:
		step=autopilot.helm(fields,dt)
		engine_throttle=1.0 if (step.velocity-velocity).length()>0.01 else 0.0
	else:
		if controls.pressed("face_target") and is_zero_approx(turn) and not retrograde:
			turn = target_facing_turn(fields,dt)
		step = Flight.step(pilot.position, velocity, pilot.heading, turn, thrust, retrograde, fields, dt)
	pilot.position = step.position
	velocity = step.velocity
	apply_hyperspace_wake(previous_player_position,pilot.position)
	pilot.heading = step.heading
	player_model.position = v3(pilot.position)
	player_model.rotation.y = -pilot.heading
	if hyperdrive.active():
		# Clearance gates preparation, including the spool-to-burn transition.
		# Once the departure burn begins, crossing a world on the warp line must
		# not abort the jump and strand the ship at hyperspace speed in this system.
		var obstacle = {} if previous_phase == "accelerating" or not chain_route.is_empty() else Travel.hyperspace_obstacle(pilot.position, planets)
		if not obstacle.is_empty():
			cancel_jump(false)
			notify("Hyperspace canceled: too close to %s. No fuel used." % obstacle.body.name)
		else:
			if hyperdrive.phase != previous_phase and hyperdrive.phase == "spooling":
				# Original Warp Up begins once stopped and aligned, and continues through the burn.
				sound("jump_start")
			if step.complete:
				if not chain_route.is_empty():
					chain_hop()
					return
				var arrival_heading: float = hyperdrive.heading
				if pilot.jump(hyperdrive.destination, catalog.system(pilot.system_id).links):
					missions.jumped()
					load_system(arrival_heading)
					finish_map_hop()
					# Trigger on the system-transition tick, after the departure sound stops.
					sound("arrival")
					notify("Arrival at cruise speed. S / Down faces against drift; W / Up slows you down.")
					save_game(false)
				else:
					cancel_jump()
				return
	if not auto_boarding.is_empty() and interactions.boarding_reason(auto_boarding).is_empty():
		target_index=npcs.find(auto_boarding);auto_boarding={}
		interactions.board();return
	if auto_landing:
		var port: Dictionary=selected_planet()
		if not port.is_empty() and pilot.position.distance_to(port.position)<=port.radius and velocity.length()<=Travel.MAX_LANDING_SPEED:
			auto_landing=false;land();return
	Models.set_thrust(player_model, engine_throttle*cloak.visibility_factor(), time, hyperdrive.phase == "accelerating",afterburning)
	var volley_input: bool=maverick_volley.update(controls.pressed("fire"),dt)
	if controls.pressed("fire") and not volley_input:
		for volley in 8:
			if shots.size()>=160 or not fire_trigger(): break
	if controls.pressed("secondary_fire") and not secondary_safe and self_destruct_seconds==0 and not Input.is_physical_key_pressed(KEY_META) and not ((Input.is_physical_key_pressed(KEY_CTRL)) and (Input.is_physical_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_D))):
		var secondary: Array=arsenal.secondary_ids()
		if not secondary.is_empty():
			if pilot.selected_weapon not in secondary: pilot.selected_weapon=int(secondary[0])
			for volley in 8:
				if shots.size()>=160 or not fire_player(): break
	if not cloak.active:
		var recovered: Vector2=Combat.recover(pilot.shield,pilot.armor,pilot.max_shield(),pilot.max_armor(),Combat.recovery_pulses(recovery_window,pilot.shield_recharge()))
		pilot.shield=recovered.x;pilot.armor=recovered.y
	update_npcs(dt)
	arsenal.update_escorts(dt)
	update_shots(dt)
	autosave_clock += dt
	if autosave_clock > 45 and pilot.armor > 0:
		autosave_clock = 0
		save_game(false)

func _process(dt: float) -> void:
	update_afterburner_audio(dt)
	traffic.maverick.advance_warp(self,dt)
	traffic.maverick.advance_victory_fade()
	arsenal.advance_gun_audio(dt)
	if mode=="flight":
		missions.flight_alert_seconds=maxf(0,missions.flight_alert_seconds-dt)
		world_activity.hunter_alert_seconds=maxf(0,world_activity.hunter_alert_seconds-dt)
	missions.advance_bar(dt)
	if mode in ["flight","dock","missions","mission_report"]:
		achievement_clock+=dt
		if achievement_clock>=1:
			achievement_clock=0
			if achievements.update(): save_game(false)
	dt*=controls.speed*(2.0 if fast_time else 1.0) if mode in ["flight","dead","ejecting"] else 1.0
	if not is_instance_valid(player_model): return
	if mode == "flight":
		for body in planets: StellarModels.advance_rotation(body.node,dt)
		update_player_render(Engine.get_physics_interpolation_fraction())
		camera.position = camera.position.lerp(rendered_player_position + v3(rendered_player_velocity*0.2,1200), 1-exp(-dt*5))
		camera.size = lerpf(camera.size, zoom, 1-exp(-dt*7))
	update_jump_visuals(dt)
	if mode=="flight": cloak.update_visual(dt)
	var quake: float=world_killer.shake*2.5 if mode=="flight" else 0.0
	camera.h_offset=0.15*camera.size+sin(time*81.0)*quake
	camera.v_offset=cos(time*67.0)*quake*.6
	space_material.set_shader_parameter("drift", Vector2(camera.position.x,camera.position.z))
	space_material.set_shader_parameter("view_height", camera.size)
	# Fixed camera coordinates already freeze the stars in menus. Keep their
	# current trail shape while paused instead of collapsing the exposure.
	space_material.set_shader_parameter("ship_velocity", velocity)
	if screenshot_timer >= 0:
		screenshot_timer -= dt
		if screenshot_timer < 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(screenshot_path)
			print("Screenshot saved: ", screenshot_path)
			get_tree().quit()

func update_player_render(alpha: float) -> void:
	# Ship and camera follow the same interpolated simulation pose. Rendering
	# the ship at 60 Hz but following it with a faster camera caused visible jitter.
	rendered_player_position = v3(previous_player_position.lerp(pilot.position,alpha))
	rendered_player_velocity = previous_player_velocity.lerp(velocity,alpha)
	rendered_clock = time-physics_step_dt*(1.0-alpha)
	player_model.rotation.y = -lerp_angle(previous_player_heading,pilot.heading,alpha)

func chain_stretch_strength() -> float:
	if chain_route.is_empty() or hyperdrive.active(): return 0.0
	var progress: float = clampf(1.0-chain_timer/CHAIN_STRETCH_SECONDS,0.0,1.0)
	return progress*progress*(3.0-2.0*progress)

func apply_hyperspace_wake(start: Vector2, end: Vector2) -> void:
	var cruise: float = pilot.flight_fields(catalog.record("ships",pilot.ship_id).fields).Speed
	if not pilot.cheat_chain_jump or velocity.length() <= cruise*1.5: return
	if hyperdrive.phase!="accelerating" and chain_route.is_empty(): return
	for npc in npcs.duplicate():
		if npc.has("fleet_uid") or npc.get("player_ally",false): continue
		if segment_distance(npc.position,start,end) <= CHAIN_BLAST_RADIUS+npc.radius:
			damage_npc(npc,npc.health+1,{},Vector2.ZERO,true)

func update_jump_visuals(dt: float) -> void:
	if mode == "flight": jump_visuals.advance(dt)
	if is_instance_valid(player_model):
		var visual_scale: Vector3 = jump_visuals.ship_scale(hyperdrive)
		var rapid_stretch: float = chain_stretch_strength()
		if rapid_stretch > 0:
			var length: float = lerpf(1.0,JumpVisuals.MAX_LENGTH,rapid_stretch)
			visual_scale = Vector3(pow(length,-0.32),1.0,length)
		if mode=="flight": preload("res://scripts/maverick.gd").advance_wings(player_model,hyperdrive.active() or not chain_route.is_empty() or afterburner_engaged(),dt)
		player_model.scale = player_base_scale*visual_scale
		var vibration: Vector3 = jump_visuals.ship_offset(hyperdrive,rendered_clock)
		player_model.position = rendered_player_position + Basis(Vector3.UP,player_model.rotation.y)*vibration
	space_material.set_shader_parameter("warp_stretch",maxf(jump_visuals.departure_strength(hyperdrive),chain_stretch_strength()))

func target_facing_turn(fields: Dictionary, dt: float) -> float:
	var target: Dictionary = selected_contact()
	if target.is_empty(): target = selected_planet()
	if target.is_empty(): return 0.0
	var offset: Vector2 = target.position-pilot.position
	if offset.is_zero_approx(): return 0.0
	return Flight.steering(pilot.heading,Flight.facing(offset),fields,dt)

func update_npcs(dt: float) -> void:
	traffic.update(dt)

func fire_trigger() -> bool:
	return fire_primary() if controls.classic_fire else fire_player()

func fire_primary() -> bool:
	if mode!="flight" or hyperdrive.active() or not chain_route.is_empty() or (cloak.active and not pilot.cheat_cloak): return false
	var fired: bool=false
	for id in arsenal.available_ids():
		if arsenal.is_secondary(id) or float(primary_cooldowns.get(id,0))>0: continue
		var mounts: int=pilot.lasers if id==128 else 0
		for outfit_id in pilot.outfits:
			var f: Dictionary=catalog.record("outfits",int(outfit_id)).fields
			if int(f.ModType)==1 and int(f.ModVal)==id: mounts+=int(pilot.outfits[outfit_id])
		mounts=maxi(1,mounts)
		var emitted: bool=false
		for mount in mounts:
			var lateral: Vector2=Vector2(cos(pilot.heading),sin(pilot.heading))*((mount-(mounts-1)*.5)*8)
			if arsenal.fire(id,pilot.position+lateral,pilot.heading): emitted=true
		if emitted:
			primary_cooldowns[id]=float(primary_cooldowns.get(id,0))+maxf(Flight.WEAPON_TICK_SECONDS,float(catalog.field("weapons",id,"Reload"))*Flight.WEAPON_TICK_SECONDS)
			fired=true
	return fired

func jettison_cargo(ordinary_only: bool=false) -> void:
	if mode!="flight" or hyperdrive.active() or not chain_route.is_empty(): return
	autopilot.cancel("Cargo jettisoned.",false)
	var dropped: int=0
	for i in pilot.cargo.size(): dropped+=int(pilot.cargo[i]);pilot.cargo[i]=0
	if not ordinary_only:
		if not pilot.mission.is_empty(): dropped+=5;pilot.mission={}
		for m in pilot.campaign.active.duplicate():
			if int(m.qty)>0 and m.picked and not m.delivered:
				dropped+=int(m.qty)
				missions.finish(m,false,true,false,"Mission cargo was jettisoned.")
	if dropped>0: burst(pilot.position,Color("a9b3bc"),mini(40,dropped+4))
	notify("Jettisoned %d t%s." % [dropped," of ordinary cargo; mission cargo retained" if ordinary_only else " of cargo"])
	save_game(false)

func advance_self_destruct(real_dt: float, held: bool) -> bool:
	if mode!="flight" or not held:
		if self_destruct_seconds>0: notify("Self-destruct canceled.")
		self_destruct_seconds=0;return false
	var previous: int=ceili(self_destruct_seconds)
	self_destruct_seconds+=real_dt
	if previous==0 or ceili(self_destruct_seconds)!=previous: notify("SELF-DESTRUCT · %d seconds · release Cmd+D to cancel" % maxi(0,ceili(10-self_destruct_seconds)))
	if self_destruct_seconds<10: return false
	self_destruct_seconds=0
	pilot.shield=0;pilot.armor=0
	if pilot.strict: pilot.strict_dead=true;save_game(false)
	ship_explosion(player_model,pilot.position,velocity)
	player_model.hide();set_mode("dead")
	return true

func fire_player() -> bool:
	if cloak.active and not pilot.cheat_cloak: return false
	if arsenal.available_ids().is_empty(): return false
	if mode != "flight" or not chain_route.is_empty() or hyperdrive.active() or cooldown > 0: return false
	var weapon: int = pilot.selected_weapon if pilot.selected_weapon in arsenal.available_ids() else int(arsenal.available_ids()[0])
	if secondary_safe and arsenal.is_secondary(weapon): return false
	var ammo: int = outfitter.ammo_id(weapon) if weapon < 10000 else -1
	if not pilot.cheat_all_weapons and ammo >= 0 and outfitter.count(ammo) == 0:
		notify("Out of ammunition. Visit an outfitter to reload.")
		return false
	var fuel_cost: int=maxi(0,-int(catalog.field("weapons",weapon,"AmmoType"))-1000) if weapon<10000 else 0
	if not pilot.cheat_infinite_fuel and pilot.fuel<fuel_cost: return false
	if not arsenal.fire(weapon,pilot.position,pilot.heading): return false
	if not pilot.cheat_infinite_fuel: pilot.fuel-=fuel_cost
	if not pilot.cheat_all_weapons and ammo >= 0:
		pilot.outfits[str(ammo)] = outfitter.count(ammo)-1
		if pilot.outfits[str(ammo)] == 0: pilot.outfits.erase(str(ammo))
	var period: float = 0.5 if weapon >= 10000 else maxf(Flight.WEAPON_TICK_SECONDS,float(catalog.field("weapons",weapon,"Reload")) * Flight.WEAPON_TICK_SECONDS)
	if weapon==128: period /= 1.0 + 0.35*(pilot.lasers-1)
	elif weapon < 10000:
		for id in pilot.outfits:
			var outfit: Dictionary = catalog.record("outfits",int(id)).fields
			if int(outfit.ModType) == 1 and int(outfit.ModVal) == weapon:
				period /= 1.0+0.35*(int(pilot.outfits[id])-1)
	cooldown+=period
	return true

func fire(pos: Vector2, heading: float, enemy: bool, weapon: int = 128) -> void:
	arsenal.fire(weapon,pos,heading,enemy)

func selected_contact() -> Dictionary:
	if target_index < 0 or target_index >= npcs.size(): return {}
	var contact: Dictionary = npcs[target_index]
	if not is_instance_valid(contact.model) or contact.health <= 0: return {}
	return contact

func segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))

# First surface crossed by a swept projectile, independent of contact list order.
static func shot_entry_distance(center: Vector2, start: Vector2, end: Vector2, radius: float) -> float:
	if start.distance_squared_to(center)<=radius*radius: return 0.0
	var segment: Vector2=end-start
	var length: float=segment.length()
	if length<=0: return INF
	var direction: Vector2=segment/length
	var projection: float=(center-start).dot(direction)
	var perpendicular: float=absf((center-start).cross(direction))
	if projection<0 or perpendicular>radius: return INF
	var entry: float=projection-sqrt(maxf(0,radius*radius-perpendicular*perpendicular))
	return entry if entry<=length else INF

func damage_npc(npc: Dictionary, amount: float, attacker: Dictionary = {}, impact_direction: Vector2 = Vector2.ZERO, hyperspace_wake: bool = false, armor_damage: float = -1, weapon_id: int = -1) -> Node3D:
	if npc not in npcs or (amount <= 0 and armor_damage<=0 and weapon_id!=903): return null
	var boarding_required: bool=missions.needs_boarding(npc)
	# Warp wake is incidental, and autonomous weapons must leave a boardable
	# hull. Direct player fire remains capable of failing the objective.
	if boarding_required and hyperspace_wake: return null
	if boarding_required and not attacker.is_empty() and float(npc.get("age",0))<8.0: return null
	var hector_sidewinder: bool=npc.get("hector",false) and weapon_id==901
	if (npc.get("hector",false) or npc.get("invulnerable",false)) and not hector_sidewinder:
		show_shield(npc.model,impact_direction)
		return null
	if npc.health > npc.max_health - npc.shield_capacity:
		var direction: Vector2 = impact_direction
		if direction == Vector2.ZERO: direction = (pilot.position if attacker.is_empty() else attacker.position)-npc.position
		show_shield(npc.model,direction)
	if hector_sidewinder:
		amount=maxf(amount,float(npc.health)+1);armor_damage=amount
		hector.banner_time=0
	if weapon_id!=903:
		Combat.apply(npc,amount,amount if armor_damage<0 else armor_damage)
		if boarding_required and not attacker.is_empty():
			var armor_capacity: float=maxf(0,float(npc.max_health)-float(npc.shield_capacity))
			if npc.health<=0 or (npc.shield<=0 and npc.armor<=armor_capacity*.1):
				npc.armor=maxf(1,armor_capacity*.1);npc.health=float(npc.shield)+float(npc.armor)
				interactions.disable(npc,attacker.has("fleet_uid") or attacker.get("player_ally",false))
	if (attacker.is_empty() or attacker.has("fleet_uid") or attacker.get("player_ally",false)) and not hyperspace_wake:
		persons.attacked(npc)
		npc.truce=false
		npc.refuel_order={}
		if not npc.crime_reported:
			Factions.penalize(catalog,pilot,npc.faction,"ShootPenalty")
			npc.crime_reported=true
		npc.hostile=true;npc.provoked=true
		for ally in npcs:
			if ally.ai>=3 and Factions.allied(catalog,ally.faction,npc.faction):
				ally.truce=false
				ally.provoked=true;ally.hostile=true
	elif not attacker.is_empty():
		npc.nemesis=attacker.model
	if weapon_id==903:
		burst(npc.position,Color("55cfff"),28)
		interactions.disable(npc,attacker.is_empty())
		return null
	burst(npc.position,Color("ffb174"),7)
	if npc.health > 0 and Combat.is_disabled(npc):
		interactions.disable(npc, attacker.is_empty() and not hyperspace_wake)
	if npc.health <= 0:
		if (attacker.is_empty() or attacker.has("fleet_uid") or attacker.get("player_ally",false)) and not hyperspace_wake: Factions.player_kill(catalog,pilot,npc.faction,int(npc.id))
		var selected: Dictionary = npcs[target_index] if target_index >= 0 and target_index < npcs.size() else {}
		var wreck: Node3D=ship_explosion(npc.model,npc.position,npc.velocity)
		npc.model.queue_free()
		npcs.erase(npc)
		target_index = npcs.find(selected) if selected != npc else -1
		fleet_service.destroyed(npc)
		missions.actor_event(npc,"kill")
		persons.destroyed(npc)
		world_activity.resolved(npc)
		if (attacker.is_empty() or attacker.has("fleet_uid") or attacker.get("player_ally",false)) and not hyperspace_wake: pilot.campaign.rating+=maxi(1,int(catalog.field("ships",int(npc.id),"Crew")))
		if pilot.ship_id==900 and attacker.is_empty() and not hyperspace_wake: traffic.maverick.celebrate(self)
		world_activity.hunter_destroyed(npc,attacker.is_empty() or attacker.has("fleet_uid") or attacker.get("player_ally",false))
		notify("Contact destroyed.")
		return wreck
	return null

func damage_player(amount: float, impact_direction: Vector2 = Vector2.UP, armor_damage: float=-1) -> void:
	if (amount<=0 and armor_damage<=0) or mode!="flight": return
	if pilot.cheat_invincibility:
		show_shield(player_model,impact_direction)
		return
	damage_clock=0
	if pilot.shield>0:
		show_shield(player_model,impact_direction)
	var remaining: Vector2=Combat.hit(pilot.shield,pilot.armor,amount,amount if armor_damage<0 else armor_damage)
	pilot.shield=remaining.x;pilot.armor=remaining.y
	burst(pilot.position,Color("78d9ff"),8)
	sound("impact")
	if pilot.armor<=0 and pilot.shield<=0:
		if ejection.begin(true): return
		if pilot.strict:
			pilot.strict_dead=true;save_game(false)
		ship_explosion(player_model,pilot.position,velocity)
		player_model.hide()
		set_mode("dead")

func update_shots(dt: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		if mode != "flight": break
		var shot = shots[i]
		if shot.kind == "ship_ram":
			if arsenal.update_ship_ram(shot,dt): shots.remove_at(i)
			continue
		var travel_dt: float=minf(maxf(0,dt),maxf(0,shot.life))
		arsenal.steer(shot,travel_dt)
		shot.visual_age=float(shot.get("visual_age",0))+travel_dt
		arsenal.ProjectileModels.advance(shot.node,shot.visual_age)
		arsenal.warn_lethal_impact(shot)
		var previous: Vector2 = shot.position
		shot.position += shot.velocity*travel_dt
		if int(shot.get("weapon",-1))==901: missile_smoke.emit_segment(shot,previous,shot.position)
		var end_position: Vector2=shot.position
		if shot.kind != "beam_visual": shot.node.position = v3(shot.position,6)
		shot.life = Flight.reload_remaining(shot.life,dt)
		var hit: bool = false
		var contact: Dictionary = {}
		var rock: Dictionary={}
		if shot.kind not in ["flare","beam_visual"]:
			rock=environment_hazards.obstruction(previous,shot.position)
			if not rock.is_empty(): shot.position=rock.position
		if shot.kind not in ["flare","beam_visual"]:
			if shot.enemy or (pilot.cheat_deflection and shot.get("npc_shot",false)):
				if segment_distance(pilot.position,previous,shot.position) < 22+shot.proximity:
					if pilot.cheat_deflection:
						deflect_shot(shot,previous)
						continue
					hit = true
					damage_player(shot.get("shield_damage",shot.damage),-shot.velocity.normalized(),shot.get("armor_damage",shot.damage))
			if shot.enemy and not hit:
				var nearest_fighter: Dictionary={}
				var fighter_distance: float=INF
				for fighter in escorts:
					if fighter.get("captured",false) or not fighter.model.visible: continue
					var entry: float=shot_entry_distance(fighter.position,previous,shot.position,18+shot.proximity)
					if entry<fighter_distance: fighter_distance=entry;nearest_fighter=fighter
				if not nearest_fighter.is_empty():
					hit=true;shot.position=previous+(shot.position-previous).normalized()*fighter_distance
					arsenal.damage_fighter(nearest_fighter,shot.get("shield_damage",shot.damage),shot.get("armor_damage",shot.damage))
			if not hit and (not shot.enemy or shot.get("npc_shot",false)):
				var closest: float=INF
				for npc in npcs:
					if not traffic.can_hit(shot,npc): continue
					var distance: float=shot_entry_distance(npc.position,previous,shot.position,npc.radius+shot.proximity)
					if distance<closest:
						closest=distance;contact=npc
				if not contact.is_empty():
					hit=true
					shot.position=previous+(shot.position-previous).normalized()*closest
		var world_hit: Dictionary=world_killer.shot_intersection(previous,shot.position,shot)
		if not world_hit.is_empty() and (contact.is_empty() or float(world_hit.distance)<previous.distance_to(shot.position)):
			shot.position=world_hit.position;contact={};hit=true
			if int(shot.weapon)!=903: world_killer.hit_target(shot.position)
		hit=hit or not rock.is_empty()
		if hit or shot.life <= 0:
			if not contact.is_empty():
				var wreck: Node3D=damage_npc(contact,shot.get("shield_damage",shot.damage),shot.get("source",{}),-shot.velocity.normalized(),false,shot.get("armor_damage",shot.damage),int(shot.weapon))
				if int(shot.weapon)==191 and wreck is Breakup and shot.life>0:
					# The forklift tore the hull apart: carry its momentum through it.
					shot.position=end_position;shot.node.position=v3(end_position,6)
					shot.kind="bolt";shot.target=null;shot.reflected=false
					continue
			if shot.blast > 0 and shot.kind != "beam_visual":
				burst(shot.position,shot.color,24)
				sound("heavy_explosion")
				if not shot.enemy or shot.get("npc_shot",false):
					for npc in npcs.duplicate():
						if npc != contact and traffic.can_hit(shot,npc) and npc.position.distance_to(shot.position) <= shot.blast:
							damage_npc(npc,shot.get("shield_damage",shot.damage),shot.get("source",{}),Vector2.ZERO,false,shot.get("armor_damage",shot.damage))
			shot.node.queue_free()
			shots.remove_at(i)

func ship_explosion(model: Node3D, pos: Vector2, motion: Vector2, size_multiplier: float = 1.0) -> Node3D:
	var split: bool = randf() < breakup_chance
	sound("impact" if split else "explosion")
	arsenal.stop_panic_for({"model":model})
	arsenal.death_cry({"health":0,"position":pos,"id":model.get_meta("ship_id",128),"faction":model.get_meta("faction_id",-1)})
	if explosions.size() >= MAX_EXPLOSIONS:
		explosions.pop_front().queue_free()
	var effect = Breakup.new() if split else Explosion.new()
	if split: effect.secondary_blast.connect(func(): sound("explosion"))
	world.add_child(effect)
	effect.position = v3(pos)
	effect.setup(model,motion,-1,size_multiplier)
	if split: effect.start_crew_audio(arsenal.panic_group(int(model.get_meta("faction_id",-1)))=="alien",muted,mode in ["flight","dead"])
	explosions.append(effect)
	return effect

func show_shield(model: Node3D, direction: Vector2) -> void:
	var effect = model.get_node_or_null("ShieldHit")
	if effect == null:
		effect = ShieldHit.new()
		effect.setup(model)
		shield_hits.append(effect)
	effect.flash(direction)

func update_shields(dt: float) -> void:
	for i in range(shield_hits.size()-1,-1,-1):
		if not is_instance_valid(shield_hits[i]): shield_hits.remove_at(i)
		else: shield_hits[i].advance(dt)

func update_explosions(dt: float) -> void:
	for i in range(explosions.size()-1,-1,-1):
		if explosions[i].advance(dt):
			explosions[i].queue_free()
			explosions.remove_at(i)

func burst(pos: Vector2, color: Color, count: int) -> void:
	for i in count:
		var dir = Vector2.from_angle(randf()*TAU)
		var node = Models.box(world,v3(pos,8),Vector3.ONE*randf_range(1.5,4),Models.material(color,0,2))
		sparks.append({"node":node,"position":pos,"velocity":dir*randf_range(40,210),"life":randf_range(.2,.8)})

func update_sparks(dt: float) -> void:
	for i in range(sparks.size()-1,-1,-1):
		var spark = sparks[i]
		spark.life -= dt
		spark.position += spark.velocity * dt
		spark.node.position = v3(spark.position,8)
		spark.node.scale *= 1-dt
		if spark.life <= 0:
			spark.node.queue_free()
			sparks.remove_at(i)

func nearest_planet() -> Dictionary:
	var best: Dictionary = {}
	var distance: float = INF
	for p in planets:
		var d: float = pilot.position.distance_to(p.position)
		if d < distance:
			distance = d
			best = p
	return best

func selected_planet() -> Dictionary:
	for planet in planets:
		if planet.id == landing_target: return planet
	return {}

func select_landing_target(index: int) -> void:
	if mode != "flight" or not chain_route.is_empty() or hyperdrive.active() or index < 0 or index >= planets.size(): return
	var planet: Dictionary = planets[index]
	if landing_target != planet.id:
		auto_boarding={}
		auto_landing=false
		landing_target = planet.id
		landing_clearance = -1
		sound("ui_select")
	notify("Selected %s · L to request landing clearance." % planet.name if landing_clearance != planet.id else "Clearance retained for %s." % planet.name)

func landing_guidance() -> String:
	if autopilot.active(): return "Autopilot · "+autopilot.status+" · A cancels"
	if not auto_boarding.is_empty(): return "Auto boarding · %s · B or steering cancels" % auto_boarding.get("name","ship")
	if auto_landing: return "Auto landing · %s · L or steering cancels" % selected_planet().get("name", "destination")
	var planet = selected_planet()
	if planet.is_empty():
		planet = nearest_planet()
		return "L requests clearance at %s · 1–4 select a world" % planet.name if not planet.is_empty() else "No landing destinations in this system."
	if landing_clearance != planet.id:
		return "%s selected · L to request clearance" % planet.name
	var distance: float = pilot.position.distance_to(planet.position) - planet.radius
	if distance > 0:
		return "Cleared for %s · fly over the blue brackets · %d km to edge" % [planet.name, ceili(distance)]
	if velocity.length() > Travel.MAX_LANDING_SPEED:
		return "Cleared for %s · S / Down turns against drift; W / Up slows you · speed ≤ %d" % [planet.name, Travel.MAX_LANDING_SPEED]
	return "Cleared for %s · L again to land" % planet.name

func board_pressed() -> void:
	if not auto_boarding.is_empty():
		auto_boarding={};last_board_tap=-1000;notify("Auto boarding canceled.");return
	if mode!="flight":
		interactions.board();return
	var now: int=Time.get_ticks_msec()
	var double_tap: bool=now-last_board_tap<=350
	last_board_tap=now
	if not double_tap:
		interactions.board();return
	last_board_tap=-1000
	var target: Dictionary=selected_contact()
	if not target.is_empty() and interactions.boarding_reason(target).is_empty():
		interactions.board();return
	if target.is_empty() or not target.get("disabled",false) or target.get("player_ally",false) or target.has("fleet_uid") or hyperdrive.active() or not chain_route.is_empty():
		notify("Auto boarding requires a selected disabled ship.");return
	autopilot.cancel("Auto boarding",false)
	auto_landing=false;auto_boarding=target
	notify("Auto boarding %s · B or steering cancels." % target.name)

func auto_boarding_step(fields: Dictionary, dt: float) -> Dictionary:
	var target: Dictionary=auto_boarding
	if not target in npcs or not is_instance_valid(target.get("model")) or target.health<=0 or not target.get("disabled",false) or selected_contact()!=target:
		auto_boarding={};notify("Auto boarding canceled: target unavailable.")
		return Flight.step(pilot.position,velocity,pilot.heading,0,false,false,fields,dt)
	var offset: Vector2=target.position-pilot.position
	var acceleration: float=maxf(1,Flight.acceleration(fields))
	var desired_speed: float=minf(float(fields.Speed)*.6,minf(offset.length()*.6,sqrt(2*acceleration*offset.length())*.4))
	var correction: Vector2=target.velocity+offset.normalized()*desired_speed-velocity
	var settling: bool=offset.length()<maxf(25,target.radius)*.65 and velocity.distance_to(target.velocity)<3
	var heading: float=target.heading if settling else (Flight.facing(correction) if correction.length()>1 else pilot.heading)
	var turn: float=Flight.steering(pilot.heading,heading,fields,dt)
	var aligned: bool=absf(angle_difference(pilot.heading,heading))<.12
	return Flight.step(pilot.position,velocity,pilot.heading,turn,not settling and aligned and correction.length()>1,false,fields,dt,minf(1,correction.length()/(acceleration*dt)))

func land_pressed() -> void:
	auto_boarding={}
	var now: int=Time.get_ticks_msec()
	if auto_landing:
		auto_boarding={};last_board_tap=-1000;auto_landing=false;last_land_tap=-1000;notify("Auto landing canceled.");return
	var double_tap: bool=now-last_land_tap<=350
	last_land_tap=now
	if not double_tap:
		land();return
	last_land_tap=-1000
	if mode!="flight" or hyperdrive.active() or not chain_route.is_empty(): return
	var port: Dictionary=selected_planet()
	if port.is_empty(): port=nearest_planet()
	if port.is_empty(): return
	var refusal: String=world_activity.landing_reason(int(port.id))
	if not refusal.is_empty(): sound("ui_error");notify(port.name+": "+refusal);return
	landing_target=port.id;landing_clearance=port.id;auto_landing=true
	notify("Auto landing at %s · L or steering cancels." % port.name)

func auto_landing_step(fields: Dictionary, dt: float) -> Dictionary:
	var port: Dictionary=selected_planet()
	if port.is_empty() or not world_activity.landing_reason(int(port.id)).is_empty():
		auto_landing=false;notify("Auto landing canceled: destination unavailable.")
		return Flight.step(pilot.position,velocity,pilot.heading,0,false,false,fields,dt)
	var offset: Vector2=port.position-pilot.position
	var acceleration: float=maxf(1,Flight.acceleration(fields))
	# Slow well before the surface, allowing time to turn the main engine retrograde.
	var desired_speed: float=minf(float(fields.Speed)*0.65,sqrt(2*acceleration*maxf(0,offset.length()-port.radius*.45))*.45)
	var correction: Vector2=offset.normalized()*desired_speed-velocity
	var heading: float=Flight.facing(correction) if correction.length()>1 else pilot.heading
	var turn: float=Flight.steering(pilot.heading,heading,fields,dt)
	var aligned: bool=absf(angle_difference(pilot.heading,heading))<0.12
	return Flight.step(pilot.position,velocity,pilot.heading,turn,aligned and correction.length()>1,false,fields,dt,minf(1,correction.length()/(acceleration*dt)))

func land() -> void:
	if mode != "flight" or not chain_route.is_empty() or hyperdrive.active(): return
	var p = selected_planet()
	if p.is_empty():
		p = nearest_planet()
		if p.is_empty():
			notify("No landing destinations in this system.")
			return
		landing_target = p.id
	var refusal: String=world_activity.landing_reason(int(p.id))
	if not refusal.is_empty():
		landing_clearance=-1;sound("ui_error");notify(p.name+": "+refusal+(" H to hail and offer a landing bribe." if world_activity.can_bribe_landing(int(p.id)) else ""));return
	if landing_clearance != p.id:
		landing_clearance = p.id
		sound("ui_confirm")
		notify("%s: %s landing clearance granted. Approach slowly; press L again over the world." % [p.name,"Mission" if missions.grants_landing_clearance(int(p.id)) else "Standard"])
		return
	if pilot.position.distance_to(p.position) > p.radius or velocity.length() > Travel.MAX_LANDING_SPEED:
		sound("ui_error")
		notify(landing_guidance())
		return
	world_activity.abort()
	arsenal.recover_all_fighters()
	fighter_wing.dock_owned_carriers()
	docked_id = p.id
	missions.begin_port_visit()
	velocity = Vector2.ZERO
	missions.landed(docked_id,true)
	world_activity.sync()
	var reward = pilot.deliver(docked_id)
	if reward > 0: notify("Delivery complete · %s credits received." % reward)
	pilot.shield = pilot.max_shield()
	# Original port-return path 0x32e80 restores the combined shield/armor pool.
	pilot.armor = pilot.max_armor()
	outfitter.auto_refuel()
	if autopilot.active(): refuel()
	sound("ui_open")
	set_mode("dock")
	missions.show_next_landing_report()
	save_game(false)

func launch() -> void:
	if mode != "dock": return
	traffic.refresh_after_landing()
	missions.enter_system()
	landing_clearance = -1
	set_mode("flight")
	notify("Launch clearance granted. Safe travels, Captain.")
	save_game(false)

func cycle_destination() -> void:
	if not chain_route.is_empty(): return
	if hyperdrive.active():
		notify("Navigation locked during hyperspace. Press J to cancel first.")
		return
	var links: Array = catalog.system(pilot.system_id).links
	if links.is_empty(): return
	map_route.clear()
	var i: int = links.find(destination)
	destination = int(links[(i+1)%links.size()])
	sound("ui_select")
	notify("Navigation set: " + catalog.system(destination).name)

func select_destination(id: int) -> void:
	if autopilot.active(): autopilot.cancel("Manual navigation destination.")
	if not chain_route.is_empty(): return
	if hyperdrive.active():
		notify("Navigation locked during hyperspace. Return to flight and press J to cancel.")
		return
	if catalog.system(id).is_empty() or id == pilot.system_id: return
	if not pilot.cheat_chain_jump and id not in catalog.system(pilot.system_id).links:
		notify("Select a connected system for your next jump.")
		return
	destination = id
	sound("ui_select")
	notify("Navigation set: " + catalog.system(id).name)
	if is_instance_valid(hud): hud.rebuild_modal()

func jump_block_reason() -> String:
	if not chain_route.is_empty(): return "Chain jump · %d hops remaining · J cancels" % chain_route.size()
	if hyperdrive.active(): return hyperdrive.status()
	if mode != "flight": return "Return to flight to jump."
	if pilot.cheat_chain_jump:
		return "" if not route_to(destination).is_empty() else "Select a destination on the map."
	if destination not in catalog.system(pilot.system_id).links:
		return "Select a connected system."
	if pilot.fuel < 100 and not pilot.cheat_infinite_fuel:
		return "Insufficient fuel. G gives a free debug refill."
	var obstacle = Travel.hyperspace_obstacle(pilot.position, planets)
	if not obstacle.is_empty():
		return "Too close to %s · %d km to clear." % [obstacle.body.name, ceili(obstacle.remaining)]
	return ""

func start_jump() -> void:
	if mode != "flight": return
	if not chain_route.is_empty():
		cancel_jump()
		return
	if hyperdrive.active():
		cancel_jump()
		return
	var reason = jump_block_reason()
	if not reason.is_empty():
		notify(reason)
		return
	var first_hop: int = destination
	if pilot.cheat_chain_jump:
		chain_route = map_route.duplicate() if not map_route.is_empty() else route_to(destination)
		map_route.clear()
		first_hop = int(chain_route[0])
	var origin: Dictionary = catalog.system(pilot.system_id).fields
	var target: Dictionary = catalog.system(first_hop).fields
	var direction = Vector2(target.xPos - origin.xPos, target.yPos - origin.yPos)
	jump_visuals.reset()
	auto_boarding={}
	auto_landing=false
	# Keep the native recording intact: spool plus burn ends at its final sample.
	hyperdrive.burn_seconds = maxf(0.01, audio.jump_start.stream.get_length() - Hyperspace.SPOOL_SECONDS)
	hyperdrive.begin(first_hop, Flight.facing(direction))
	fleet_service.begin_jump()
	traffic.maverick.begin_warp(self)
	# Original input dispatch at 0x328bc uses interface sound slot 2 (snd 152).
	sound("ui_select")
	notify("Hyperspace: stop, align, spool, accelerate · %s · J cancels" % catalog.system(destination).name)

func cancel_jump(announce: bool = true) -> void:
	fleet_service.end_jump()
	var was_active: bool = hyperdrive.active() or not chain_route.is_empty()
	chain_route.clear()
	hyperdrive.reset()
	jump_visuals.reset()
	update_jump_visuals(0)
	if audio.has("jump"): audio.jump.stop()
	if audio.has("jump_start"): audio.jump_start.stop()
	if was_active and announce: notify("Hyperspace canceled. No fuel used; manual flight restored.")

func route_to(target: int) -> Array:
	if target == pilot.system_id or catalog.system(target).is_empty(): return []
	var queue: Array = [pilot.system_id]
	var previous: Dictionary = {pilot.system_id:-1}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == target: break
		for neighbor in catalog.system(current).links:
			if not previous.has(neighbor):
				previous[neighbor] = current
				queue.append(neighbor)
	# Cheat also permits isolated systems that have no connected route.
	if not previous.has(target): return [target]
	var route: Array = []
	var cursor: int = target
	while cursor != pilot.system_id:
		route.push_front(cursor)
		cursor = previous[cursor]
	return route

func chain_hop() -> void:
	if chain_route.is_empty(): return
	var retained_speed: float = velocity.length()
	var final_target: int = int(chain_route.back())
	var next: int = int(chain_route.pop_front())
	var from: Dictionary = catalog.system(pilot.system_id).fields
	var to: Dictionary = catalog.system(next).fields
	var heading: float = Flight.facing(Vector2(to.xPos-from.xPos,to.yPos-from.yPos))
	missions.sync_actors()
	pilot.system_id = next
	missions.jumped()
	if next not in pilot.visited: pilot.visited.append(next)
	load_system(heading,true)
	# Intermediate flybys retain burn speed; the final arrival returns to cruise.
	# Keep load_system’s directional arrival upstream of the primary world.
	var fields: Dictionary = pilot.flight_fields(catalog.record("ships",pilot.ship_id).fields)
	var arrival_speed: float = float(fields.Speed) if chain_route.is_empty() else maxf(retained_speed,float(fields.Speed))
	velocity = Vector2(sin(heading),-cos(heading))*arrival_speed
	previous_player_position = pilot.position
	previous_player_velocity = velocity
	rendered_player_position = v3(pilot.position)
	rendered_player_velocity = velocity
	player_model.position = v3(pilot.position)
	camera.position = v3(pilot.position+velocity*0.2,1200)
	destination = final_target if not chain_route.is_empty() else -1
	chain_timer = 1.0
	fleet_service.arrive()
	if not chain_route.is_empty(): fleet_service.begin_jump()
	update_jump_visuals(0)
	sound("arrival")
	notify("%s · %s" % [catalog.system(next).name,"Chain jump complete." if chain_route.is_empty() else "Next jump in 1 second · J cancels"])
	save_game(false)

func set_chain_jump_cheat(enabled: bool) -> void:
	pilot.cheat_chain_jump = enabled
	if not enabled:
		if not chain_route.is_empty(): cancel_jump(false)
		if destination not in catalog.system(pilot.system_id).links: destination = -1
	notify("Chain hyperjump on. M selects any system; J jumps the route." if enabled else "Chain hyperjump off.")
	save_game(false)
	if is_instance_valid(hud): hud.rebuild_modal()

func toggle_fleet_menu() -> void:
	if mode == "fleet":
		set_mode(fleet_return_mode)
	elif mode in ["flight", "pause", "dock", "info"]:
		fleet_return_mode = mode
		set_mode("fleet")

func release_ship(escort: Dictionary) -> bool:
	return fleet_service.release(escort)

func toggle_cheat_menu() -> void:
	if mode in ["dead", "comms", "boarding", "fleet", "eject_confirm", "ejecting", "rescue"]: return
	if mode == "cheats":
		set_mode(cheat_return_mode)
	else:
		cheat_return_mode = mode
		set_mode("cheats")

func set_weapon_cheat(enabled: bool) -> void:
	if pilot.armor <= 0: return
	pilot.cheat_all_weapons = enabled
	if not enabled:
		pilot.selected_weapon = 128
		arsenal.remove_cheat_weapons()
	notify("All 26 weapons available · unlimited ammo · Q/E selects, Space fires." if enabled else "Weapons cheat off. Normal laser loadout restored.")
	save_game(false)
	if is_instance_valid(hud): hud.rebuild_modal()

func set_fuel_cheat(enabled: bool) -> void:
	if pilot.armor <= 0: return
	pilot.cheat_infinite_fuel = enabled
	notify("Infinite fuel on. Jumps use no fuel." if enabled else "Infinite fuel off. Normal fuel consumption restored.")
	save_game(false)
	if is_instance_valid(hud): hud.rebuild_modal()

func set_invincibility_cheat(enabled: bool) -> void:
	if pilot.armor <= 0: return
	pilot.cheat_invincibility = enabled
	notify("Invincibility on. Your ship cannot take damage." if enabled else "Invincibility off. Normal damage restored.")
	save_game(false)
	if is_instance_valid(hud): hud.rebuild_modal()

func set_deflection_cheat(enabled: bool) -> void:
	if pilot.armor <= 0: return
	pilot.cheat_deflection = enabled
	notify("Deflection on. Incoming fire returns to its sender." if enabled else "Deflection off.")
	save_game(false)
	if is_instance_valid(hud): hud.rebuild_modal()

func deflect_shot(shot: Dictionary, previous: Vector2) -> void:
	var sender: Dictionary = shot.get("source",{})
	shot.position = Geometry2D.get_closest_point_to_segment(pilot.position,previous,shot.position)
	var direction: Vector2 = -shot.velocity.normalized()
	if sender in npcs:
		direction = (sender.position-shot.position).normalized()
		shot.target = sender.model
	else:
		shot.target = null
	shot.speed = maxf(shot.speed,275)
	shot.velocity = direction*shot.speed
	shot.launch_drift = Vector2.ZERO
	shot.enemy = false
	shot.npc_shot = false
	shot.source = {}
	shot.reflected = true
	shot.life = maxf(shot.life,10)
	shot.node.position = v3(shot.position,6)
	shot.node.rotation.y = -Flight.facing(direction)
	burst(shot.position,Color("82f8ff"),8)

func select_weapon(id: int) -> void:
	if id not in arsenal.available_ids(): return
	pilot.selected_weapon = id
	notify("Weapon: %s" % arsenal.weapon_name(id))
	save_game(false)
	if mode == "cheats" and is_instance_valid(hud): hud.rebuild_modal()

func cycle_weapon(direction: int) -> void:
	maverick_volley.reset()
	var available = arsenal.secondary_ids() if controls.classic_fire else arsenal.available_ids()
	if available.is_empty(): return
	select_weapon(available[posmod(available.find(pilot.selected_weapon)+direction,available.size())])

func debug_refuel() -> void:
	if mode == "dead" or pilot.armor <= 0: return
	pilot.fuel = pilot.fuel_capacity()
	notify("Fuel tank refilled. Enable infinite fuel in Cheats for unlimited travel.")
	save_game(false)
	if is_instance_valid(hud): hud.rebuild_modal()

func service_cost() -> int:
	var fuel_cost: float = refuel_cost()
	return int(ceil(fuel_cost+maxf(0,pilot.max_armor()-pilot.armor)*2))

func refuel_cost() -> int:
	if pilot.cheat_infinite_fuel or docked_id in world_activity.state().dominated: return 0
	return maxi(0,ceili(pilot.fuel_capacity()-pilot.fuel))

func refuel() -> int:
	var port: Dictionary=catalog.record("objects",docked_id)
	if port.is_empty() or int(port.fields.Flags)&32 or pilot.cheat_infinite_fuel: return 0
	var needed: float=maxf(0,pilot.fuel_capacity()-pilot.fuel)
	var cost: int=mini(refuel_cost(),pilot.credits)
	# Original 0x41034–0x41098 buys one fuel unit per credit, including partial fills.
	pilot.fuel+=needed if docked_id in world_activity.state().dominated else minf(needed,cost)
	pilot.credits-=cost
	return cost

func refuel_ship() -> void:
	if mode!="dock": return
	var cost: int=refuel()
	notify("Fuel purchased · %d credits." % cost)
	save_game(false);hud.rebuild_modal()

func service() -> void:
	var cost: int = service_cost()
	if pilot.credits < cost:
		notify("Insufficient credits for full service.")
		return
	pilot.credits -= cost
	if not pilot.cheat_infinite_fuel: pilot.fuel = pilot.fuel_capacity()
	pilot.armor = pilot.max_armor()
	pilot.shield = pilot.max_shield()
	notify("Refueled and repaired · %d credits." % cost)
	save_game(false)
	hud.rebuild_modal()

func trade(index: int, buying: bool) -> void:
	if mode != "dock": return
	var price: int = world_activity.prices(docked_id)[index]
	if not fleet_service.trade(index,buying,price):
		notify("Hold full or insufficient credits." if buying else "No units aboard to sell.")
	else:
		save_game(false)
	hud.rebuild_modal()

func courier_destination() -> Dictionary:
	for id in catalog.system(pilot.system_id).links:
		for port in catalog.system(int(id)).objects:
			if not world_killer.destroyed(int(port)): return {"system":int(id),"object":int(port)}
	return {}

func accept_job() -> void:
	if mode!="dock" and not (mode=="missions" and missions.return_mode=="dock" and missions.channel==0): return
	var dest: Dictionary=courier_destination()
	if dest.is_empty(): notify("No surviving courier destination is available.");return
	if pilot.accept_job(int(dest.system),int(dest.object),pilot.cargo_capacity()):
		destination=int(dest.system)
		notify("Courier contract accepted. Destination: %s." % catalog.system(destination).name)
		save_game(false)
	else: notify("An active contract or a full hold prevents accepting this job.")
	hud.rebuild_modal()

func buy_laser() -> void:
	if mode != "dock": return
	mode = "outfitter"
	outfitter.trade(128,true)
	set_mode("dock")

func save_game(announce: bool = true) -> bool:
	if mode in ["ejecting","rescue"] or is_instance_valid(ejection.pod): return false
	missions.sync_actors()
	fleet_service.sync()
	if pilot.armor <= 0 and pilot.shield <= 0 and not pilot.strict_dead: return false
	achievements.update(is_instance_valid(hud) and mode not in ["title","intro"])
	var f = FileAccess.open(save_path + ".tmp",FileAccess.WRITE)
	if f == null:
		if announce: notify("Could not write the pilot save.")
		return false
	pilot.fighter_sorties=fighter_wing.saved()
	var saved: Dictionary=pilot.snapshot()
	saved.outfits=arsenal.saved_outfits()
	f.store_string(JSON.stringify(saved,"\t"))
	f.close()
	var result = DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))
	if result != OK:
		if announce: notify("Could not replace the pilot save.")
		return false
	if announce: notify("Pilot saved.")
	return true

func open_pilot_file(path: String) -> String:
	if not FileAccess.file_exists(path): return "That pilot file could not be found. Choose an Escape Velocity HD pilot JSON file."
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null: return "That pilot file could not be read. Check its permissions and try again."
	var saved=JSON.parse_string(file.get_as_text());file.close()
	if saved is Dictionary and saved.get("strict_dead",false): return "This strict pilot has died permanently. Choose another pilot or create a new one."
	var restored=Pilot.new()
	if not restored.restore(saved,catalog): return "This is not a valid Escape Velocity HD pilot file, or it belongs to an unsupported version."
	if ProjectSettings.globalize_path(path)!=ProjectSettings.globalize_path(save_path):
		var preservation_error: String=preserve_current_pilot()
		if not preservation_error.is_empty(): return preservation_error
	autopilot.cancel("Pilot restored.",false)
	# Discard transient encounters and reports belonging to the previous pilot.
	missions.reset_bar_encounters();missions.landing_reports.clear();missions.active_landing_report.clear()
	pilot=restored;save_path=path;pilot_ready=true;opening_story_seen=true
	remember_active_pilot()
	messages.clear()
	load_system()
	return ""

func load_game() -> void:
	var error: String=open_pilot_file(save_path)
	if not error.is_empty(): notify(error);return
	set_mode("flight")
	notify("Pilot restored.")

func replay_opening_sequence() -> void:
	if mode!="title": return
	set_mode("intro")
	var layer=CanvasLayer.new();layer.name="OpeningReplay";layer.layer=50;add_child(layer)
	var opening=load("res://scripts/startup.gd").new()
	opening.replay_only=true;opening.music_muted=muted;opening.replay_music=audio.menu_music
	opening.opening_finished.connect(func():
		layer.queue_free();set_mode("title"))
	layer.add_child(opening)

var opening_story_seen: bool=false
func enter_ship_with_intro(force_intro: bool=false) -> void:
	if not pilot_ready: return
	if opening_story_seen or (DisplayServer.get_name()=="headless" and not force_intro):
		set_mode("flight");return
	opening_story_seen=true
	set_mode("intro")
	var layer=CanvasLayer.new();layer.layer=50;add_child(layer)
	var intro=load("res://scripts/startup.gd").new();intro.story_only=true;intro.music_muted=muted
	intro.story_finished.connect(func():set_mode("flight"))
	intro.story_revealed.connect(layer.queue_free)
	layer.add_child(intro)

func remember_active_pilot() -> void:
	if not remember_pilot_selection: return
	var file=FileAccess.open(pilot_selection_path+".tmp",FileAccess.WRITE)
	if file==null: return
	file.store_string(JSON.stringify({"path":ProjectSettings.globalize_path(save_path)}));file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(pilot_selection_path+".tmp"),ProjectSettings.globalize_path(pilot_selection_path))

func preserve_current_pilot() -> String:
	if not pilot_ready: return ""
	# A normal dead pilot retains its last living save; never overwrite it with the wreck.
	if pilot.shield<=0 and pilot.armor<=0 and not pilot.strict_dead: return ""
	return "" if save_game(false) else "Could not save the current pilot. No pilot was replaced. Check the save folder permissions and try again."

func create_pilot(name: String,strict_rules: bool,ship_name: String="Adventurer",launch_now: bool=true) -> bool:
	pilot_file_error=preserve_current_pilot()
	if not pilot_file_error.is_empty(): return false
	var candidate=Pilot.new()
	candidate.pilot_name=name.strip_edges().left(64) if not name.strip_edges().is_empty() else "Captain"
	candidate.strict=strict_rules
	candidate.ship_name=ship_name.strip_edges().left(64) if not ship_name.strip_edges().is_empty() else "Adventurer"
	var stem: String="pilot-"+candidate.pilot_name.to_snake_case().validate_filename().left(48)
	var directory: String=save_path.get_base_dir()
	var path: String=directory.path_join(stem+".json")
	var suffix: int=2
	while FileAccess.file_exists(path) or FileAccess.file_exists(path+".tmp") or ProjectSettings.globalize_path(path)==ProjectSettings.globalize_path(save_path):
		path=directory.path_join(stem+"-%d.json" % suffix);suffix+=1
	# Write the new pilot successfully before changing the active pilot or file.
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		pilot_file_error="Could not create the new pilot file. Your current pilot is still active.";return false
	file.store_string(JSON.stringify(candidate.snapshot(),"\t"));file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))!=OK:
		pilot_file_error="Could not finish saving the new pilot. Your current pilot is still active.";return false
	save_path=path;remember_active_pilot();restart(candidate,launch_now);opening_story_seen=false
	if launch_now: enter_ship_with_intro()
	return true

func restart(new_pilot: Variant=null,enter_flight: bool=true) -> void:
	autopilot.cancel("New flight.",false)
	pilot_ready = true
	missions.approach={};missions.approached.clear();missions.approach_port=-1;missions.bar_port=-1;missions.bar_rolls.clear();missions.bar_queue.clear()
	missions.landing_reports.clear()
	missions.active_landing_report.clear()
	pilot = Pilot.new() if new_pilot==null else new_pilot
	load_system()
	if enter_flight: set_mode("flight")
	notify("Fresh test flight. Save with F5 when ready.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if pilot_ready: save_game(false)
		get_tree().quit()
