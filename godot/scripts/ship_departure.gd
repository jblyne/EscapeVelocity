extends RefCounted

# Shared with the player's actual engine, not a look-alike animation timer.
const Hyperspace=preload("res://scripts/hyperspace.gd")
const JumpVisuals=preload("res://scripts/jump_visuals.gd")
const Flight=preload("res://scripts/flight.gd")
const Travel=preload("res://scripts/travel_rules.gd")
var game
var drive=Hyperspace.new()
var visuals=JumpVisuals.new()
var host: Node3D
var visual: Node3D
var base_scale=Vector3.ONE
var fields: Dictionary
var position=Vector2.ZERO
var velocity=Vector2.ZERO
var heading: float=0
var route_heading: float=0
var destination: int=-1
var height: float=0
var age: float=0
var complete: bool=false
var audio: AudioStreamPlayer
var clearing: bool=true
var thrust: float=0

func setup(owner_game,root: Node3D,model: Node3D,pos: Vector2,drift: Vector2,facing: float,ship_fields: Dictionary) -> void:
	game=owner_game;host=root;visual=model;position=pos;velocity=drift;heading=facing
	fields=ship_fields.duplicate(true);height=root.position.y;base_scale=model.scale
	var preferred=Vector2(sin(heading),-cos(heading))
	var best: float=-INF
	var origin: Dictionary=game.catalog.system(game.pilot.system_id).fields
	for id in game.catalog.system(game.pilot.system_id).links:
		var next: Dictionary=game.catalog.system(int(id)).fields
		var direction=Vector2(next.xPos-origin.xPos,next.yPos-origin.yPos).normalized()
		if direction.dot(preferred)>best:
			best=direction.dot(preferred);destination=int(id);route_heading=Flight.facing(direction)
	if destination<0: route_heading=heading
	audio=AudioStreamPlayer.new();audio.stream=game.audio.jump.stream;audio.pitch_scale=game.audio.jump.pitch_scale
	audio.volume_db=-20;host.add_child(audio)

func phase() -> String:
	return "complete" if complete else "clearing" if clearing else drive.phase

func set_audio_state(muted: bool,running: bool) -> void:
	if not is_instance_valid(audio): return
	audio.volume_db=-16+linear_to_db(1000.0/(1000.0+position.distance_to(game.pilot.position)))
	if muted: audio.stop();return
	if running and drive.phase=="accelerating" and not complete and not audio.playing:
		audio.play((Hyperspace.ACCELERATION_SECONDS-drive.remaining)*audio.pitch_scale)
	audio.stream_paused=not running

func cancel() -> void:
	if is_instance_valid(audio): audio.queue_free()
	if is_instance_valid(visual): visual.scale=base_scale

func advance(dt: float) -> bool:
	if complete: return true
	if game.mode!="flight": return false
	age+=dt
	if clearing and Travel.hyperspace_obstacle(position,game.planets).is_empty():
		clearing=false;drive.begin(destination,route_heading)
	var step: Dictionary
	if clearing:
		# Fly outward before stopping/aligning, just as a pilot must clear gravity.
		var obstacle: Dictionary=Travel.hyperspace_obstacle(position,game.planets)
		var away: Vector2=position-obstacle.body.position
		if away.length()<1: away=Vector2(sin(route_heading),-cos(route_heading))
		var turn: float=Flight.steering(heading,Flight.facing(away),fields,dt)
		step=Flight.step(position,velocity,heading,turn,true,false,fields,dt)
		step.thrust=1.0;step.complete=false
	else:
		step=drive.step(position,velocity,heading,fields,dt)
	position=step.position;velocity=step.velocity;heading=step.heading;thrust=float(step.thrust)
	if not clearing and drive.phase!="accelerating" and not Travel.hyperspace_obstacle(position,game.planets).is_empty():
		drive.reset();clearing=true
	complete=bool(step.complete)
	host.position=Vector3(position.x,height,position.y)
	host.rotation.y=-heading
	visual.scale=base_scale*visuals.ship_scale(drive)
	game.Models.set_thrust(host,thrust,age,drive.phase=="accelerating")
	set_audio_state(game.muted,true)
	return complete
