extends RefCounted
const HOLD_SECONDS=.4
var game
var held=false
var age=0.0
var ready=false
var launched=false
var targets: Array=[]
var locked_weapon: int=-1
func reset() -> void:
 held=false;age=0;ready=false;launched=false;targets.clear();locked_weapon=-1
func supports(id: int) -> bool:
 var record: Dictionary=game.catalog.record("weapons",id)
 return not record.is_empty() and int(record.fields.Guidance) in [1,2,3,4,7,8]
func eligible() -> bool:
 return game.mode=="flight" and game.pilot.ship_id==900 and supports(game.pilot.selected_weapon) and not game.controls.classic_fire and game.pilot.selected_weapon in game.arsenal.available_ids() and not game.hyperdrive.active() and game.chain_route.is_empty() and (not game.cloak.active or game.pilot.cheat_cloak)
func budget() -> int:
 var id: int=game.pilot.selected_weapon
 var count: int=maxi(0,160-game.shots.size())
 var ammo: int=game.outfitter.ammo_id(id)
 if not game.pilot.cheat_all_weapons and ammo>=0: count=mini(count,game.outfitter.count(ammo))
 var fuel: int=maxi(0,-int(game.catalog.field("weapons",id,"AmmoType"))-1000)
 if not game.pilot.cheat_infinite_fuel and fuel>0: count=mini(count,int(game.pilot.fuel/fuel))
 return count
func valid(npc: Dictionary) -> bool:
 return npc in game.npcs and npc.get("health",0)>0 and npc.get("hostile",false) and not npc.has("fleet_uid") and not npc.get("player_ally",false) and not npc.has("departure") and npc.position.distance_to(game.pilot.position)<=game.arsenal.weapon_reach(game.pilot.selected_weapon)
func acquire() -> void:
 locked_weapon=game.pilot.selected_weapon
 var candidates: Array=game.npcs.filter(func(n):return valid(n))
 candidates.sort_custom(func(a,b):return a.position.distance_squared_to(game.pilot.position)<b.position.distance_squared_to(game.pilot.position))
 targets=candidates.slice(0,budget());ready=not targets.is_empty()
 if ready and not game.muted: game.sound("maverick_target")
 game.notify("%d %s locks · release, then press fire to launch." % [targets.size(),game.arsenal.weapon_name(locked_weapon)] if ready else "No hostile targets in weapon range, or no ammunition.")
func launch() -> int:
 var count=0
 if not eligible() or locked_weapon!=game.pilot.selected_weapon: reset();return 0
 var id: int=locked_weapon
 if game.cooldown>0 or (game.secondary_safe and game.arsenal.is_secondary(id)): return 0
 for npc in targets.duplicate():
  if not valid(npc) or budget()<=0: continue
  if game.arsenal.fire(id,game.pilot.position,game.pilot.heading,false,{},npc):
   count+=1
   if not game.pilot.cheat_infinite_fuel: game.pilot.fuel-=maxi(0,-int(game.catalog.field("weapons",id,"AmmoType"))-1000)
   var ammo: int=game.outfitter.ammo_id(id)
   if not game.pilot.cheat_all_weapons and ammo>=0:
    game.pilot.outfits[str(ammo)]=game.outfitter.count(ammo)-1
    if game.pilot.outfits[str(ammo)]==0: game.pilot.outfits.erase(str(ammo))
 if count>0:
  game.cooldown=maxf(game.Flight.WEAPON_TICK_SECONDS,float(game.catalog.field("weapons",id,"Reload"))*game.Flight.WEAPON_TICK_SECONDS)
  game.notify("FOX TWO · %d Sidewinders away!" % count if id==901 else "%s · %d targets engaged!" % [game.arsenal.weapon_name(id),count])
 targets.clear();ready=false
 return count
# Returns true when this gesture owns the primary fire input, including release.
func update(pressed: bool,dt: float) -> bool:
 if not eligible(): reset();return false
 if locked_weapon!=-1 and locked_weapon!=game.pilot.selected_weapon: reset()
 targets=targets.filter(func(n):return valid(n)).slice(0,budget())
 if ready and targets.is_empty(): ready=false
 if pressed and not held:
  held=true;age=0;launched=false
  if ready:
   launch();launched=true
 if pressed:
  age+=dt
  if not launched and age>=HOLD_SECONDS and not ready:
   acquire();launched=true # Acquire once per hold, including empty acquisitions.
 elif held:
  if age<HOLD_SECONDS and not launched: game.fire_player()
  held=false;age=0;launched=false
 return true
