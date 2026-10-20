extends RefCounted

const SHIP_ID = 136 # Original EV Data përs 639: Cap'n Hector -> Rapier.
const REMINDER = "Avast, pilot! Don't forget to pay your shareware fee!"
var game
var rng = RandomNumberGenerator.new()
var remaining: float
var banner_time: float = 0.0

func _init() -> void:
	rng.randomize()
	remaining = rng.randf_range(180,360)

func advance(dt: float) -> void:
	if game.mode != "flight": return
	banner_time = maxf(0,banner_time-dt)
	if game.hyperdrive.active() or not game.chain_route.is_empty(): return
	if game.npcs.any(func(npc):return npc.get("hector",false)): return
	remaining -= dt
	if remaining <= 0:
		if spawn(): remaining = rng.randf_range(360,600)
		else: remaining = 15 # Retry later if the system is full.

func spawn() -> bool:
	if game.npcs.any(func(npc):return npc.get("hector",false)): return false
	var npc: Dictionary = game.traffic.spawn(SHIP_ID,-1,1,game.pilot.position+Vector2(320,-180))
	if npc.is_empty(): return false
	npc.hector = true
	npc.name = "Cap'n Hector"
	npc.truce = true
	npc.hostile = false
	npc.behavior = "Shareware patrol"
	npc.credits = 0
	npc.cargo = [0,0,0,0,0,0]
	npc.weapons = []
	npc.heading = game.Flight.facing(game.pilot.position-npc.position)
	npc.model.rotation.y = -npc.heading
	banner_time = 10.0
	game.notify("Cap'n Hector: "+REMINDER)
	return true

func fly(npc: Dictionary, dt: float) -> void:
	if npc.age > 30:
		game.traffic.request_departure(npc)
		return
	var goal: Vector2 = game.pilot.position+Vector2(140,-100)
	if npc.age > 18:
		goal = npc.position+Vector2(1,-.5)*2000
		npc.behavior = "Departing"
	else: npc.behavior = "Shareware patrol"
	npc.hostile = false
	npc.truce = true
	var offset: Vector2 = goal-npc.position
	npc.heading = rotate_toward(npc.heading,game.Flight.facing(offset),dt*3.0)
	npc.velocity = Vector2(sin(npc.heading),-cos(npc.heading))*minf(450,offset.length()*2)
	npc.position += npc.velocity*dt
	npc.model.position = game.v3(npc.position)
	npc.model.rotation.y = -npc.heading
	game.Models.set_thrust(npc.model,.75,game.time)
