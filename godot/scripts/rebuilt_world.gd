extends RefCounted
# Seeded steel megastructures shared by live flight and offline artwork renders.
const Models=preload("res://scripts/models.gd")
const STEEL="res://assets/reconstruction/steel_panels.png"
static var steel_texture: Texture2D
static var dirt_texture: Texture2D

static func soil_texture() -> Texture2D:
 if dirt_texture==null and ResourceLoader.exists("res://assets/reconstruction/reclaimed_soil.png"): dirt_texture=load("res://assets/reconstruction/reclaimed_soil.png")
 return dirt_texture

static func material(id: int) -> StandardMaterial3D:
 var m=Models.material(Color.from_hsv(fmod(id*.6180339,1),.075,.9),.38)
 if steel_texture==null and ResourceLoader.exists(STEEL): steel_texture=load(STEEL)
 m.albedo_texture=steel_texture;m.roughness=.58;m.vertex_color_use_as_albedo=true
 m.cull_mode=BaseMaterial3D.CULL_DISABLED
 return m

static func rank(id: int,index: int) -> float:
 return float(posmod(id*7919+index*104729+index*index*31,10007))/10007.0

static func beam(mesh: SurfaceTool,a: Vector3,b: Vector3,width: float) -> void:
 if a.distance_to(b)<.001: return
 var shape=CylinderMesh.new();shape.top_radius=width;shape.bottom_radius=width;shape.height=a.distance_to(b);shape.radial_segments=5;shape.rings=1
 var direction: Vector3=(b-a).normalized()
 var basis=Basis(Quaternion(Vector3.UP,direction))
 mesh.append_from(shape,0,Transform3D(basis,(a+b)*.5))

static func add_box(mesh: SurfaceTool,at: Vector3,size: Vector3,rotation: float=0) -> void:
 var shape=BoxMesh.new();shape.size=size
 mesh.append_from(shape,0,Transform3D(Basis(Vector3.UP,rotation),at))

static func globe_point(latitude: float,longitude: float,radius: float,flatten: float) -> Vector3:
 return Vector3(sin(latitude)*cos(longitude),cos(latitude)*flatten,sin(latitude)*sin(longitude))*radius

static func plate(mesh: SurfaceTool,points: Array,shade: float) -> void:
 for index in [0,1,2,0,2,3]:
  mesh.set_normal(points[index].normalized());mesh.set_color(Color(shade,shade,shade));mesh.set_uv([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)][index]);mesh.add_vertex(points[index]);mesh.add_index(int(mesh.get_meta("plate_vertex",0)));mesh.set_meta("plate_vertex",int(mesh.get_meta("plate_vertex",0))+1)

