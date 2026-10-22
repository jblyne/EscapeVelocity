extends "res://scripts/sidewinder_smoke.gd"
# World-space exhaust trails share one bounded draw batch, never move with the hull.
var previous: Dictionary={}
func _ready():
 lifetime=1.0
 super._ready()
func advance(dt: float):
 super.advance(dt)
 var active: Dictionary={}
 for model in get_parent().get_children():
  if not model is Node3D or int(model.get_meta("ship_id",-1))!=900 or not model.get_meta("afterburner_active",false): continue
  for flame in model.get_children():
   if not str(flame.name).begins_with("Flame") or not flame.visible: continue
   var tip: Vector3=flame.to_global(Vector3(0,0,.7))
   var at=Vector2(tip.x,tip.z)
   var key: int=flame.get_instance_id();active[key]=at
   var start: Vector2=previous.get(key,at)
   var count: int=clampi(ceili(start.distance_to(at)/10),1,64)
   for i in count:
    if puffs.size()>=LIMIT: break
    puffs.append({"position":start.lerp(at,float(i+1)/count),"age":0.0,"seed":randf(),"drift":Vector2(randf_range(-6,6),randf_range(-6,6))})
 previous=active
