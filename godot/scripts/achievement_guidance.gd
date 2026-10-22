extends RefCounted
var game
var destinations: Array=[]

func add_destination(system: int) -> void:
 if system>=0 and system not in destinations and not game.catalog.system(system).is_empty(): destinations.append(system)

func objective(m: Dictionary) -> String:
 add_destination(game.missions.target_system(m))
 return game.missions.next_objective(m)
const Awards=preload("res://scripts/achievements.gd")

func steps(id: String) -> String:
 destinations.clear()
 var entries: Array=game.achievements.badges().filter(func(b):return b.id==id)
 if entries.is_empty(): return "Unknown badge."
 var b: Dictionary=entries[0]
 if b.earned or float(b.fraction)>=1: return "Badge complete. No further steps are required."
 var remaining: int=maxi(0,ceili(float(b.target)-float(b.value)))
 if id.begins_with("story_"):
  for track in Awards.COMMON:
   if id=="story_"+track.id: return story_steps(track.missions)
 match id:
  "war_hero":
   var branch: String=game.achievements.progress().branch
   if branch=="Confederation": return story_steps(Awards.CONFED)
   if branch=="Rebellion": return story_steps(Awards.REBEL)
   return "Choose one military path; completing both is not required.\n\nCONFEDERATION\n"+story_steps(Awards.CONFED)+"\n\nREBELLION\n"+story_steps(Awards.REBEL)
  "alien_threat":
   var branch: String=game.achievements.progress().branch
   if branch=="Confederation": return story_steps(Awards.ALIEN_CONFED)
   if branch=="Rebellion": return story_steps(Awards.ALIEN_REBEL)
   return "The Alien investigation follows either faction's military assignments. Choose one path; both are not required.\n\nCONFEDERATION\n"+story_steps(Awards.ALIEN_CONFED)+"\n\nREBELLION\n"+story_steps(Awards.ALIEN_REBEL)
  "special_ops","experimental":
   var branch: String=game.achievements.progress().branch
   if branch=="Confederation": return story_steps(Awards.CARRIER if id=="special_ops" else [170])
   if branch=="Rebellion": return story_steps(Awards.ASTRODYNE if id=="special_ops" else [164])
   return "Choose a faction path to earn special equipment.\n\nREBEL PATH\n"+story_steps(Awards.ASTRODYNE if id=="special_ops" else [164])+"\n\nCONFEDERATION PATH\n"+story_steps(Awards.CARRIER if id=="special_ops" else [170])
  "new_ship":
   var port: int=nearest_port(8)
   return "1. Land at %s and open Visit Shipyard.\n2. Buy any ship other than the starting Shuttle or Escape Pod. The badge is earned when you take command." % place(port)
  "world_killer":
   return "1. Open Cheats (C) and enable Death Star.\n2. Select a surviving planet or station in your current system, then hail it with H and choose the Death Star option.\n3. Let the countdown finish and the target be obliterated; accepting payment or sparing it does not count."
 if id.begins_with("jobs_") or id=="first_job":
  var text: String="Complete %d more contract%s.\n\n" % [remaining,"" if remaining==1 else "s"]
  if not game.pilot.campaign.active.is_empty(): return text+"Finish an accepted assignment:\n"+objective(game.pilot.campaign.active[0])
  if not game.pilot.mission.is_empty(): return text+"Deliver your accepted courier cargo to "+place(int(game.pilot.mission.object))+"."
  return text+"Land at %s, open the Mission Computer, accept a delivery and land at its destination. Finish the return trip too if the contract requires one." % place(nearest_port())
 if id.begins_with("explore_"):
  var next: int=nearest_unvisited()
  add_destination(next)
  return "Visit %d more distinct system%s. Repeat visits do not count.\n\nNext: jump to %s (%d jump%s away). Select it on the map (M), then jump with J. Arriving counts; landing is not required." % [remaining,"" if remaining==1 else "s",game.catalog.system(next).get("name","an unexplored system"),game.autopilot.path(game.pilot.system_id,next).size(),"" if game.autopilot.path(game.pilot.system_id,next).size()==1 else "s"]
 if id.begins_with("credits_"):
  return "Build your balance to %s credits at once. Your previous best is %s; your current balance is %s.\n\n1. Land at %s and accept paid work at the Mission Computer, or use A to choose a profitable trade route.\n2. Keep the earnings until your balance reaches the threshold; lifetime spending does not count toward this badge." % [game.hud.commas(int(b.target)),game.hud.commas(int(b.value)),game.hud.commas(game.pilot.credits),place(nearest_port())]
 if id.begins_with("combat_"):
  return "Earn %d more combat-rating points (current %d; target %d).\n\nDestroy hostile ships. Each credited kill adds at least 1 point, based on the destroyed ship's crew size; larger ships are worth more. Disabling or boarding alone does not count. Check the rating on the flight sidebar as you progress." % [remaining,game.pilot.campaign.rating,int(b.target)]
 if id.begins_with("fleet_"):
  return "Command %d hired or captured escorts at once. Your largest fleet so far is %d; you currently command %d.\n\n1. Land at %s, enter the Spaceport Bar and choose Hire an Escort; use F to manage the fleet.\n2. Alternatively, disable a ship, board it with B and successfully capture it. Bay-launched fighters do not count toward this badge." % [int(b.target),int(b.value),game.pilot.fleet.size(),place(nearest_port())]
 return b.description

func place(port: int) -> String:
 if port>=0: add_destination(game.missions.system_of(port))
 return game.missions.objective_port(port)

