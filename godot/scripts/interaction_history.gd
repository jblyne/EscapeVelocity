extends RefCounted
const ACTIONS=["hail","assistance_requested","refueled","bribe_offered","bribe_paid","boarded","plundered","captured","tribute_demanded","tribute_released","threatened","appeal_denied","spared","bribe_received","bribe_demanded","fired_upon"]
static func fresh() -> Dictionary: return {"next":1,"contacts":{}}
static func integer(value: Variant,low: int,high: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=low and value<=high
static func valid(value: Variant) -> bool:
 if not value is Dictionary or not integer(value.get("next"),1,1000000000) or not value.get("contacts") is Dictionary or value.contacts.size()>2048: return false
 for key in value.contacts:
  if not key is String or key.length()>80: return false
  var entry=value.contacts[key]
  if not entry is Dictionary or not entry.get("counts") is Dictionary or not entry.get("last") in ACTIONS or not integer(entry.get("day"),0,1000000000): return false
  for action in entry.counts:
   if action not in ACTIONS or not integer(entry.counts[action],1,1000000): return false
 return true
static func normalized(value: Dictionary) -> Dictionary:
 var result=fresh();result.next=int(value.next)
 for key in value.contacts:
  var entry: Dictionary=value.contacts[key]
  var counts: Dictionary={}
  for action in entry.counts: counts[action]=int(entry.counts[action])
  result.contacts[key]={"counts":counts,"last":entry.last,"day":int(entry.day)}
 return result
static func pilot_key(pilot,npc: Dictionary) -> String:
 if npc.has("person_id"): return "person:%d" % int(npc.person_id)
 if npc.has("fleet_uid"): return "fleet:%s" % str(npc.fleet_uid)
 if not npc.has("history_key"):
  npc.history_key="pilot:%d" % int(pilot.interaction_history.next)
  pilot.interaction_history.next+=1
 return npc.history_key
static func record(pilot,key: String,action: String) -> void:
 if action not in ACTIONS: return
 var contacts: Dictionary=pilot.interaction_history.contacts
 if not contacts.has(key):
  if contacts.size()>=2048:
   var candidates: Array=contacts.keys().filter(func(id):return str(id).begins_with("pilot:"))
   if candidates.is_empty(): candidates=contacts.keys()
   var oldest: String=str(candidates[0])
   for id in candidates:
    if int(contacts[id].day)<int(contacts[oldest].day): oldest=id
   contacts.erase(oldest)
  contacts[key]={"counts":{},"last":action,"day":int(pilot.campaign.day)}
 var entry: Dictionary=contacts[key]
 entry.counts[action]=mini(1000000,int(entry.counts.get(action,0))+1)
 entry.last=action;entry.day=int(pilot.campaign.day)
static func count(pilot,key: String,action: String) -> int:
 return int(pilot.interaction_history.contacts.get(key,{}).get("counts",{}).get(action,0))
static func recollection(pilot,key: String) -> String:
 var c: Dictionary=pilot.interaction_history.contacts.get(key,{}).get("counts",{})
 if c.is_empty(): return ""
 if c.has("captured"): return "You captured our ship %d times. You expect a warm welcome?" % int(c.captured)
 if c.has("plundered"): return "You have stripped our holds %d times. There is little left to take." % int(c.plundered)
 if c.has("boarded"): return "We remember your boarding parties — %d visits. Keep your people off our decks." % int(c.boarded)
 if c.has("tribute_demanded"): return "You have demanded tribute from us %d times. We remember every demand." % int(c.tribute_demanded)
 if c.has("bribe_received"): return "We have paid you to spare us %d times. Please do not put us through that again." % int(c.bribe_received)
 if c.has("spared"): return "You have spared us %d times. We have not forgotten." % int(c.spared)
 if c.has("threatened"): return "You have threatened us %d times. We know what you are capable of." % int(c.threatened)
 if c.has("bribe_paid"): return "You have bought peace with us %d times. Let us keep this civil." % int(c.bribe_paid)
 if c.has("refueled"): return "We have refueled you %d times already. Flying safely, captain?" % int(c.refueled)
 if c.has("assistance_requested"): return "You have asked us for assistance %d times. What do you need now?" % int(c.assistance_requested)
 if c.has("bribe_offered"): return "You have offered us a bribe %d times. We remember your approach." % int(c.bribe_offered)
 if int(c.get("hail",0))>=2: return "Back again, captain? This is contact number %d." % (int(c.hail)+1)
 return "Good to hear from you again, captain."
