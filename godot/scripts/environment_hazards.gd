extends RefCounted
const AsteroidModels=preload("res://scripts/asteroid_models.gd")
var game
var rocks: Array=[]
var age: float=0
func build() -> void:
 rocks.clear()
 age=0
 var density: int=clampi(int(game.catalog.system(game.pilot.system_id).fields.Asteroids),0,12)
 var rng=RandomNumberGenerator.new();rng.seed=game.pilot.system_id*971
 for i in density*10:
  var point=Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(900,2900)
  if game.planets.any(func(body):return point.distance_to(body.position)<float(body.radius)+120): continue
  var radius: float=rng.randf_range(8,24)
  var node=AsteroidModels.create(game.world,game.v3(point,0),radius,i)
  node.scale*=Vector3(rng.randf_range(.7,1.3),rng.randf_range(.65,1.15),rng.randf_range(.7,1.3));node.rotation=Vector3(rng.randf(),rng.randf(),rng.randf())*TAU
  var motion=RandomNumberGenerator.new();motion.seed=game.pilot.system_id*7919+i*331
  var velocity=Vector2.from_angle(motion.randf_range(0,TAU))*motion.randf_range(12,38)
  var spin=Vector3(motion.randf_range(-.18,.18),motion.randf_range(.25,.65)*(1 if i%2==0 else -1),motion.randf_range(-.18,.18))
  rocks.append({"position":point,"radius":radius,"node":node,"origin":point,"velocity":velocity,"rotation":node.rotation,"spin":spin})
func advance(dt: float) -> void:
 if game.mode!="flight": return
 age+=dt
 for rock in rocks:
  if not rock.has("origin"): continue
  var point: Vector2=rock.origin+rock.velocity*age-game.pilot.position
  # Recycle beyond the camera, keeping a field around a travelling pilot.
  rock.position=game.pilot.position+Vector2(wrapf(point.x,-3200,3200),wrapf(point.y,-3200,3200))
  rock.node.position=game.v3(rock.position)
  rock.node.rotation=rock.rotation+rock.spin*age
func obstruction(start: Vector2,end: Vector2) -> Dictionary:
 var best: Dictionary={};var nearest: float=INF
 var delta=end-start;var length: float=delta.length()
 if length<.0001: return best
 var direction=delta/length
 for rock in rocks:
  var projection: float=(rock.position-start).dot(direction)
  var perpendicular: float=absf((rock.position-start).cross(direction))
  if perpendicular>rock.radius: continue
  var distance: float=projection-sqrt(maxf(0,rock.radius*rock.radius-perpendicular*perpendicular))
  if distance<0 and start.distance_to(rock.position)<rock.radius: distance=0
  if distance>=0 and distance<=length and distance<nearest:
   nearest=distance;best={"position":start+direction*distance,"distance":distance}
 return best
func interference() -> int:
 return clampi(int(game.catalog.system(game.pilot.system_id).fields.Interference),0,100)
func sensor_visible(npc: Dictionary) -> bool:
 var noise: int=interference()
 if noise==0: return true
 if npc.get("fleet_uid",-1)>=0 or npc.get("player_ally",false): return true
 var distance: float=game.pilot.position.distance_to(npc.position)
 # Visible nearby ships remain trackable; interference limits remote radar.
 return distance<=maxf(350,2000*(1-float(noise)/100.0))
