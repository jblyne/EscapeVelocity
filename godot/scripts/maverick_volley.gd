extends RefCounted
const HOLD_SECONDS=.4
var game
var held=false
var age=0.0
var ready=false
var launched=false
var targets: Array=[]
func reset() -> void:
 held=false;age=0;ready=false;launched=false;targets.clear()
func eligible() -> bool:
 return game.mode=="flight" and game.pilot.ship_id==900 and game.pilot.selected_weapon==901 and not game.controls.classic_fire and 901 in game.arsenal.available_ids() and not game.hyperdrive.active() and game.chain_route.is_empty() and (not game.cloak.active or game.pilot.cheat_cloak)
func budget() -> int:
 return maxi(0,160-game.shots.size()) if game.pilot.cheat_all_weapons else mini(maxi(0,160-game.shots.size()),game.outfitter.count(game.outfitter.ammo_id(901)))
func valid(npc: Dictionary) -> bool:
 return npc in game.npcs and npc.get("health",0)>0 and npc.get("hostile",false) and not npc.has("fleet_uid") and not npc.get("player_ally",false) and not npc.has("departure") and npc.position.distance_to(game.pilot.position)<=game.arsenal.weapon_reach(901)
func acquire() -> void:
 var candidates: Array=game.npcs.filter(func(n):return valid(n))
 candidates.sort_custom(func(a,b):return a.position.distance_squared_to(game.pilot.position)<b.position.distance_squared_to(game.pilot.position))
 targets=candidates.slice(0,budget());ready=not targets.is_empty()
 if ready and not game.muted: game.sound("maverick_target")
 game.notify("%d Sidewinder locks · release, then press fire to launch." % targets.size() if ready else "No hostile targets in Sidewinder range, or no ammunition.")
func launch() -> int:
 var count=0
 if game.cooldown>0 or game.secondary_safe: return 0
 for npc in targets.duplicate():
  if not valid(npc) or budget()<=0: continue
  if game.arsenal.fire(901,game.pilot.position,game.pilot.heading,false,{},npc):
   count+=1
   if not game.pilot.cheat_all_weapons:
    var ammo: int=game.outfitter.ammo_id(901)
    game.pilot.outfits[str(ammo)]=game.outfitter.count(ammo)-1
    if game.pilot.outfits[str(ammo)]==0: game.pilot.outfits.erase(str(ammo))
 if count>0:
  game.cooldown=maxf(game.Flight.WEAPON_TICK_SECONDS,float(game.catalog.field("weapons",901,"Reload"))*game.Flight.WEAPON_TICK_SECONDS)
  game.notify("FOX TWO · %d Sidewinders away!" % count)
 targets.clear();ready=false
 return count
# Returns true when this gesture owns the primary fire input, including release.
func update(pressed: bool,dt: float) -> bool:
 if not eligible(): reset();return false
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