static func create(parent: Node3D,at: Vector3,radius: float,id: int,station: bool,progress: float) -> Node3D:
 var root=Node3D.new();root.name="SteelReconstruction%d" % id;root.position=at;parent.add_child(root)
 root.set_meta("rebuild_progress",progress);root.set_meta("rebuild_id",id);root.set_meta("stellar_kind","station" if station else "steel_planet")
 var frame=SurfaceTool.new();frame.begin(Mesh.PRIMITIVE_TRIANGLES)
 var hull=SurfaceTool.new();hull.begin(Mesh.PRIMITIVE_TRIANGLES)
 var frame_fraction: float=clampf(progress*4,0,1)
 var plating: float=clampf((progress-.25)/.75,0,1)
 var soil=SurfaceTool.new();soil.begin(Mesh.PRIMITIVE_TRIANGLES)
 var water=SurfaceTool.new();water.begin(Mesh.PRIMITIVE_TRIANGLES)
 var soil_tiles: int=0;var water_tiles: int=0
 var soil_material=Models.material(Color("e4d2bd"));soil_material.albedo_texture=soil_texture();soil_material.roughness=1;soil_material.vertex_color_use_as_albedo=true
 var water_material=Models.material(Color("2386ae"),.15);water_material.roughness=.18;water_material.vertex_color_use_as_albedo=true
 var lights=Models.material(Color.from_hsv(fmod(id*.6180339,1),.4,1),.1,1.6)
 if station:
  var segments: int=24+id%8;var decks: int=1+id%3
  for deck in decks:
   var y: float=(deck-(decks-1)*.5)*radius*.22
   for i in segments:
    var a: float=i*TAU/segments;var b: float=(i+1)*TAU/segments
    var p=Vector3(cos(a)*radius*.78,y,sin(a)*radius*.78)
    var q=Vector3(cos(b)*radius*.78,y,sin(b)*radius*.78)
    if rank(id,i+deck*segments)<=frame_fraction:
     beam(frame,p,q,radius*.012);beam(frame,p,Vector3(0,y,0),radius*.009)
     if deck>0: beam(frame,p,p-Vector3(0,radius*.22,0),radius*.01)
    if rank(id,i+900+deck*segments)<plating:
     add_box(hull,(p+q)*.5,Vector3(radius*.17,radius*.1,radius*.14),-a)
  for i in 4+id%5:
   var a: float=i*TAU/(4+id%5)+id*.1
   var p=Vector3(cos(a)*radius*.72,0,sin(a)*radius*.72)
   if rank(id,i+240)<frame_fraction: beam(frame,Vector3.ZERO,p,radius*.025)
   if rank(id,i+310)<plating:
    add_box(hull,p,Vector3(radius*.28,radius*.16,radius*.22),-a)
    Models.box(root,p+Vector3(0,radius*.09,0),Vector3(radius*.17,radius*.012,radius*.1),lights)
  beam(frame,Vector3(0,-radius*.4,0),Vector3(0,radius*.4,0),radius*.025)
  if plating>.15: add_box(hull,Vector3.ZERO,Vector3(radius*.35,radius*(.2+plating*.4),radius*.35))
 else:
  var latitudes: int=12+id%5;var sections: int=24+id%9
  var flatten: float=.9+float(id%6)*.02
  for lat in range(1,latitudes):
   for lon in sections:
    var a: float=float(lat)*PI/latitudes;var b: float=lon*TAU/sections;var next: float=(lon+1)*TAU/sections
    var p=globe_point(a,b,radius,flatten)
    if rank(id,lat*sections+lon)<frame_fraction:
     beam(frame,p,globe_point(a,next,radius,flatten),radius*.006)
     beam(frame,p,globe_point(float(lat+1)*PI/latitudes,b,radius,flatten),radius*.006)
  for lat in latitudes:
   for lon in sections:
    var index: int=lat*sections+lon
    if rank(id,index+3000)>=plating: continue
    var a: float=(lat+.015)*PI/latitudes;var b: float=(lat+.985)*PI/latitudes
    var c: float=(lon+.015)*TAU/sections;var d: float=(lon+.985)*TAU/sections
    var points: Array=[globe_point(a,c,radius*1.006,flatten),globe_point(a,d,radius*1.006,flatten),globe_point(b,d,radius*1.006,flatten),globe_point(b,c,radius*1.006,flatten)]
    # Smoothly clustered engineered soil islands and water reservoirs in later work.
    var field: float=(sin(c*2+id*.3)+sin(a*3+id*.5)+cos((c+a)*3-id))/6+.5
    var land_fraction: float=clampf((progress-.5)*.85,0,.425)
    var water_fraction: float=clampf((progress-.65)*.5,0,.175)
    if progress>.65 and field<water_fraction:
     plate(water,points,.85+rank(id,index+6000)*.15);water_tiles+=1
    elif progress>.5 and field<land_fraction:
     plate(soil,points,.68+rank(id,index+6100)*.32);soil_tiles+=1
    else: plate(hull,points,.75+rank(id,index+5000)*.25)
  # Enclosed temporary dock remains available before the outer hull is complete.
  var dock=Vector3(0,radius*flatten,radius*.08)
  add_box(hull,dock,Vector3(radius*.28,radius*.055,radius*.22))
  Models.box(root,dock+Vector3(0,radius*.035,0),Vector3(radius*.2,radius*.008,radius*.11),lights)
  if id%3==0:
   for i in 48:
    if rank(id,i+710)<frame_fraction:
     var a: float=i*TAU/48;var b: float=(i+1)*TAU/48
     beam(frame,Vector3(cos(a),.1,sin(a))*radius*1.16,Vector3(cos(b),.1,sin(b))*radius*1.16,radius*.01)
 # Core dock: every stage has a recognizable, lit operating facility.
 add_box(hull,Vector3.ZERO,Vector3.ONE*radius*.08)
 var meshes: Array=[[frame,"StructuralSkeleton",material(id)],[hull,"SteelHull",material(id)]]
 if soil_tiles>0: meshes.append([soil,"ReclaimedSoil",soil_material])
 if water_tiles>0: meshes.append([water,"WaterReservoirs",water_material])
 root.set_meta("soil_tiles",soil_tiles);root.set_meta("water_tiles",water_tiles)
 for spec in meshes:
  var node=MeshInstance3D.new();node.name=spec[1];node.mesh=spec[0].commit();node.material_override=spec[2];root.add_child(node)
 root.rotation.y=float(id%37)*.17
 return root