func distances() -> Dictionary:
 var found: Dictionary={game.pilot.system_id:0}
 var queue: Array=[game.pilot.system_id]
 while not queue.is_empty():
  var here: int=queue.pop_front()
  for neighbor in game.catalog.system(here).get("links",[]):
   if found.has(int(neighbor)): continue
   found[int(neighbor)]=int(found[here])+1;queue.append(int(neighbor))
 return found

func nearest_port(flags: int=1, mission: int=-1) -> int:
 var dist: Dictionary=distances();var selected: int=-1;var best: int=100000
 for obj in game.catalog.data.objects.values():
  var port: int=int(obj.id);var f: Dictionary=obj.fields
  if not int(f.Flags)&1 or not int(f.Flags)&flags or int(f.Flags)&32 or game.world_killer.destroyed(port): continue
  if mission>=0 and not game.missions.port_matches(int(game.catalog.field("missions",mission,"AvailStel")),port): continue
  var distance: int=int(dist.get(int(f.System),100000))
  if distance<best or (distance==best and port<selected): best=distance;selected=port
 return selected

func nearest_unvisited() -> int:
 var dist: Dictionary=distances();var selected: int=-1;var best: int=100000
 for system in dist:
  if int(system) in game.pilot.visited: continue
  if int(dist[system])<best or (int(dist[system])==best and int(system)<selected): best=int(dist[system]);selected=int(system)
 return selected

func story_steps(ids: Array) -> String:
 for active in game.pilot.campaign.active:
  if int(active.id) in ids: return "Continue accepted mission: "+game.missions.title(active)+"\n\n1. "+objective(active)+"\n2. Complete the assignment to advance this badge, then check here for the next contact."
 for id in ids:
  if int(id) in game.pilot.campaign.completed: continue
  var f: Dictionary=game.catalog.record("missions",int(id)).fields
  if int(f.AvailBitClr)>=0 and int(f.AvailBitClr) in game.pilot.campaign.bits: continue
  return mission_step(int(id),[])
 return "All listed milestones are complete or closed. Check the mission journal for failed assignments or the other faction path; closed story branches cannot be restarted from this badge."

func mission_step(id: int, seen: Array) -> String:
 if id in seen or seen.size()>10: return "An earlier story prerequisite remains unresolved. Check your mission journal and return to your previous contact."
 seen=seen.duplicate();seen.append(id)
 for active in game.pilot.campaign.active:
  if int(active.id)==id: return "Continue accepted mission: "+game.missions.title(active)+"\n\n"+objective(active)
 var f: Dictionary=game.catalog.record("missions",id).fields
 var bit: int=int(f.AvailBitSet)
 if not game.missions.bit_matches(bit) and bit>=0 and bit<1000:
  var predecessors: Array=[]
  for previous in game.catalog.data.missions.values():
   if bit in [int(previous.fields.CompBitSet),int(previous.fields.CompBitSet2)] and int(previous.id) not in seen: predecessors.append(int(previous.id))
  predecessors.sort()
  if not predecessors.is_empty(): return "First complete the prerequisite:\n"+mission_step(int(predecessors[0]),seen)
 var port: int=nearest_port(1,id)
 if port<0: return "No surviving reachable port can offer this assignment. A required contact may have been destroyed."
 var m: Dictionary=game.missions.offer(id,port)
 var reason: String=game.missions.eligibility_reason(id,port)
 var missing_space: int=maxi(0,game.pilot.cargo_used()+int(m.qty)-game.pilot.cargo_capacity())
 if missing_space>0: reason+=(" " if not reason.is_empty() else "")+"Free %d more tonnes of cargo space (this offer needs %d t)." % [missing_space,int(m.qty)]
 if game.pilot.campaign.active.size()>=8: reason+=(" " if not reason.is_empty() else "")+"Finish or abort an active contract to free a mission slot (8/8 occupied)."
 var text: String="Next milestone: "+game.missions.title(m)+"\n\n"
 if not reason.is_empty(): text+="1. "+reason+"\n2. "
 else: text+="1. "
 var channel: String="enter the Spaceport Bar" if int(f.AvailLoc)==1 else "open the Mission Computer" if int(f.AvailLoc)==0 else "meet the local landing contact"
 text+="Land at %s and %s.\n" % [place(port),channel]
 text+="3. " if not reason.is_empty() else "2. "
 text+="Accept the offer and follow its mission-journal objective."
 if int(f.AvailStel)>=0 and int(f.AvailStel)<5000:
  var contact_system: int=game.missions.system_of(port)
  var others: Array[String]=[]
  for object_id in game.catalog.system(contact_system).get("objects",[]):
   if int(object_id)!=port and int(game.catalog.field("objects",int(object_id),"Flags"))&1:
    others.append(str(game.catalog.record("objects",int(object_id)).name))
  if not others.is_empty():
   text+="\n\nExact landing site: %s. This offer does not appear at %s." % [str(game.catalog.record("objects",port).name),", ".join(others)]
  if game.pilot.system_id==contact_system:
   for index in game.planets.size():
    if int(game.planets[index].id)==port and index<4:
     text+="\nIn flight, press %d or F%d to select %s, then double-tap L to auto-land and enter the bar." % [index+1,index+1,str(game.catalog.record("objects",port).name)] if int(f.AvailLoc)==1 else ""
     break

 if int(f.AvailRandom)<100: text+="\n\nThis contact is intermittent. If the offer does not appear, leave and return on a later visit; opening this badge does not trigger an offer."
 return text
