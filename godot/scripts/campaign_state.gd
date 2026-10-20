extends RefCounted

static func fresh() -> Dictionary:
	return {"bits":[],"active":[],"completed":[],"day":0,"visit":0,"rating":0}

static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=low and value<=high

static func valid(value: Variant, catalog) -> bool:
	if not value is Dictionary: return false
	for key in ["bits","active","completed"]:
		if not value.get(key) is Array: return false
	for key in ["day","visit","rating"]:
		if not integer(value.get(key),0,1000000000): return false
	if value.bits.size()>256 or value.active.size()>8 or value.completed.size()>catalog.data.missions.size(): return false
	for bit in value.bits:
		if not integer(bit,0,255): return false
	for id in value.completed:
		if not integer(id,128,243) or catalog.record("missions",int(id)).is_empty(): return false
	var seen: Array=[]
	for m in value.active:
		if not m is Dictionary or not integer(m.get("id"),128,243) or m.id in seen: return false
		seen.append(m.id)
		var rec: Dictionary=catalog.record("missions",int(m.id))
		if rec.is_empty(): return false
		for key in ["origin","dest","back"]:
			if not integer(m.get(key),-1,1627): return false
			if m[key]!=-1 and catalog.record("objects",int(m[key])).is_empty(): return false
		if m.origin<0: return false
		for key in ["picked","delivered","travel_done","met","prepaid"]:
			if not m.get(key) is bool: return false
		if not integer(m.get("qty"),0,10000) or not integer(m.get("deadline"),-1,1000000000): return false
		if not integer(m.get("ship_system"),-1,1127): return false
		if m.ship_system>=0 and catalog.system(int(m.ship_system)).is_empty(): return false
		for key in ["actors","aux"]:
			if not m.get(key) is Array or m[key].size()>31: return false
			for a in m[key]:
				if not a is Dictionary or not integer(a.get("ship"),128,255) or catalog.record("ships",int(a.ship)).is_empty(): return false
				if not (a.get("health") is int or a.get("health") is float) or not is_finite(a.health) or a.health < -1 or a.health>1000000: return false
				for layer in ["shield","armor"]:
					if a.has(layer) and (not (a[layer] is float or a[layer] is int) or not is_finite(a[layer]) or a[layer]<0 or a[layer]>1000000): return false
				if a.has("person_id") and (not integer(a.person_id,128,639) or catalog.record("persons",int(a.person_id)).is_empty()): return false
				for flag in ["disabled","boarded","observed","dead"]:
					if not a.get(flag) is bool: return false
	return true

static func normalized(value: Dictionary) -> Dictionary:
	var result: Dictionary=value.duplicate(true)
	for key in ["bits","completed"]:
		result[key]=[]
		for id in value[key]:
			if int(id) not in result[key]: result[key].append(int(id))
	for key in ["day","visit","rating"]: result[key]=int(result[key])
	return result
