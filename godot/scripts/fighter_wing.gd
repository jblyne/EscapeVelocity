extends RefCounted
# Original manual: docking services fighters at no operating cost. Endurance,
# approach radius and service delay below remain explicit remake tuning.
const ENDURANCE=180.0
const SERVICE_SECONDS=3.0
const COMMANDS=["defend","attack","formation","hold","dock"]
var game
var pilot_owner
var attack_target: Node3D
static func stock(catalog,id: int) -> Array:
 var result: Array=[]
 var f: Dictionary=catalog.record("ships",id).fields
 for i in f.WeapType.size():
  var weapon: int=int(f.WeapType[i])
  if int(f.WeapCount[i])<=0 or catalog.record("weapons",weapon).is_empty(): continue
  result.append({"id":weapon,"slot":i,"count":int(f.WeapCount[i]),"ammo":int(f.AmmoLoad[i]) if int(catalog.field("weapons",weapon,"AmmoType"))>=0 else -1,"cooldown":.3})
 return result
static func shield_capacity(catalog,id: int) -> float:
 var value: float=float(catalog.field("ships",id,"Shield"))
 return value if value>=0 else -5*value
static func finite_number(value: Variant,lo: float,hi: float) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value>=lo and value<=hi
static func valid(records: Variant,catalog,carrier: int,limit: int=12) -> bool:
 if not records is Array or records.size()>limit: return false
 for r in records:
  if not r is Dictionary: return false
  for key in ["id","carrier_ship","bay_weapon","bay_ammo"]:
   if not finite_number(r.get(key),-1,32767) or r[key]!=int(r[key]): return false
  if int(r.carrier_ship)!=carrier or catalog.record("ships",int(r.id)).is_empty(): return false
  var bay: Dictionary=catalog.record("weapons",int(r.bay_weapon))
  if bay.is_empty() or int(bay.fields.Guidance)!=99 or int(bay.fields.AmmoType)!=int(r.id): return false
  if int(r.bay_ammo)>=0:
   var outfit: Dictionary=catalog.record("outfits",int(r.bay_ammo))
   if outfit.is_empty() or int(outfit.fields.ModType)!=3 or int(outfit.fields.ModVal)!=int(r.bay_weapon): return false
  if not finite_number(r.get("shield"),0,shield_capacity(catalog,int(r.id))) or not finite_number(r.get("armor"),0,maxf(0,float(catalog.field("ships",int(r.id),"Armor")))): return false
  if float(r.shield)+float(r.armor)<=0: return false
  if not finite_number(r.get("sortie_seconds"),0,100000000) or r.get("command") not in COMMANDS or not finite_number(r.get("heading"),-100000000,100000000): return false
  for key in ["position","velocity"]:
   if not r.get(key) is Array or r[key].size()!=2: return false
   for value in r[key]:
    if not finite_number(value,-100000000,100000000): return false
  var weapons: Array=stock(catalog,int(r.id))
  if not r.get("ammo") is Array or r.ammo.size()!=weapons.size(): return false
  for i in weapons.size():
   var n=r.ammo[i];var maximum: int=int(weapons[i].ammo)
   if not finite_number(n,-1,maxi(-1,maximum)) or n!=int(n) or (maximum<0 and n!=-1) or (maximum>=0 and n<0): return false
 return true
func snapshot(f: Dictionary,carrier: int) -> Dictionary:
 var ammo: Array=[]
 for w in f.weapons: ammo.append(int(w.ammo))
 return {"id":int(f.id),"carrier_ship":carrier,"bay_weapon":int(f.get("bay_weapon",-1)),"bay_ammo":int(f.get("bay_ammo",-1)),"shield":float(f.shield),"armor":float(f.armor),"ammo":ammo,"sortie_seconds":float(f.get("sortie_seconds",0)),"command":"dock" if f.get("recalling",false) else str(f.get("command","defend")),"position":[f.position.x,f.position.y],"velocity":[f.velocity.x,f.velocity.y],"heading":float(f.heading)}
func saved() -> Array:
 var records: Array=[]
 for f in game.escorts:
  if f.get("captured",false) or int(f.get("carrier_ship",game.pilot.ship_id))!=game.pilot.ship_id: continue
  if not is_instance_valid(f.model) or float(f.shield)+float(f.armor)<=0: continue
  records.append(snapshot(f,game.pilot.ship_id))
 return records
func apply(f: Dictionary,r: Dictionary) -> void:
 for key in ["shield","armor","sortie_seconds","bay_weapon","bay_ammo","carrier_ship"]: f[key]=r[key]
 f.position=Vector2(r.position[0],r.position[1]);f.velocity=Vector2(r.velocity[0],r.velocity[1]);f.heading=float(r.heading)
 f.command="defend" if r.command=="attack" else r.command;f.recalling=r.command=="dock";f.hold_position=f.position
 for i in mini(f.weapons.size(),r.ammo.size()): f.weapons[i].ammo=int(r.ammo[i])
 f.health=float(f.shield)+float(f.armor)
 f.model.position=game.v3(f.position);f.model.rotation.y=-f.heading
