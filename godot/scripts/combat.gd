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

static func regenerate(npc: Dictionary, fields: Dictionary, dt: float) -> void:
	sync(npc)
	npc.damage_clock=float(npc.get("damage_clock",0))+dt
	if npc.disabled: return
	var result: Vector2=recover(npc.shield,npc.armor,float(npc.shield_capacity),maxf(0,float(npc.max_health)-float(npc.shield_capacity)),float(fields.ShieldRe),dt)
	npc.shield=result.x;npc.armor=result.y
	npc.health=npc.shield+npc.armor

static func recover(shield: float,armor: float,max_shield: float,max_armor: float,recharge: float,dt: float) -> Vector2:
	# The original's signed integrity pool recovers through armor before shields.
	# 0x36550–0x365e4: add truncated 1% shield capacity each recharge interval.
	var amount: float=shield_rate(max_shield,recharge)*dt
	var repaired: float=minf(maxf(0,max_armor-armor),amount)
	return Vector2(minf(max_shield,shield+amount-repaired),minf(max_armor,armor+repaired))

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