static func landing_scene(parent: Node3D,id: int,station: bool,phase: int) -> Node3D:
 var root=Node3D.new();parent.add_child(root)
 var steel=material(id);var dark=Models.material(Color("16232f"),.55)
 var lamps=Models.material(Color.from_hsv(fmod(id*.6180339,1),.45,1),0,1.5)
 # A different dock layout and skyline for every catalog identity.
 Models.box(root,Vector3(0,-1,0),Vector3(36,2,46),steel)
 for side in [-1,1]:
  for i in 7:
   var z: float=-19+i*6
   Models.box(root,Vector3(side*16,.2,z),Vector3(.35,.18,3),lamps)
 for i in 9+id%8:
  var x: float=(-1 if i%2 else 1)*(20+rank(id,i)*15)
  var z: float=-28+rank(id,i+60)*48
  var height: float=5+rank(id,i+90)*21
  for column in [-1,1]: Models.box(root,Vector3(x+column*2,height*.5,z),Vector3(.5,height,.5),steel)
  Models.box(root,Vector3(x,height,z),Vector3(6,.5,5),steel)
  if phase>=2 and rank(id,i+80)<float(phase-1)/3:
   Models.box(root,Vector3(x,height*.45,z),Vector3(5,height*.9,5),steel)
   for level in int(height/3): Models.box(root,Vector3(x,height*.15+level*2.5,z+2.55),Vector3(3,.3,.15),lamps)
  if phase<4:
   Models.box(root,Vector3(x+3,height+3,z),Vector3(.4,6,.4),dark)
   Models.box(root,Vector3(x+6,height+6,z),Vector3(11,.4,.4),steel)
 if not station and phase>=3:
  var dirt=Models.material(Color("e4d2bd"));dirt.albedo_texture=soil_texture();dirt.roughness=1
  var water=Models.material(Color("278cae"),.12);water.roughness=.12
  for bed in (3 if phase==3 else 7):
   var side: int=-1 if bed%2 else 1
   var at=Vector3(side*(10+rank(id,bed+910)*5),.12,-14+bed*5)
   Models.box(root,at,Vector3(4,.45,3.8),steel)
   Models.box(root,at+Vector3(0,.25,0),Vector3(3.6,.12,3.4),dirt if bed%3 else water)
   if phase==4 and bed%3!=0:
    var green=Models.material(Color("687d3c"))
    for crop in 4: Models.box(root,at+Vector3(-1.1+crop*.7,.39,0),Vector3(.18,.12,2.8),green)
 # The actual stage-specific sphere/station dominates the horizon beyond the apron.
 var body=create(root,Vector3(0,24,-130),62,id,station,float(phase)/4)
 body.rotation.z=.18 if station else -.12
 return root