func order(command: String) -> void:
 if command not in COMMANDS: return
 if command=="attack":
  var target: Dictionary=game.selected_contact()
  if target.is_empty() or target.has("fleet_uid") or target.get("player_ally",false): game.notify("Select an enemy ship for your fighters.");return
  attack_target=target.model
 for f in game.escorts:
  if f.get("captured",false): continue
  f.command=command;f.recalling=command=="dock";f.hold_position=f.position
 game.notify("Fighter order: "+command.capitalize());game.save_game(false)
func target(f: Dictionary) -> Dictionary:
 if f.get("command","defend") in ["hold","formation","dock"] or f.get("recalling",false): return {}
 if f.get("command","defend")=="attack" and is_instance_valid(attack_target):
  for npc in game.npcs:
   if npc.model==attack_target and npc.health>0: return npc
 var best: Dictionary={}
 var distance: float=INF
 for npc in game.npcs:
  if not npc.hostile or npc.disabled or npc.truce or npc.health<=0: continue
  var d: float=f.position.distance_squared_to(npc.position)
  if d<distance: distance=d;best=npc
 return best
func fly(f: Dictionary,goal: Vector2,carrier_velocity: Vector2,dt: float) -> void:
 var fields: Dictionary=game.catalog.record("ships",int(f.id)).fields
 var offset: Vector2=goal-f.position
 var acceleration: float=game.Flight.acceleration(fields)
 var desired: Vector2=carrier_velocity+offset.normalized()*minf(float(fields.Speed),minf(offset.length()*.8,sqrt(2*acceleration*offset.length())*.55))
 var correction: Vector2=desired-f.velocity
 var heading: float=game.Flight.facing(correction) if correction.length()>1 else float(f.heading)
 var turn: float=game.Flight.steering(f.heading,heading,fields,dt)
 var aligned: bool=absf(angle_difference(f.heading,heading))<(PI/12 if offset.length()<150 else PI/3)
 var step: Dictionary=game.Flight.step(f.position,f.velocity,f.heading,turn,aligned and correction.length()>1,false,fields,dt,minf(1,correction.length()/maxf(1,acceleration*dt)))
 f.position=step.position;f.velocity=step.velocity;f.heading=step.heading
 f.model.position=game.v3(f.position);f.model.rotation.y=-f.heading
 game.Models.set_thrust(f.model,.7 if aligned and correction.length()>1 else 0,game.time)
func update_carrier_fighter(f: Dictionary,dt: float) -> bool:
 if f not in game.npcs or not f.get("fighter",false): return false
 var carrier: Dictionary={}
 for npc in game.npcs:
  if npc.model==f.carrier: carrier=npc;break
 if carrier.is_empty():
  f.fighter=false;f.carrier=null;f.ambient=true;f.age=101;return false
 if f.disabled: return false
 f.sortie_seconds=float(f.get("sortie_seconds",0))+dt
 var parent_order: String=str(game.fleet_service.record(carrier).get("command","defend"))
 if parent_order=="recall": f.recalling=true
 if f.sortie_seconds>=ENDURANCE or carrier.disabled or carrier.has("departure"): f.recalling=true
 if float(f.health)<float(f.max_health)*.25: f.recalling=true
 if parent_order=="hold" and not f.get("recalling",false):
  if not f.has("hold_position"): f.hold_position=f.position
  fly(f,f.hold_position,Vector2.ZERO,dt);f.behavior="Holding with carrier";return true
 if not f.get("recalling",false): return false
 if f.position.distance_to(carrier.position)<=maxf(45,carrier.radius) and f.velocity.distance_to(carrier.velocity)<35:
  for w in carrier.weapons:
   if int(w.id)==int(f.get("bay_weapon",-1)) and w.ammo>=0: w.ammo+=1;w.cooldown=maxf(float(w.cooldown),SERVICE_SECONDS);break
  game.traffic.retire(f);return true
 fly(f,carrier.position,carrier.velocity,dt);f.behavior="Returning to carrier";return true

func restore_carrier(carrier: Dictionary) -> void:
 for r in carrier.get("pending_wings",[]).duplicate():
  if not game.traffic.launch_fighter(carrier,int(r.id),int(r.bay_weapon)): return
  var fighter: Dictionary=game.npcs.back()
  apply(fighter,r)
  fighter.position=carrier.position+Vector2(70,80).rotated(float(carrier.pending_wings.find(r)))
  fighter.model.position=game.v3(fighter.position)
  fighter.disabled=game.Combat.is_disabled(fighter)
  carrier.pending_wings.erase(r)

func dock_owned_carriers() -> void:
 for carrier in game.npcs.duplicate():
  if not carrier.has("fleet_uid"): continue
  var records: Array=carrier.get("pending_wings",[]).duplicate(true)
  carrier.pending_wings=[]
  for fighter in game.npcs.duplicate():
   if fighter.get("fighter",false) and fighter.carrier==carrier.model:
    records.append(snapshot(fighter,int(carrier.id)));game.traffic.retire(fighter)
  for r in records:
   for weapon in carrier.weapons:
    if int(weapon.id)==int(r.bay_weapon) and weapon.ammo>=0: weapon.ammo+=1;break
