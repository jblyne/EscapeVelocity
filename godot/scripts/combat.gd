extends RefCounted

# Original EV mixes mass and energy damage (unlike Nova). See SpacePort's
# conversion of 30-byte EV weapon records. powers() returns shield, armor.
# Overflow applies the fraction of a hit remaining after shields are exhausted.
static func hit(shield: float, armor: float, energy: float, mass: float) -> Vector2:
	if shield<=0: return Vector2(0,maxf(0,armor-mass))
	if energy<=0: return Vector2(shield,armor)
	var fraction: float=clampf(1.0-shield/energy,0,1)
	return Vector2(maxf(0,shield-energy),maxf(0,armor-mass*fraction))

static func sync(npc: Dictionary) -> void:
	# Keep legacy mission saves and direct simulation damage compatible.
	if npc.has("shield") and npc.has("armor") and is_equal_approx(float(npc.shield)+float(npc.armor),float(npc.health)): return
	var armor_capacity: float=maxf(0,float(npc.max_health)-float(npc.shield_capacity))
	npc.armor=minf(armor_capacity,maxf(0,float(npc.health)))
	npc.shield=maxf(0,float(npc.health)-armor_capacity)

static func apply(npc: Dictionary, energy: float, mass: float) -> void:
	sync(npc)
	var result: Vector2=hit(npc.shield,npc.armor,energy,mass)
	npc.shield=result.x;npc.armor=result.y;npc.health=result.x+result.y
	npc.damage_clock=0.0

# The original global update counter wraps after 1024 (0x15a34-0x15a50).
# A window contains absolute reference ticks [start,end); sharing it keeps all
# ships on the same recovery phase rather than restarting recovery on a hit.
static func recovery_pulses(window: Vector2i, recharge: float) -> int:
	var period: int=maxi(1,int(recharge))
	var count: int=0
	for tick in range(window.x,window.y):
		if (tick%1025)%period==0: count+=1
	return count

static func regenerate(npc: Dictionary, fields: Dictionary, dt: float, window: Vector2i=Vector2i(-1,-1)) -> void:
	sync(npc)
	npc.damage_clock=float(npc.get("damage_clock",0))+dt
	if window.x<0:
		var before: float=float(npc.get("recovery_clock",0))
		npc.recovery_clock=before+maxf(0,dt)*60.0
		window=Vector2i(int(floor(before+.000001)),int(floor(float(npc.recovery_clock)+.000001)))
	if npc.disabled: return
	var result: Vector2=recover(npc.shield,npc.armor,float(npc.shield_capacity),maxf(0,float(npc.max_health)-float(npc.shield_capacity)),recovery_pulses(window,float(fields.ShieldRe)))
	npc.shield=result.x;npc.armor=result.y
	npc.health=npc.shield+npc.armor

static func recover(shield: float,armor: float,max_shield: float,max_armor: float,pulses: int) -> Vector2:
	# 0x36570-0x365ac and 0x187c8-0x18804 truncate AFTER adding 1% to
	# signed integrity. Negative armor damage therefore rounds toward zero.
	var integrity: float=shield-maxf(0,max_armor-armor)
	for pulse in pulses:
		if integrity>=max_shield: break
		integrity=minf(max_shield,float(int(integrity+max_shield*.01)))
	return Vector2(maxf(0,integrity),clampf(max_armor+minf(0,integrity),0,max_armor))

static func powers(fields: Dictionary) -> Vector2:
	var mass: float=float(fields.MassDmg)
	var energy: float=float(fields.EnergyDmg)
	return Vector2(maxf(energy+floorf(mass/4),mass),maxf(mass+floorf(energy/4),energy))

static func shield_rate(capacity: float, recharge: float) -> float:
	return floorf(capacity/100)*60.0/maxf(1,recharge)

static func is_disabled(npc: Dictionary) -> bool:
	sync(npc)
	var capacity: float=maxf(0,float(npc.max_health)-float(npc.shield_capacity))
	# 0x61dd0–0x61e40: signed integrity * 100 < armor capacity * -33.333.
	return npc.shield<=0 and npc.armor>0 and capacity>0 and (capacity-float(npc.armor))*100>capacity*33.333
