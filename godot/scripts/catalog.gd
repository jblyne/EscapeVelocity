class_name EVCatalog
extends RefCounted

var data: Dictionary

func _init() -> void:
	var content = JSON.parse_string(FileAccess.get_file_as_string("res://data/original_catalog.json"))
	assert(content is Dictionary, "Run tools/build_catalog.py before opening this project.")
	data = content
	preload("res://scripts/maverick.gd").install(self)
	# Rebel counterpart to the original consumable Confederation papers.
	var rebel_id: Dictionary=data.outfits["180"].duplicate(true)
	rebel_id.id=903;rebel_id.name="Rebel Fake ID Papers";rebel_id.fields.ModVal=129
	data.outfits["903"]=rebel_id
	data.descriptions[str(3000+903-128)]="Forged Rebel identification clears a negative Rebellion record to neutral. Consumed immediately on purchase; later offenses still count."
	# Requested forklift buff; retain the recovered source catalog unchanged.
	data.weapons["191"].fields.MassDmg*=3
	data.weapons["191"].fields.EnergyDmg*=3
	# Sidewinders deal half the forklift's current mass and energy damage.
	data.weapons["901"].fields.MassDmg=data.weapons["191"].fields.MassDmg*.5
	data.weapons["901"].fields.EnergyDmg=data.weapons["191"].fields.EnergyDmg*.5
	# JSON numbers arrive as floats; Array membership in Godot is type-sensitive.
	# Normalize identifiers at the boundary so navigation/save references agree.
	for s in data.systems.values():
		for key in ["links", "objects"]:
			var ids: Array = []
			for id in s[key]:
				ids.append(int(id))
			s[key] = ids

func record(group: String, id: int) -> Dictionary:
	return data[group].get(str(id), {})

func system(id: int) -> Dictionary:
	return record("systems", id)

func field(group: String, id: int, key: String) -> Variant:
	return record(group, id).fields[key]

static func technology_price(cost: int, item_tech: int, port_tech: int) -> int:
	# EV 1.0.5 PPC routine 0x4a914. Special technology is not discounted.
	if item_tech<=5 and port_tech<=5 and item_tech<port_tech and cost>=100:
		cost=int(cost*((100-3*(port_tech-item_tech))*.01))
	var step: int=1000 if cost>100000 else (100 if cost>10000 else (10 if cost>100 else 1))
	return int(cost/step)*step

func equipment_price(group: String,id: int,port_id: int) -> int:
	var port: Dictionary=record("objects",port_id)
	var tech: int=int(port.fields.TechLevel) if not port.is_empty() else int(field(group,id,"TechLevel"))
	return technology_price(int(field(group,id,"Cost")),int(field(group,id,"TechLevel")),tech)

func stellar_type(type_id: int) -> Dictionary:
	return data.stellar_types.get(str(type_id), {"id":type_id,"kind":"planet","world_class":"D","label":"Unknown stellar object","sprite":{"width":80,"height":75}})

func government(id: int) -> String:
	var gov = record("governments", int(system(id).fields.Govt))
	return gov.get("name", "Independent space")

func commodity_band(object_id: int,index: int) -> int:
	if index<0 or index>=6: return 0
	var flags: int=int(field("objects",object_id,"Flags"))
	if not flags&2: return 0
	return (flags>>(28-index*4))&7

func prices(object_id: int,spread: float=1.25) -> Array:
	# EV 1.0.5 PPC: 0x3eba4–0x3ec7c. Low truncates base/spread;
	# medium uses base, high truncates base*spread. Default spread is 1.25.
	var result: Array=[]
	for good in data.commodities:
		var band=commodity_band(object_id,int(good.id))
		var base: int=int(good.base_price)
		result.append(maxi(5,int(base/spread)) if band==1 else base if band==2 else maxi(5,int(base*spread)) if band==4 else -1)
	return result
